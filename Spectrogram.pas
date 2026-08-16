unit Spectrogram;

interface

uses
  Vcl.Graphics,
  System.SysUtils, System.Math,
  FFT, WavReader;

type
  TSpectrogramData = class
  private
    FWavFile:    TWavFile;    // not owned
    FFFTSize:    Integer;
    FWindow:     TWindowType;
    FNumBins:    Integer;
    FSampleRate: Cardinal;
    FBgSpectrum: TArray<Double>;
    FHasBg:      Boolean;
    procedure ViridisRGB(T: Double; out R, G, B: Byte);
  public
    { Call when file / FFT size / window changes.  Fast — only computes
      background spectrum from a non-overlapping coarse pass. }
    procedure Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType);

    { Render the visible zoom window at display resolution.  Each pixel column
      gets its own FFT so there is no block artefact when zoomed in. }
    procedure Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer;
                     ZoomStart, ZoomEnd: Double;
                     BgSubtract: Boolean; GainDB, Gamma: Double;
                     MinDB: Double = -100.0; MaxDB: Double = 0.0);

    property NumBins:    Integer  read FNumBins;
    property SampleRate: Cardinal read FSampleRate;
  end;

implementation

type
  TBGRPixel  = packed record B, G, R: Byte; end;
  TBGRRowArr = array[0..MaxInt div SizeOf(TBGRPixel) - 1] of TBGRPixel;
  PBGRRow    = ^TBGRRowArr;

procedure TSpectrogramData.ViridisRGB(T: Double; out R, G, B: Byte);
const
  VR: array[0..7] of Integer = ( 68,  72,  59,  44,  33,  94, 144, 253);
  VG: array[0..7] of Integer = (  1,  40,  81, 113, 144, 201, 213, 231);
  VB: array[0..7] of Integer = ( 84, 120, 139, 142, 141, 100,  68,  37);
var
  Seg:  Integer;
  Frac: Double;
begin
  T    := Min(1.0, Max(0.0, T));
  Frac := T * 7.0;
  Seg  := Trunc(Frac);
  if Seg >= 7 then Seg := 6;
  Frac := Frac - Seg;
  R := Byte(Round(VR[Seg] + (VR[Seg+1] - VR[Seg]) * Frac));
  G := Byte(Round(VG[Seg] + (VG[Seg+1] - VG[Seg]) * Frac));
  B := Byte(Round(VB[Seg] + (VB[Seg+1] - VB[Seg]) * Frac));
end;

procedure TSpectrogramData.Prepare(AWavFile: TWavFile; AFFTSize: Integer;
  AWindow: TWindowType);
var
  Samples:      TArray<Single>;
  TotalSamples: Integer;
  Mags:         TArray<Double>;
  BgSum:        TArray<Double>;
  FrameCount, B, Offset: Integer;
begin
  FWavFile    := AWavFile;
  FFFTSize    := AFFTSize;
  FWindow     := AWindow;
  FNumBins    := AFFTSize shr 1;
  FSampleRate := AWavFile.Info.SampleRate;
  FHasBg      := False;
  SetLength(FBgSpectrum, 0);

  Samples      := AWavFile.Samples;
  TotalSamples := Length(Samples);
  if TotalSamples < AFFTSize then Exit;

  SetLength(BgSum, FNumBins);
  FrameCount := 0;
  Offset := 0;
  while Offset + AFFTSize <= TotalSamples do
  begin
    ComputeWindowedFFT(Samples, Offset, AFFTSize, AWindow, Mags);
    for B := 0 to FNumBins - 1 do
      BgSum[B] := BgSum[B] + Mags[B];
    Inc(FrameCount);
    Inc(Offset, AFFTSize);  // non-overlapping for speed
  end;

  if FrameCount > 0 then
  begin
    SetLength(FBgSpectrum, FNumBins);
    for B := 0 to FNumBins - 1 do
      FBgSpectrum[B] := BgSum[B] / FrameCount;
    FHasBg := True;
  end;
end;

procedure TSpectrogramData.Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer;
  ZoomStart, ZoomEnd: Double; BgSubtract: Boolean; GainDB, Gamma: Double;
  MinDB: Double; MaxDB: Double);
var
  Samples:      TArray<Single>;
  TotalSamples: Integer;
  Rows:         TArray<PBGRRow>;
  Mags:         TArray<Double>;
  X, Y, Bin:   Integer;
  Frac, ZFrac:  Double;
  CenterSample: Integer;
  Mag, DB:      Double;
  TLin, T:      Double;
  VR, VG, VB:  Byte;
  UseBg:        Boolean;
begin
  if (FWavFile = nil) or (FNumBins = 0) or (DestWidth <= 0) or (DestHeight <= 0) then Exit;

  Samples      := FWavFile.Samples;
  TotalSamples := Length(Samples);
  UseBg        := BgSubtract and FHasBg;

  DestBmp.PixelFormat := pf24bit;
  DestBmp.Width       := DestWidth;
  DestBmp.Height      := DestHeight;

  SetLength(Rows, DestHeight);
  for Y := 0 to DestHeight - 1 do
    Rows[Y] := PBGRRow(DestBmp.ScanLine[Y]);

  for X := 0 to DestWidth - 1 do
  begin
    Frac         := (X + 0.5) / DestWidth;
    ZFrac        := ZoomStart + Frac * (ZoomEnd - ZoomStart);
    CenterSample := Round(ZFrac * TotalSamples);

    // ComputeWindowedFFT uses Offset as start of window; we center it on
    // CenterSample.  FFT.pas handles out-of-range indices with zero-padding.
    ComputeWindowedFFT(Samples, CenterSample - (FFFTSize shr 1),
                       FFFTSize, FWindow, Mags);

    for Y := 0 to DestHeight - 1 do
    begin
      Bin := Round((1.0 - (Y + 0.5) / DestHeight) * (FNumBins - 1));
      if Bin < 0 then Bin := 0;
      if Bin >= FNumBins then Bin := FNumBins - 1;

      Mag := Mags[Bin];
      if UseBg then
        Mag := Max(0.0, Mag - FBgSpectrum[Bin]);

      if Mag > 1.0e-12 then
        DB := 20.0 * Log10(Mag) + GainDB
      else
        DB := MinDB;

      TLin := (DB - MinDB) / (MaxDB - MinDB);
      if TLin < 0.0 then TLin := 0.0;
      if TLin > 1.0 then TLin := 1.0;

      if (Gamma > 0.0) and (TLin > 0.0) then
        T := Power(TLin, Gamma)
      else
        T := TLin;

      ViridisRGB(T, VR, VG, VB);
      Rows[Y]^[X].R := VR;
      Rows[Y]^[X].G := VG;
      Rows[Y]^[X].B := VB;
    end;
  end;
end;

end.
