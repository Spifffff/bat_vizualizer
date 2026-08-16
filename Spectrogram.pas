unit Spectrogram;

interface

uses
  Vcl.Graphics,
  System.SysUtils, System.Math,
  FFT, WavReader;

type
  TColorScheme = (csViridis, csInferno, csMagma, csGrayscale);

  TSpectrogramData = class
  private
    FWavFile:    TWavFile;    // not owned
    FFFTSize:    Integer;
    FWindow:     TWindowType;
    FNumBins:    Integer;
    FSampleRate: Cardinal;
    FBgSpectrum: TArray<Double>;
    FHasBg:      Boolean;
    procedure GetColor(T: Double; Scheme: TColorScheme; out R, G, B: Byte);
  public
    { Call when file / FFT size / window changes.  Fast — only computes
      background spectrum from a non-overlapping coarse pass. }
    procedure Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType);

    { Render the visible zoom window at display resolution.  Each pixel column
      gets its own FFT so there is no block artefact when zoomed in. }
    procedure Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer;
                     ZoomStart, ZoomEnd: Double;
                     BgSubtract: Boolean; GainDB, Gamma: Double;
                     MinDB: Double = -100.0; MaxDB: Double = 0.0;
                     ColorScheme: TColorScheme = csViridis);

    property NumBins:    Integer  read FNumBins;
    property SampleRate: Cardinal read FSampleRate;
  end;

implementation

type
  TBGRPixel  = packed record B, G, R: Byte; end;
  TBGRRowArr = array[0..MaxInt div SizeOf(TBGRPixel) - 1] of TBGRPixel;
  PBGRRow    = ^TBGRRowArr;

procedure TSpectrogramData.GetColor(T: Double; Scheme: TColorScheme;
  out R, G, B: Byte);
const
  // 8 anchor points for each colormap (R, G, B), evenly spaced 0..1
  VirR: array[0..7] of Integer = (  0,  72,  59,  44,  33,  94, 144, 253);
  VirG: array[0..7] of Integer = (  0,  40,  81, 113, 144, 201, 213, 231);
  VirB: array[0..7] of Integer = (  0, 120, 139, 142, 141, 100,  68,  37);
  InfR: array[0..7] of Integer = (  0,  40, 101, 159, 212, 245, 254, 252);
  InfG: array[0..7] of Integer = (  0,  11,  21,  42,  72, 125, 188, 255);
  InfB: array[0..7] of Integer = (  4,  84, 110,  99,  66,  21,  43, 164);
  MagR: array[0..7] of Integer = (  0,  28,  79, 129, 181, 229, 251, 252);
  MagG: array[0..7] of Integer = (  0,  16,  18,  37,  54,  80, 135, 253);
  MagB: array[0..7] of Integer = (  4,  68, 123, 129, 122, 100,  97, 191);
var
  Seg:  Integer;
  Frac: Double;
  V:    Integer;
begin
  T    := Min(1.0, Max(0.0, T));
  if Scheme = csGrayscale then
  begin
    V := Round(T * 255);
    R := V; G := V; B := V;
    Exit;
  end;
  Frac := T * 7.0;
  Seg  := Trunc(Frac);
  if Seg >= 7 then Seg := 6;
  Frac := Frac - Seg;
  case Scheme of
    csViridis: begin
      R := Byte(Round(VirR[Seg] + (VirR[Seg+1] - VirR[Seg]) * Frac));
      G := Byte(Round(VirG[Seg] + (VirG[Seg+1] - VirG[Seg]) * Frac));
      B := Byte(Round(VirB[Seg] + (VirB[Seg+1] - VirB[Seg]) * Frac));
    end;
    csInferno: begin
      R := Byte(Round(InfR[Seg] + (InfR[Seg+1] - InfR[Seg]) * Frac));
      G := Byte(Round(InfG[Seg] + (InfG[Seg+1] - InfG[Seg]) * Frac));
      B := Byte(Round(InfB[Seg] + (InfB[Seg+1] - InfB[Seg]) * Frac));
    end;
    csMagma: begin
      R := Byte(Round(MagR[Seg] + (MagR[Seg+1] - MagR[Seg]) * Frac));
      G := Byte(Round(MagG[Seg] + (MagG[Seg+1] - MagG[Seg]) * Frac));
      B := Byte(Round(MagB[Seg] + (MagB[Seg+1] - MagB[Seg]) * Frac));
    end;
  else
    R := 0; G := 0; B := 0;
  end;
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
  MinDB: Double; MaxDB: Double; ColorScheme: TColorScheme);
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

      GetColor(T, ColorScheme, VR, VG, VB);
      Rows[Y]^[X].R := VR;
      Rows[Y]^[X].G := VG;
      Rows[Y]^[X].B := VB;
    end;
  end;
end;

end.
