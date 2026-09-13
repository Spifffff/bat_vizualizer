unit Spectrogram;



interface



uses
  Vcl.Graphics,
  System.SysUtils, System.Math, System.Generics.Collections, System.Generics.Defaults,
  FFT, WavReader;

type
  TColorScheme = (csViridis, csInferno, csMagma, csGrayscale, csGrayscaleInv, csPlasma, csCividis, csMako, csRocket, csSpectral, csTurbo, csHot);



  TSpectrogramData = class
  private
    FWavFile: TWavFile; // not owned
    FFFTSize: Integer;
    FWindow: TWindowType;
    FNumBins: Integer;
    FSampleRate: Cardinal;
    FNoiseFloor: TArray<TArray<Double>>;
    FNoiseFramePos: TArray<Double>;
    FHasBg: Boolean;
    FFilteredSamples: TArray<Single>;
    FAutoFloorDB: Double;
    FAutoCeilingDB: Double;
    FAutoMaxFreqHz: Double;
  public
    procedure GetColor(T: Double; Scheme: TColorScheme; out R, G, B: Byte);
    { Call when file / FFT size / window changes.  Computes a rolling-median
      noise floor used by Render when BgSubtract is True, and suggested
      auto floor/ceiling/max-frequency values (see Auto*** properties).
      AOnTick, when assigned, is called once per analyzed frame so a caller
      can show progress for a slow (large-file) recompute. }
    procedure Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType; const AOnTick: TProc = nil);

    { Render the visible zoom window at display resolution.  Each pixel column
      gets its own FFT so there is no block artefact when zoomed in. }
    procedure Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer; ZoomStart, ZoomEnd: Double; BgSubtract: Boolean; Gamma: Double;
      MinDB: Double = -100.0; MaxDB: Double = 0.0; ColorScheme: TColorScheme = csViridis; MaxFreqHz: Double = 0.0;
      UseHighPass: Boolean = False; UseEnergyGate: Boolean = False);

    property NumBins: Integer read FNumBins;
    property SampleRate: Cardinal read FSampleRate;
    { Suggested display range computed by Prepare from the 5th/99.5th
      percentile of the file's dB distribution. }
    property AutoFloorDB: Double read FAutoFloorDB;
    property AutoCeilingDB: Double read FAutoCeilingDB;
    { Suggested max frequency: the highest bin whose peak level clears the
      noise floor by a margin, with a little headroom, capped at Nyquist. }
    property AutoMaxFreqHz: Double read FAutoMaxFreqHz;
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
  // Turbo (Google)
  TuR: array [0 .. 7] of Integer = (48, 64, 43, 35, 117, 220, 240, 122);
  TuG: array [0 .. 7] of Integer = (18, 84, 155, 197, 220, 205, 110, 4);
  TuB: array [0 .. 7] of Integer = (59, 196, 232, 168, 90, 45, 30, 3);
  // Hot (matplotlib, black-body style)
  HtR: array [0 .. 7] of Integer = (0, 97, 194, 255, 255, 255, 255, 255);
  HtG: array [0 .. 7] of Integer = (0, 0, 0, 37, 133, 230, 255, 255);
  HtB: array [0 .. 7] of Integer = (0, 0, 0, 0, 0, 0, 109, 255);
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
    Exit();
  end;
  if Scheme = csGrayscaleInv then begin
    V := 255 - Round(T * 255);
    R := V;
    G := V;
    B := V;
    Exit();
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
    csTurbo: begin
        R := Byte(Round(TuR[Seg] + (TuR[Seg + 1] - TuR[Seg]) * Frac));
        G := Byte(Round(TuG[Seg] + (TuG[Seg + 1] - TuG[Seg]) * Frac));
        B := Byte(Round(TuB[Seg] + (TuB[Seg + 1] - TuB[Seg]) * Frac));
      end;
    csHot: begin
        R := Byte(Round(HtR[Seg] + (HtR[Seg + 1] - HtR[Seg]) * Frac));
        G := Byte(Round(HtG[Seg] + (HtG[Seg + 1] - HtG[Seg]) * Frac));
        B := Byte(Round(HtB[Seg] + (HtB[Seg + 1] - HtB[Seg]) * Frac));
      end;
  else
    R := 0;
    G := 0;
    B := 0;
  end;
end;



const
  HP_CUTOFF_HZ   = 15000.0;  // high-pass cutoff — adjust to suit recording setup
  GATE_ON_THRESH  = 3.0e-5;  // RMS of mag spectrum to open gate
  GATE_OFF_THRESH = 1.5e-5;  // RMS of mag spectrum to close gate (hysteresis)



procedure BiquadHighPass(const Src: TArray<Single>; SampleRate: Cardinal; CutoffHz: Double; out Dst: TArray<Single>);
var
  W0, Alpha, Cos0, A0, NB0, NB1, NB2, NA1, NA2: Double;
  X1, X2, Y1, Y2, Y: Double;
  I: Integer;
begin
  SetLength(Dst, Length(Src));
  if (Length(Src) = 0) or (SampleRate = 0) then
    Exit();
  W0 := 2.0 * Pi * CutoffHz / SampleRate;
  Cos0 := Cos(W0);
  Alpha := Sin(W0) / (2.0 * 0.7071); // Q = 1/sqrt(2) Butterworth
  A0 := 1.0 + Alpha;
  NB0 := (1.0 + Cos0) / (2.0 * A0);
  NB1 := -(1.0 + Cos0) / A0;
  NB2 := NB0;
  NA1 := -2.0 * Cos0 / A0;
  NA2 := (1.0 - Alpha) / A0;
  X1 := 0; X2 := 0; Y1 := 0; Y2 := 0;
  for I := 0 to Length(Src) - 1 do begin
    Y := NB0 * Src[I] + NB1 * X1 + NB2 * X2 - NA1 * Y1 - NA2 * Y2;
    X2 := X1; X1 := Src[I];
    Y2 := Y1; Y1 := Y;
    Dst[I] := Single(Y);
  end;
end;



procedure TSpectrogramData.Prepare(AWavFile: TWavFile; AFFTSize: Integer; AWindow: TWindowType; const AOnTick: TProc);
const
  MAX_NOISE_FRAMES = 256;
  NOISE_HALF_WIN = 16;
  AUTO_MIN_DB = -160.0;
  AUTO_SIGNAL_SNR_DB = 22.5;
  AUTO_MAXFREQ_HEADROOM = 1.15;
var
  Samples: TArray<Single>;
  TotalSamples, Hop, N, HalfW: Integer;
  Frame, B, J, K, WinStart, WinEnd, WinLen, Offset: Integer;
  Mags: TArray<Double>;
  RawMags: TArray<TArray<Double>>;
  Scratch: array [0 .. 2 * NOISE_HALF_WIN] of Double;
  Tmp: Double;
  AllDB, NoiseDBFlat, PeakMag: TArray<Double>;
  Idx, SignalBin: Integer;
  Mag, NoiseMag, NoiseBaselineDB: Double;
begin
  FWavFile := AWavFile;
  FFFTSize := AFFTSize;
  FWindow := AWindow;
  FNumBins := AFFTSize shr 1;
  FSampleRate := AWavFile.Info.SampleRate;
  FHasBg := False;
  SetLength(FNoiseFloor, 0);
  SetLength(FNoiseFramePos, 0);
  FAutoFloorDB := -100.0;
  FAutoCeilingDB := 0.0;
  FAutoMaxFreqHz := FSampleRate / 2.0;

  Samples := AWavFile.Samples;
  TotalSamples := Length(Samples);
  if TotalSamples < AFFTSize then
    Exit();

  // Evenly-spaced noise frames, at most MAX_NOISE_FRAMES
  Hop := Max(AFFTSize, TotalSamples div MAX_NOISE_FRAMES);
  N := 0;
  Offset := 0;
  while Offset + AFFTSize <= TotalSamples do begin
    Inc(N);
    Inc(Offset, Hop);
  end;
  N := Min(N, MAX_NOISE_FRAMES);
  if N = 0 then
    Exit();

  // Window half-width: aim for ~1 second each side, capped at NOISE_HALF_WIN
  HalfW := Min(NOISE_HALF_WIN, Max(1, Round(FSampleRate / (2.0 * Hop))));
  HalfW := Min(HalfW, N div 2);
  HalfW := Max(HalfW, 1);

  // Compute raw magnitude frames
  SetLength(RawMags, N);
  SetLength(FNoiseFramePos, N);
  Offset := 0;
  for Frame := 0 to N - 1 do begin
    ComputeWindowedFFT(Samples, Offset, AFFTSize, AWindow, Mags);
    SetLength(RawMags[Frame], FNumBins);
    Move(Mags[0], RawMags[Frame][0], FNumBins * SizeOf(Double));
    FNoiseFramePos[Frame] := (Offset + AFFTSize * 0.5) / TotalSamples;
    Inc(Offset, Hop);
    if Assigned(AOnTick) then
      AOnTick();
  end;

  // Per-bin rolling median across the window
  SetLength(FNoiseFloor, N);
  for Frame := 0 to N - 1 do begin
    SetLength(FNoiseFloor[Frame], FNumBins);
    WinStart := Max(0, Frame - HalfW);
    WinEnd := Min(N - 1, Frame + HalfW);
    WinLen := WinEnd - WinStart + 1;
    for B := 0 to FNumBins - 1 do begin
      for J := 0 to WinLen - 1 do
        Scratch[J] := RawMags[WinStart + J][B];
      for J := 1 to WinLen - 1 do begin
        Tmp := Scratch[J];
        K := J - 1;
        while (K >= 0) and (Scratch[K] > Tmp) do begin
          Scratch[K + 1] := Scratch[K];
          Dec(K);
        end;
        Scratch[K + 1] := Tmp;
      end;
      FNoiseFloor[Frame][B] := Scratch[WinLen div 2];
    end;
  end;

  // Auto floor/ceiling: 5th/99.5th percentile of the dB distribution over
  // all sampled frames and bins, and track each bin's peak magnitude.
  SetLength(AllDB, N * FNumBins);
  SetLength(PeakMag, FNumBins);
  for B := 0 to FNumBins - 1 do
    PeakMag[B] := 0.0;
  Idx := 0;
  for Frame := 0 to N - 1 do
    for B := 0 to FNumBins - 1 do begin
      Mag := RawMags[Frame][B];
      if Mag > 1.0E-12 then
        AllDB[Idx] := 20.0 * Log10(Mag)
      else
        AllDB[Idx] := AUTO_MIN_DB;
      Inc(Idx);
      if Mag > PeakMag[B] then
        PeakMag[B] := Mag;
    end;
  TArray.Sort<Double>(AllDB);
  FAutoFloorDB := AllDB[EnsureRange(Ceil(Length(AllDB) * 0.4), 0, High(AllDB))];
  FAutoCeilingDB := AllDB[EnsureRange(Floor(Length(AllDB) * 0.99996), 0, High(AllDB))];

  // Auto max-frequency: highest bin whose peak clears the median noise floor
  // by a margin, with a little headroom, capped at Nyquist.
  SetLength(NoiseDBFlat, N * FNumBins);
  Idx := 0;
  for Frame := 0 to N - 1 do
    for B := 0 to FNumBins - 1 do begin
      NoiseMag := FNoiseFloor[Frame][B];
      if NoiseMag > 1.0E-12 then
        NoiseDBFlat[Idx] := 20.0 * Log10(NoiseMag)
      else
        NoiseDBFlat[Idx] := AUTO_MIN_DB;
      Inc(Idx);
    end;
  TArray.Sort<Double>(NoiseDBFlat);
  NoiseBaselineDB := NoiseDBFlat[Length(NoiseDBFlat) div 2];

  SignalBin := -1;
  for B := FNumBins - 1 downto 0 do
    if (PeakMag[B] > 1.0E-12) and (20.0 * Log10(PeakMag[B]) >= NoiseBaselineDB + AUTO_SIGNAL_SNR_DB) then begin
      SignalBin := B;
      Break;
    end;
  if SignalBin >= 0 then
    FAutoMaxFreqHz := Min(FSampleRate / 2.0,
      (SignalBin / (FNumBins - 1)) * (FSampleRate / 2.0) * AUTO_MAXFREQ_HEADROOM);

  FHasBg := True;
  BiquadHighPass(Samples, FSampleRate, HP_CUTOFF_HZ, FFilteredSamples);
end;



procedure TSpectrogramData.Render(DestBmp: TBitmap; DestWidth, DestHeight: Integer; ZoomStart, ZoomEnd: Double; BgSubtract: Boolean; Gamma: Double;
  MinDB: Double; MaxDB: Double; ColorScheme: TColorScheme; MaxFreqHz: Double;
  UseHighPass: Boolean; UseEnergyGate: Boolean);
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
  NoiseBuf: TArray<Double>;
  NoiseF0, NoiseF1, BIdx: Integer;
  Alpha, Energy, RMS: Double;
  GateOpen: Boolean;
begin
  if (FWavFile = nil) or (FNumBins = 0) or (DestWidth <= 0) or (DestHeight <= 0) then
    Exit();

  if UseHighPass and (Length(FFilteredSamples) = Length(FWavFile.Samples)) then
    Samples := FFilteredSamples
  else
    Samples := FWavFile.Samples;
  TotalSamples := Length(Samples);
  UseBg := BgSubtract and FHasBg;
  NoiseF0 := 0;
  if UseBg then
    SetLength(NoiseBuf, FNumBins);
  GateOpen := False;

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

    if UseEnergyGate then begin
      Energy := 0.0;
      for BIdx := 0 to MaxBin do
        Energy := Energy + Sqr(Mags[BIdx]);
      RMS := Sqrt(Energy / (MaxBin + 1));
      if GateOpen then begin
        if RMS < GATE_OFF_THRESH then
          GateOpen := False;
      end else begin
        if RMS >= GATE_ON_THRESH then
          GateOpen := True;
      end;
      if not GateOpen then begin
        for Y := 0 to DestHeight - 1 do begin
          Rows[Y]^[X].R := 0;
          Rows[Y]^[X].G := 0;
          Rows[Y]^[X].B := 0;
        end;
        Continue;
      end;
    end;

    if UseBg then begin
      while (NoiseF0 < Length(FNoiseFloor) - 2) and (FNoiseFramePos[NoiseF0 + 1] <= ZFrac) do
        Inc(NoiseF0);
      NoiseF1 := Min(NoiseF0 + 1, Length(FNoiseFloor) - 1);
      if (NoiseF0 < NoiseF1) and (FNoiseFramePos[NoiseF1] > FNoiseFramePos[NoiseF0]) then
        Alpha := Max(0.0, Min(1.0, (ZFrac - FNoiseFramePos[NoiseF0]) / (FNoiseFramePos[NoiseF1] - FNoiseFramePos[NoiseF0])))
      else
        Alpha := 0.0;
      for BIdx := 0 to FNumBins - 1 do
        NoiseBuf[BIdx] := FNoiseFloor[NoiseF0][BIdx] * (1.0 - Alpha) + FNoiseFloor[NoiseF1][BIdx] * Alpha;
    end;

    for Y := 0 to DestHeight - 1 do begin
      Bin := Round((1.0 - (Y + 0.5) / DestHeight) * MaxBin);
      if Bin < 0 then
        Bin := 0;
      if Bin >= FNumBins then
        Bin := FNumBins - 1;

      Mag := Mags[Bin];
      if UseBg then
        Mag := Max(0.0, Mag - NoiseBuf[Bin]);

      if Mag > 1.0E-12 then
        DB := 20.0 * Log10(Mag)
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
