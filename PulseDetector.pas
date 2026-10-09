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



unit PulseDetector;



interface



uses
  System.SysUtils, System.Math, System.Generics.Collections, FFT;

type
  TPulseDetection = record
    StartSec: Double;
    PeakSec: Double;
    EndSec: Double;
    DurationMs: Double;
    AttackMs: Double;
    DecayMs: Double;
    InterPulseIntervalMs: Double; // onset-to-onset gap from the previous pulse; -1 for the first pulse
    PeakAmplitude: Double;
    RmsAmplitude: Double;
    StartFreqHz: Double;
    PeakFreqHz: Double;
    EndFreqHz: Double;
  end;



  TPulseDetectionParams = record
    EnvelopeSmoothMs: Double;     // amplitude envelope smoothing window
    NoiseFloorPercentile: Double; // 0..100, percentile of the envelope used as the noise floor
    ThresholdSigma: Double;       // multiples of envelope std-dev above the noise floor to count as signal
    MinThreshold: Double;         // absolute floor on the threshold, so near-silent files don't trigger on hiss
    MaxGapMs: Double;             // gaps shorter than this within a pulse are bridged
    MinRegionMs: Double;          // regions shorter than this are discarded as noise spikes
    PrePaddingMs: Double;         // extra time added before each region to capture the attack
    PostPaddingMs: Double;        // extra time added after each region to capture the decay tail
    SpectralFFTSize: Integer;     // must be a power of two; window used to estimate pulse frequency
    SpectralWindow: TWindowType;
  end;



function DefaultPulseDetectionParams: TPulseDetectionParams;
function DetectPulses(const Samples: TArray<Single>; SampleRate: Cardinal; const Params: TPulseDetectionParams): TArray<TPulseDetection>;



implementation



function DefaultPulseDetectionParams: TPulseDetectionParams;
begin
  Result.EnvelopeSmoothMs := 1.0;
  Result.NoiseFloorPercentile := 20.0;
  Result.ThresholdSigma := 3.0;
  Result.MinThreshold := 0.01;
  Result.MaxGapMs := 2.0;
  Result.MinRegionMs := 0.5;
  Result.PrePaddingMs := 1.0;
  Result.PostPaddingMs := 2.0;
  Result.SpectralFFTSize := 512;
  Result.SpectralWindow := wtHann;
end;



// Rectified, box-smoothed amplitude envelope, same length as Samples. Uses a running-sum so the
// cost is O(n) regardless of the smoothing window size.
procedure BuildEnvelope(const Samples: TArray<Single>; SampleRate: Cardinal; SmoothMs: Double; out Envelope: TArray<Double>);
var
  N, HalfWin, I, Lo, Hi: Integer;
  RunningSum: Double;
  Prefix: TArray<Double>;
begin
  N := Length(Samples);
  SetLength(Envelope, N);
  if N = 0 then
    Exit();

  HalfWin := Max(0, Round(SmoothMs / 1000.0 * SampleRate / 2.0));

  SetLength(Prefix, N + 1);
  RunningSum := 0.0;
  Prefix[0] := 0.0;
  for I := 0 to N - 1 do begin
    RunningSum := RunningSum + Abs(Samples[I]);
    Prefix[I + 1] := RunningSum;
  end;

  for I := 0 to N - 1 do begin
    Lo := Max(0, I - HalfWin);
    Hi := Min(N - 1, I + HalfWin);
    Envelope[I] := (Prefix[Hi + 1] - Prefix[Lo]) / (Hi - Lo + 1);
  end;
end;



// Percentile (0..100) of Values. Sorts a strided sample rather than the full array when Values is
// very large, since an exact percentile isn't needed for an adaptive noise-floor estimate.
function Percentile(const Values: TArray<Double>; P: Double): Double;
const
  MAX_SAMPLE_COUNT = 200000;
var
  Sample: TArray<Double>;
  Stride, I, Idx: Integer;
begin
  if Length(Values) = 0 then
    Exit(0.0);

  Stride := Max(1, Length(Values) div MAX_SAMPLE_COUNT);
  SetLength(Sample, (Length(Values) + Stride - 1) div Stride);
  I := 0;
  while I * Stride < Length(Values) do begin
    Sample[I] := Values[I * Stride];
    Inc(I);
  end;
  SetLength(Sample, I);

  TArray.Sort<Double>(Sample);
  Idx := EnsureRange(Round(P / 100.0 * (Length(Sample) - 1)), 0, Length(Sample) - 1);
  Result := Sample[Idx];
end;



procedure MeanAndStdDev(const Values: TArray<Double>; out AMean, AStdDev: Double);
var
  I: Integer;
  SumSq: Double;
begin
  AMean := 0.0;
  AStdDev := 0.0;
  if Length(Values) = 0 then
    Exit();

  for I := 0 to High(Values) do
    AMean := AMean + Values[I];
  AMean := AMean / Length(Values);

  SumSq := 0.0;
  for I := 0 to High(Values) do
    SumSq := SumSq + Sqr(Values[I] - AMean);
  AStdDev := Sqrt(SumSq / Length(Values));
end;



// Dominant frequency (Hz) of an FFT window of size FFTSize centered on CenterIdx. The DC bin is
// skipped so a slowly-drifting mean doesn't win against the actual call tone.
function PeakFrequencyNear(const Samples: TArray<Single>; SampleRate: Cardinal; CenterIdx, FFTSize: Integer; Window: TWindowType): Double;
var
  Magnitudes: TArray<Double>;
  I, BestBin: Integer;
begin
  ComputeWindowedFFT(Samples, CenterIdx - FFTSize div 2, FFTSize, Window, Magnitudes);

  BestBin := 1;
  for I := 2 to High(Magnitudes) do
    if Magnitudes[I] > Magnitudes[BestBin] then
      BestBin := I;

  Result := BestBin * SampleRate / FFTSize;
end;



function DetectPulses(const Samples: TArray<Single>; SampleRate: Cardinal; const Params: TPulseDetectionParams): TArray<TPulseDetection>;
var
  Envelope: TArray<Double>;
  NoiseFloor, EnvMean, EnvStdDev, Threshold: Double;
  MaxGapSamples, MinRegionSamples, PrePadSamples, PostPadSamples: Integer;
  RawRegions, MergedRegions: TList<TPair<Integer, Integer>>;
  I, N, RegionStart: Integer;
  InRegion: Boolean;
  Cur, Prev: TPair<Integer, Integer>;
  Pulses: TList<TPulseDetection>;
  Pulse: TPulseDetection;
  StartIdx, EndIdx, PeakIdx, LastEndIdx: Integer;
  PeakAmp, SumSq: Double;
  PrevStartSec: Double;
begin
  N := Length(Samples);
  SetLength(Result, 0);
  if (N = 0) or (SampleRate = 0) then
    Exit();

  BuildEnvelope(Samples, SampleRate, Params.EnvelopeSmoothMs, Envelope);
  NoiseFloor := Percentile(Envelope, Params.NoiseFloorPercentile);
  MeanAndStdDev(Envelope, EnvMean, EnvStdDev);
  Threshold := Max(NoiseFloor + Params.ThresholdSigma * EnvStdDev, Params.MinThreshold);

  MaxGapSamples := Round(Params.MaxGapMs / 1000.0 * SampleRate);
  MinRegionSamples := Round(Params.MinRegionMs / 1000.0 * SampleRate);
  PrePadSamples := Round(Params.PrePaddingMs / 1000.0 * SampleRate);
  PostPadSamples := Round(Params.PostPaddingMs / 1000.0 * SampleRate);

  // Pass 1: raw runs where the envelope is above threshold.
  RawRegions := TList<TPair<Integer, Integer>>.Create();
  try
    InRegion := False;
    RegionStart := 0;
    for I := 0 to N - 1 do begin
      if (Envelope[I] >= Threshold) and not InRegion then begin
        InRegion := True;
        RegionStart := I;
      end
      else if (Envelope[I] < Threshold) and InRegion then begin
        InRegion := False;
        RawRegions.Add(TPair<Integer, Integer>.Create(RegionStart, I - 1));
      end;
    end;
    if InRegion then
      RawRegions.Add(TPair<Integer, Integer>.Create(RegionStart, N - 1));

    // Pass 2: bridge gaps shorter than MaxGapSamples, then drop anything still too short.
    MergedRegions := TList<TPair<Integer, Integer>>.Create();
    try
      for I := 0 to RawRegions.Count - 1 do begin
        Cur := RawRegions[I];
        if (MergedRegions.Count > 0) and (Cur.Key - MergedRegions[MergedRegions.Count - 1].Value <= MaxGapSamples) then begin
          Prev := MergedRegions[MergedRegions.Count - 1];
          MergedRegions[MergedRegions.Count - 1] := TPair<Integer, Integer>.Create(Prev.Key, Cur.Value);
        end
        else
          MergedRegions.Add(Cur);
      end;

      // Pass 3: pad each surviving region, clamped to the sample array and re-merged if padding
      // now makes neighbouring regions overlap.
      Pulses := TList<TPulseDetection>.Create();
      try
        PrevStartSec := -1.0;
        LastEndIdx := -1;
        for I := 0 to MergedRegions.Count - 1 do begin
          Cur := MergedRegions[I];
          if Cur.Value - Cur.Key + 1 < MinRegionSamples then
            Continue;

          StartIdx := Max(0, Cur.Key - PrePadSamples);
          EndIdx := Min(N - 1, Cur.Value + PostPadSamples);
          if StartIdx <= LastEndIdx then
            StartIdx := LastEndIdx + 1;
          if StartIdx > EndIdx then
            Continue;
          LastEndIdx := EndIdx;

          PeakIdx := StartIdx;
          PeakAmp := Abs(Samples[StartIdx]);
          SumSq := 0.0;
          for var J := StartIdx to EndIdx do begin
            if Abs(Samples[J]) > PeakAmp then begin
              PeakAmp := Abs(Samples[J]);
              PeakIdx := J;
            end;
            SumSq := SumSq + Sqr(Samples[J]);
          end;

          Pulse.StartSec := StartIdx / SampleRate;
          Pulse.PeakSec := PeakIdx / SampleRate;
          Pulse.EndSec := EndIdx / SampleRate;
          Pulse.DurationMs := (EndIdx - StartIdx) / SampleRate * 1000.0;
          Pulse.AttackMs := (PeakIdx - StartIdx) / SampleRate * 1000.0;
          Pulse.DecayMs := (EndIdx - PeakIdx) / SampleRate * 1000.0;
          if PrevStartSec < 0.0 then
            Pulse.InterPulseIntervalMs := -1.0
          else
            Pulse.InterPulseIntervalMs := (Pulse.StartSec - PrevStartSec) * 1000.0;
          PrevStartSec := Pulse.StartSec;

          Pulse.PeakAmplitude := PeakAmp;
          Pulse.RmsAmplitude := Sqrt(SumSq / (EndIdx - StartIdx + 1));

          Pulse.StartFreqHz := PeakFrequencyNear(Samples, SampleRate, StartIdx, Params.SpectralFFTSize, Params.SpectralWindow);
          Pulse.PeakFreqHz := PeakFrequencyNear(Samples, SampleRate, PeakIdx, Params.SpectralFFTSize, Params.SpectralWindow);
          Pulse.EndFreqHz := PeakFrequencyNear(Samples, SampleRate, EndIdx, Params.SpectralFFTSize, Params.SpectralWindow);

          Pulses.Add(Pulse);
        end;

        Result := Pulses.ToArray();
      finally
        Pulses.Free();
      end;
    finally
      MergedRegions.Free();
    end;
  finally
    RawRegions.Free();
  end;
end;



end.
