{ Bat vizualizer
  Copyright (C) 2026

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>. }



unit Heterodyne;

{ Produces a real-time-playable baseband signal for heterodyne ("direct
  conversion") bat-detector-style playback: mixes a slice of the recording
  against a local oscillator at the tuned frequency, low-pass filters the
  result to isolate the difference (beat) frequency, then decimates to a
  rate just above that filter's passband. Unlike time-expansion, which
  slows everything down to make the whole spectrum audible, this only makes
  a narrow band around the tuned frequency audible, played back in real
  time (no time stretch). }

interface

uses
  System.SysUtils, System.Math;

const
  { Half-width, in Hz, of the low-pass filter applied after mixing -- the
    audible output only contains content within +-this of the tuned
    frequency, matching a typical hardware heterodyne detector's IF
    bandwidth. Not user-adjustable: it is a property of the (simulated)
    filter, not a playback setting. }
  HETERODYNE_HALF_BANDWIDTH_HZ = 4000.0;

{ Mixes Samples[StartSample..EndSample) down against a local oscillator at
  TuneHz. TimeScale is the number of original-timeline samples each output
  sample represents (the decimation factor) -- callers use it to keep
  playback-position tracking in the original timeline correct. OutputRate is
  the sample rate Output should be played back at to run in real time. }
procedure MixHeterodyne(const Samples: TArray<Single>; StartSample, EndSample: Integer; SourceRate: Cardinal;
  TuneHz: Double; out Output: TArray<Single>; out TimeScale: Integer; out OutputRate: Cardinal);

implementation

procedure MixHeterodyne(const Samples: TArray<Single>; StartSample, EndSample: Integer; SourceRate: Cardinal;
  TuneHz: Double; out Output: TArray<Single>; out TimeScale: Integer; out OutputRate: Cardinal);
const
  { Comfortably above 2x the filter's passband, and low enough to keep the
    decimated array small. }
  TARGET_OUTPUT_RATE = 16000;
var
  N, I, OutN, OutIdx: Integer;
  PhaseInc, Alpha, LpStage1, LpStage2: Double;
  Mixed: TArray<Single>;
begin
  N := EndSample - StartSample;
  if N <= 0 then begin
    SetLength(Output, 0);
    TimeScale := 1;
    OutputRate := SourceRate;
    Exit();
  end;

  { Mix down against a local oscillator at the tuned frequency. This shifts
    a narrow band around TuneHz down to (near) 0 Hz -- the low-pass filter
    below then isolates just that band, rejecting everything else. Phase is
    recomputed per sample (not accumulated) so it stays exact regardless of
    how long the selection is. }
  SetLength(Mixed, N);
  PhaseInc := 2.0 * Pi * TuneHz / SourceRate;
  for I := 0 to N - 1 do
    Mixed[I] := Samples[StartSample + I] * Cos(PhaseInc * I);

  { Two cascaded single-pole low-pass filters -- a cheap approximation of a
    steeper anti-alias filter -- at the IF bandwidth, run before decimating
    so content that would otherwise alias back into the audible band is
    attenuated first. }
  Alpha := 1.0 - Exp(-2.0 * Pi * HETERODYNE_HALF_BANDWIDTH_HZ / SourceRate);
  LpStage1 := 0.0;
  LpStage2 := 0.0;
  for I := 0 to N - 1 do begin
    LpStage1 := LpStage1 + Alpha * (Mixed[I] - LpStage1);
    LpStage2 := LpStage2 + Alpha * (LpStage1 - LpStage2);
    Mixed[I] := LpStage2;
  end;

  TimeScale := Max(1, Round(SourceRate / TARGET_OUTPUT_RATE));
  OutputRate := Round(SourceRate / TimeScale);

  OutN := (N + TimeScale - 1) div TimeScale;
  SetLength(Output, OutN);
  OutIdx := 0;
  I := 0;
  while I < N do begin
    Output[OutIdx] := Mixed[I];
    Inc(OutIdx);
    Inc(I, TimeScale);
  end;
end;

end.
