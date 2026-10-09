{ BatViz
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



unit Mp3Writer;

{ Encodes a zoom-window slice of float samples to MP3 using LAME.
  Requires lame_enc.dll (32-bit) placed next to BatViz.exe in the release folder.
  Download from https://lame.buanzo.org/#lamewindl

  Sample rate strategy: snap UP to the next standard MP3 rate at or above the
  desired rate (capped at 48 kHz), then linearly resample the PCM to fill that
  wider rate.  This keeps the playback speed exact while leaving a silent band
  between the signal's Nyquist and the MP3 container's Nyquist. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math;

procedure SaveMp3(const Samples: TArray<Single>; ZoomStart, ZoomEnd: Double;
  const FileName: string; DesiredRate: Cardinal; Gain: Double; out ActualRate: Cardinal);

implementation

{ ---- LAME dynamic-load declarations ---------------------------------------- }

type
  TLameGFP = Pointer;

  TFnLameInit         = function: TLameGFP; cdecl;
  TFnLameSetInt       = function(gfp: TLameGFP; v: Integer): Integer; cdecl;
  TFnLameInitParams   = function(gfp: TLameGFP): Integer; cdecl;
  TFnLameEncodeBuffer = function(gfp: TLameGFP; pcm_l, pcm_r: PSmallInt;
                          nsamples: Integer; mp3buf: PByte; mp3buf_size: Integer): Integer; cdecl;
  TFnLameEncodeFlush  = function(gfp: TLameGFP; mp3buf: PByte; size: Integer): Integer; cdecl;
  TFnLameClose        = function(gfp: TLameGFP): Integer; cdecl;

{ ---- Helpers --------------------------------------------------------------- }

{ Returns the smallest standard MP3 sample rate >= Rate, capped at 48000.
  This preserves exact playback speed: the PCM is resampled to fill the gap,
  leaving a silent band from Signal-Nyquist to MP3-Nyquist. }
function SnapUpToMp3Rate(Rate: Cardinal): Cardinal;
const
  Rates: array [0 .. 8] of Cardinal = (8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000);
var
  I: Integer;
begin
  for I := 0 to High(Rates) do
    if Rates[I] >= Rate then begin
      Result := Rates[I];
      Exit();
    end;
  Result := 48000;
end;

procedure LoadProc(Lib: HMODULE; const Name: string; out Fn);
begin
  Pointer(Fn) := GetProcAddress(Lib, PChar(Name));
  if Pointer(Fn) = nil then
    raise Exception.CreateFmt('lame_enc.dll: missing export "%s"', [Name]);
end;

{ ---- Public procedure ------------------------------------------------------- }

procedure SaveMp3(const Samples: TArray<Single>; ZoomStart, ZoomEnd: Double;
  const FileName: string; DesiredRate: Cardinal; Gain: Double; out ActualRate: Cardinal);
const
  LAME_QUALITY      = 5;      // 2 = high quality, 5 = good, 7 = ok
  LAME_KBPS         = 128;    // kbit/s
  EXTRA_BUF_BYTES   = 7200;   // LAME: output buffer >= nsamples * 1.25 + 7200
  CHUNK_OUT_SAMPLES = 65536;  // resample+encode this many output-rate samples at a time
var
  HLib: HMODULE;
  LameInit: TFnLameInit;
  LameSetNumChannels, LameSetInRate, LameSetBrate, LameSetQuality: TFnLameSetInt;
  LameInitParams: TFnLameInitParams;
  LameEncodeBuffer: TFnLameEncodeBuffer;
  LameEncodeFlush: TFnLameEncodeFlush;
  LameClose: TFnLameClose;
  GFP: TLameGFP;
  OutRate: Cardinal;
  TotalN, S0, S1, N, I, N_out: Integer;
  PeakAbs, EffectiveGain: Double;
  ChunkPcm: TArray<SmallInt>;
  Mp3Buf: TArray<Byte>;
  BufSize, ChunkStart, ChunkLen, OutIdx, SrcIdx0, Encoded: Integer;
  SrcPos, SrcFrac: Double;
  F: TFileStream;

  { What Pcm[Idx] would have been under the old whole-buffer approach: the
    gain-applied, clipped 16-bit value of sample Idx within the selection
    (0 outside it). Computed on demand so no full-selection Int16 copy of
    the selection ever has to exist at once -- see SaveWav for why that
    matters for a large, especially heavily time-expanded, selection. }
  function RawPcm(Idx: Integer): SmallInt;
  var
    V: Integer;
  begin
    if (Idx < 0) or (Idx >= N) then begin
      Result := 0;
      Exit();
    end;
    V := Round(Samples[S0 + Idx] * EffectiveGain * 32767.0);
    if V > 32767 then V := 32767;
    if V < -32768 then V := -32768;
    Result := SmallInt(V);
  end;

begin
  HLib := LoadLibrary('lame_enc.dll');
  if HLib = 0 then
    raise Exception.CreateFmt(
      'Could not load lame_enc.dll (Windows error %d).'#13#10 +
      'Ensure the 32-bit build is placed next to BatViz.exe.'#13#10 +
      'Error 193 = wrong bitness (need 32-bit). Error 126 = missing dependency.',
      [GetLastError()]);
  try
    LoadProc(HLib, 'lame_init',              LameInit);
    LoadProc(HLib, 'lame_set_num_channels',  LameSetNumChannels);
    LoadProc(HLib, 'lame_set_in_samplerate', LameSetInRate);
    LoadProc(HLib, 'lame_set_brate',         LameSetBrate);
    LoadProc(HLib, 'lame_set_quality',       LameSetQuality);
    LoadProc(HLib, 'lame_init_params',       LameInitParams);
    LoadProc(HLib, 'lame_encode_buffer',     LameEncodeBuffer);
    LoadProc(HLib, 'lame_encode_flush',      LameEncodeFlush);
    LoadProc(HLib, 'lame_close',             LameClose);

    OutRate := SnapUpToMp3Rate(DesiredRate);
    ActualRate := OutRate;

    TotalN := Length(Samples);
    S0 := Max(0, Min(TotalN - 1, Round(ZoomStart * TotalN)));
    S1 := Max(S0 + 1, Min(TotalN, Round(ZoomEnd * TotalN)));
    N := S1 - S0;
    if N <= 0 then
      raise Exception.Create('Selection contains no samples.');

    { A gain high enough to clip almost the whole selection collapses it
      toward a near-constant (DC) signal -- inaudible except for a click at
      the edges of the clipped region, even though every sample is at "full
      volume". Cap the gain actually applied so the loudest sample in range
      reaches, but doesn't exceed, full scale, instead of clipping past it. }
    PeakAbs := 0.0;
    for I := 0 to N - 1 do
      PeakAbs := Max(PeakAbs, Abs(Samples[S0 + I]));
    EffectiveGain := Gain;
    if (PeakAbs > 0.0) and (Gain * PeakAbs > 1.0) then
      EffectiveGain := 1.0 / PeakAbs;

    { Linearly resample from DesiredRate to OutRate.
      The ratio OutRate/DesiredRate >= 1, so this is always an upsample (or 1:1).
      Frequencies above DesiredRate/2 (signal Nyquist) will be near-zero,
      giving a silent band between the signal content and OutRate/2. }
    if OutRate = DesiredRate then
      N_out := N
    else
      N_out := Round(Int64(N) * OutRate / DesiredRate);

    GFP := LameInit();
    if GFP = nil then
      raise Exception.Create('lame_init() returned nil.');
    try
      LameSetNumChannels(GFP, 1);
      LameSetInRate(GFP, Integer(OutRate));
      LameSetBrate(GFP, LAME_KBPS);
      LameSetQuality(GFP, LAME_QUALITY);
      if LameInitParams(GFP) < 0 then
        raise Exception.Create('lame_init_params() failed — unsupported sample rate.');

      BufSize := Round(CHUNK_OUT_SAMPLES * 1.25) + EXTRA_BUF_BYTES;
      SetLength(Mp3Buf, BufSize);
      SetLength(ChunkPcm, Min(N_out, CHUNK_OUT_SAMPLES));

      F := TFileStream.Create(FileName, fmCreate);
      try
        { Resample (if needed) and encode bounded-size chunks at a time
          instead of building the whole resampled buffer -- and the whole
          LAME output buffer -- in memory up front. For a large selection,
          especially at a heavy time-expansion factor, that used to hold
          three whole-selection-sized buffers at once on top of the
          already-resident whole-file Samples array. }
        ChunkStart := 0;
        while ChunkStart < N_out do begin
          ChunkLen := Min(CHUNK_OUT_SAMPLES, N_out - ChunkStart);
          for OutIdx := 0 to ChunkLen - 1 do begin
            if OutRate = DesiredRate then
              ChunkPcm[OutIdx] := RawPcm(ChunkStart + OutIdx)
            else begin
              SrcPos := (ChunkStart + OutIdx) * (DesiredRate / OutRate);
              SrcIdx0 := Trunc(SrcPos);
              SrcFrac := SrcPos - SrcIdx0;
              if SrcIdx0 + 1 < N then
                ChunkPcm[OutIdx] := SmallInt(Round(RawPcm(SrcIdx0) * (1.0 - SrcFrac) + RawPcm(SrcIdx0 + 1) * SrcFrac))
              else if SrcIdx0 < N then
                ChunkPcm[OutIdx] := RawPcm(SrcIdx0)
              else
                ChunkPcm[OutIdx] := 0;
            end;
          end;

          Encoded := LameEncodeBuffer(GFP, @ChunkPcm[0], @ChunkPcm[0], ChunkLen, @Mp3Buf[0], BufSize);
          if Encoded < 0 then
            raise Exception.CreateFmt('lame_encode_buffer() failed (%d).', [Encoded]);
          if Encoded > 0 then
            F.WriteBuffer(Mp3Buf[0], Encoded);
          Inc(ChunkStart, ChunkLen);
        end;

        Encoded := LameEncodeFlush(GFP, @Mp3Buf[0], BufSize);
        if Encoded > 0 then
          F.WriteBuffer(Mp3Buf[0], Encoded);
      finally
        F.Free();
      end;
    finally
      LameClose(GFP);
    end;
  finally
    FreeLibrary(HLib);
  end;
end;

end.
