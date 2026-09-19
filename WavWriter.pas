unit WavWriter;

{ Writes a zoom-window slice of float samples to a 16-bit PCM WAV file at an
  arbitrary sample rate -- unlike MP3, WAV has no restriction to a fixed set
  of standard rates, so the time-expanded rate can be written directly with
  no resampling. }

interface

uses
  System.SysUtils, System.Classes, System.Math;

procedure SaveWav(const Samples: TArray<Single>; ZoomStart, ZoomEnd: Double;
  const FileName: string; DesiredRate: Cardinal; Gain: Double; out ActualRate: Cardinal);

implementation

type
  TWavFileHeader = packed record
    RiffTag: array [0 .. 3] of AnsiChar;
    RiffSize: Cardinal;
    WaveTag: array [0 .. 3] of AnsiChar;
    FmtTag: array [0 .. 3] of AnsiChar;
    FmtSize: Cardinal;
    AudioFormat: Word;
    Channels: Word;
    SampleRate: Cardinal;
    ByteRate: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    DataTag: array [0 .. 3] of AnsiChar;
    DataSize: Cardinal;
  end;

procedure SaveWav(const Samples: TArray<Single>; ZoomStart, ZoomEnd: Double;
  const FileName: string; DesiredRate: Cardinal; Gain: Double; out ActualRate: Cardinal);
var
  TotalN, S0, S1, N, I, V: Integer;
  PeakAbs, EffectiveGain: Double;
  Pcm: TArray<SmallInt>;
  F: TFileStream;
  Header: TWavFileHeader;
begin
  ActualRate := DesiredRate;

  TotalN := Length(Samples);
  S0 := Max(0, Min(TotalN - 1, Round(ZoomStart * TotalN)));
  S1 := Max(S0 + 1, Min(TotalN, Round(ZoomEnd * TotalN)));
  N := S1 - S0;
  if N <= 0 then
    raise Exception.Create('Selection contains no samples.');

  { Same peak-based gain cap as WaveOutPlayer.Load/SaveMp3: a high gain
    setting should never collapse the exported audio into (near-)full-scale
    clipping -- see the comment there for why that comes out as near
    silence, not just distortion. }
  PeakAbs := 0.0;
  for I := 0 to N - 1 do
    PeakAbs := Max(PeakAbs, Abs(Samples[S0 + I]));
  EffectiveGain := Gain;
  if (PeakAbs > 0.0) and (Gain * PeakAbs > 1.0) then
    EffectiveGain := 1.0 / PeakAbs;

  SetLength(Pcm, N);
  for I := 0 to N - 1 do begin
    V := Round(Samples[S0 + I] * EffectiveGain * 32767.0);
    if V > 32767 then
      V := 32767;
    if V < -32768 then
      V := -32768;
    Pcm[I] := SmallInt(V);
  end;

  FillChar(Header, SizeOf(Header), 0);
  Header.RiffTag := 'RIFF';
  Header.WaveTag := 'WAVE';
  Header.FmtTag := 'fmt ';
  Header.FmtSize := 16;
  Header.AudioFormat := 1; // PCM
  Header.Channels := 1;
  Header.SampleRate := DesiredRate;
  Header.BitsPerSample := 16;
  Header.BlockAlign := Header.Channels * (Header.BitsPerSample div 8);
  Header.ByteRate := Header.SampleRate * Header.BlockAlign;
  Header.DataTag := 'data';
  Header.DataSize := Cardinal(N) * Header.BlockAlign;
  Header.RiffSize := SizeOf(Header) - 8 + Header.DataSize;

  F := TFileStream.Create(FileName, fmCreate);
  try
    F.WriteBuffer(Header, SizeOf(Header));
    if N > 0 then
      F.WriteBuffer(Pcm[0], Header.DataSize);
  finally
    F.Free();
  end;
end;

end.
