unit Spectrogram;



interface



uses
  Vcl.Graphics,
  System.SysUtils, System.Math,
  FFT, WavReader;

type
  TColorScheme = (csViridis, csInferno, csMagma, csGrayscale, csPlasma, csCividis, csMako, csRocket, csSpectral);



  TSpectrogramData = class
  private
    FWavFile: TWavFile; // not owned
    FFFTSize: Integer;
    FWindow: TWindowType;
    FNumBins: Integer;
    FSampleRate: Cardinal;
    FBgSpectrum: TArray<Double>;
    FHasBg: Boolean;
  public
    procedure GetColor(T: Double; Scheme: TColorScheme; out R, G, B: Byte);
    { Call when file / FFT size / window changes.  Fast — only computes
      background spectrum from a non-overlapping coarse pass. }
    procedure Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType);

    { Render the visible zoom window at display resolution.  Each pixel column
      gets its own FFT so there is no block artefact when zoomed in. }
    procedure Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer; ZoomStart, ZoomEnd: Double; BgSubtract: Boolean; GainDB, Gamma: Double;
      MinDB: Double = -100.0; MaxDB: Double = 0.0; ColorScheme: TColorScheme = csViridis; MaxFreqHz: Double = 0.0);

    property NumBins: Integer read FNumBins;
    property SampleRate: Cardinal read FSampleRate;
  end;



implementation



type
  TBGRPixel = packed record
    B, G, R: Byte;
  end;



  TBGRRowArr = array [0 .. MaxInt div SizeOf(TBGRPixel) - 1] of TBGRPixel;
  PBGRRow = ^TBGRRowArr;



procedure TSpectrogramData.GetColor(T: Double; Scheme: TColorScheme; out R, G, B: Byte);
const
  // 8 anchor points evenly spaced 0..1 for each colormap
  VirR: array [0 .. 7] of Integer = (0, 72, 59, 44, 33, 94, 144, 253);
  VirG: array [0 .. 7] of Integer = (0, 40, 81, 113, 144, 201, 213, 231);
  VirB: array [0 .. 7] of Integer = (0, 120, 139, 142, 141, 100, 68, 37);
  InfR: array [0 .. 7] of Integer = (0, 40, 101, 159, 212, 245, 254, 252);
  InfG: array [0 .. 7] of Integer = (0, 11, 21, 42, 72, 125, 188, 255);
  InfB: array [0 .. 7] of Integer = (4, 84, 110, 99, 66, 21, 43, 164);
  MagR: array [0 .. 7] of Integer = (0, 28, 79, 129, 181, 229, 251, 252);
  MagG: array [0 .. 7] of Integer = (0, 16, 18, 37, 54, 80, 135, 253);
  MagB: array [0 .. 7] of Integer = (4, 68, 123, 129, 122, 100, 97, 191);
  // Plasma (matplotlib)
  PlR: array [0 .. 7] of Integer = (13, 83, 139, 184, 218, 243, 254, 240);
  PlG: array [0 .. 7] of Integer = (8, 2, 10, 50, 91, 135, 187, 247);
  PlB: array [0 .. 7] of Integer = (135, 163, 165, 137, 105, 74, 43, 36);
  // Cividis (matplotlib)
  CiR: array [0 .. 7] of Integer = (0, 33, 76, 108, 141, 176, 215, 254);
  CiG: array [0 .. 7] of Integer = (34, 59, 85, 110, 136, 165, 196, 230);
  CiB: array [0 .. 7] of Integer = (78, 110, 108, 114, 120, 113, 92, 54);
  // Mako (seaborn)
  MkR: array [0 .. 7] of Integer = (11, 46, 65, 55, 52, 64, 139, 222);
  MkG: array [0 .. 7] of Integer = (4, 30, 61, 101, 143, 183, 218, 245);
  MkB: array [0 .. 7] of Integer = (5, 59, 123, 158, 167, 173, 178, 229);
  // Rocket (seaborn)
  RkR: array [0 .. 7] of Integer = (3, 53, 112, 173, 225, 243, 246, 250);
  RkG: array [0 .. 7] of Integer = (5, 25, 31, 23, 51, 118, 180, 235);
  RkB: array [0 .. 7] of Integer = (26, 62, 87, 89, 66, 81, 143, 221);
  // Spectral (ColorBrewer, sampled from 11-class table)
  SpR: array [0 .. 7] of Integer = (94, 50, 171, 230, 254, 253, 213, 158);
  SpG: array [0 .. 7] of Integer = (79, 136, 221, 245, 224, 174, 62, 1);
  SpB: array [0 .. 7] of Integer = (162, 189, 164, 152, 139, 97, 79, 66);
var
  Seg: Integer;
  Frac: Double;
  V: Integer;
begin
  T := Min(1.0, Max(0.0, T));
  if Scheme = csGrayscale then begin
    V := Round(T * 255);
    R := V;
    G := V;
    B := V;
    Exit;
  end;
  Frac := T * 7.0;
  Seg := Trunc(Frac);
  if Seg >= 7 then
    Seg := 6;
  Frac := Frac - Seg;
  case Scheme of
    csViridis: begin
        R := Byte(Round(VirR[Seg] + (VirR[Seg + 1] - VirR[Seg]) * Frac));
        G := Byte(Round(VirG[Seg] + (VirG[Seg + 1] - VirG[Seg]) * Frac));
        B := Byte(Round(VirB[Seg] + (VirB[Seg + 1] - VirB[Seg]) * Frac));
      end;
    csInferno: begin
        R := Byte(Round(InfR[Seg] + (InfR[Seg + 1] - InfR[Seg]) * Frac));
        G := Byte(Round(InfG[Seg] + (InfG[Seg + 1] - InfG[Seg]) * Frac));
        B := Byte(Round(InfB[Seg] + (InfB[Seg + 1] - InfB[Seg]) * Frac));
      end;
    csMagma: begin
        R := Byte(Round(MagR[Seg] + (MagR[Seg + 1] - MagR[Seg]) * Frac));
        G := Byte(Round(MagG[Seg] + (MagG[Seg + 1] - MagG[Seg]) * Frac));
        B := Byte(Round(MagB[Seg] + (MagB[Seg + 1] - MagB[Seg]) * Frac));
      end;
    csPlasma: begin
        R := Byte(Round(PlR[Seg] + (PlR[Seg + 1] - PlR[Seg]) * Frac));
        G := Byte(Round(PlG[Seg] + (PlG[Seg + 1] - PlG[Seg]) * Frac));
        B := Byte(Round(PlB[Seg] + (PlB[Seg + 1] - PlB[Seg]) * Frac));
      end;
    csCividis: begin
        R := Byte(Round(CiR[Seg] + (CiR[Seg + 1] - CiR[Seg]) * Frac));
        G := Byte(Round(CiG[Seg] + (CiG[Seg + 1] - CiG[Seg]) * Frac));
        B := Byte(Round(CiB[Seg] + (CiB[Seg + 1] - CiB[Seg]) * Frac));
      end;
    csMako: begin
        R := Byte(Round(MkR[Seg] + (MkR[Seg + 1] - MkR[Seg]) * Frac));
        G := Byte(Round(MkG[Seg] + (MkG[Seg + 1] - MkG[Seg]) * Frac));
        B := Byte(Round(MkB[Seg] + (MkB[Seg + 1] - MkB[Seg]) * Frac));
      end;
    csRocket: begin
        R := Byte(Round(RkR[Seg] + (RkR[Seg + 1] - RkR[Seg]) * Frac));
        G := Byte(Round(RkG[Seg] + (RkG[Seg + 1] - RkG[Seg]) * Frac));
        B := Byte(Round(RkB[Seg] + (RkB[Seg + 1] - RkB[Seg]) * Frac));
      end;
    csSpectral: begin
        R := Byte(Round(SpR[Seg] + (SpR[Seg + 1] - SpR[Seg]) * Frac));
        G := Byte(Round(SpG[Seg] + (SpG[Seg + 1] - SpG[Seg]) * Frac));
        B := Byte(Round(SpB[Seg] + (SpB[Seg + 1] - SpB[Seg]) * Frac));
      end;
  else
    R := 0;
    G := 0;
    B := 0;
  end;
end;



procedure TSpectrogramData.Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType);
var
  Samples: TArray<Single>;
  TotalSamples: Integer;
  Mags: TArray<Double>;
  BgSum: TArray<Double>;
  FrameCount, B, Offset: Integer;
begin
  FWavFile := AWavFile;
  FFFTSize := AFFTSize;
  FWindow := AWindow;
  FNumBins := AFFTSize shr 1;
  FSampleRate := AWavFile.Info.SampleRate;
  FHasBg := False;
  SetLength(FBgSpectrum, 0);

  Samples := AWavFile.Samples;
  TotalSamples := Length(Samples);
  if TotalSamples < AFFTSize then
    Exit;

  SetLength(BgSum, FNumBins);
  FrameCount := 0;
  Offset := 0;
  while Offset + AFFTSize <= TotalSamples do begin
    ComputeWindowedFFT(Samples, Offset, AFFTSize, AWindow, Mags);
    for B := 0 to FNumBins - 1 do
      BgSum[B] := BgSum[B] + Mags[B];
    Inc(FrameCount);
    Inc(Offset, AFFTSize); // non-overlapping for speed
  end;

  if FrameCount > 0 then begin
    SetLength(FBgSpectrum, FNumBins);
    for B := 0 to FNumBins - 1 do
      FBgSpectrum[B] := BgSum[B] / FrameCount;
    FHasBg := True;
  end;
end;



procedure TSpectrogramData.Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer; ZoomStart, ZoomEnd: Double; BgSubtract: Boolean; GainDB, Gamma: Double;
  MinDB: Double; MaxDB: Double; ColorScheme: TColorScheme; MaxFreqHz: Double);
var
  Samples: TArray<Single>;
  TotalSamples: Integer;
  Rows: TArray<PBGRRow>;
  Mags: TArray<Double>;
  X, Y, Bin, MaxBin: Integer;
  Frac, ZFrac: Double;
  CenterSample: Integer;
  Mag, DB: Double;
  TLin, T: Double;
  VR, VG, VB: Byte;
  UseBg: Boolean;
begin
  if (FWavFile = nil) or (FNumBins = 0) or (DestWidth <= 0) or (DestHeight <= 0) then
    Exit;

  Samples := FWavFile.Samples;
  TotalSamples := Length(Samples);
  UseBg := BgSubtract and FHasBg;

  MaxBin := FNumBins - 1;
  if (MaxFreqHz > 0) and (MaxFreqHz < FSampleRate / 2.0) then
    MaxBin := Min(FNumBins - 1, Round(MaxFreqHz / (FSampleRate / 2.0) * (FNumBins - 1)));

  DestBmp.PixelFormat := pf24bit;
  DestBmp.Width := DestWidth;
  DestBmp.Height := DestHeight;

  SetLength(Rows, DestHeight);
  for Y := 0 to DestHeight - 1 do
    Rows[Y] := PBGRRow(DestBmp.ScanLine[Y]);

  for X := 0 to DestWidth - 1 do begin
    Frac := (X + 0.5) / DestWidth;
    ZFrac := ZoomStart + Frac * (ZoomEnd - ZoomStart);
    CenterSample := Round(ZFrac * TotalSamples);

    // ComputeWindowedFFT uses Offset as start of window; we center it on
    // CenterSample.  FFT.pas handles out-of-range indices with zero-padding.
    ComputeWindowedFFT(Samples, CenterSample - (FFFTSize shr 1), FFFTSize, FWindow, Mags);

    for Y := 0 to DestHeight - 1 do begin
      Bin := Round((1.0 - (Y + 0.5) / DestHeight) * MaxBin);
      if Bin < 0 then
        Bin := 0;
      if Bin >= FNumBins then
        Bin := FNumBins - 1;

      Mag := Mags[Bin];
      if UseBg then
        Mag := Max(0.0, Mag - FBgSpectrum[Bin]);

      if Mag > 1.0E-12 then
        DB := 20.0 * Log10(Mag) + GainDB
      else
        DB := MinDB;

      TLin := (DB - MinDB) / (MaxDB - MinDB);
      if TLin < 0.0 then
        TLin := 0.0;
      if TLin > 1.0 then
        TLin := 1.0;

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
