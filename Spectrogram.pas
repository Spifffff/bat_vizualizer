unit Spectrogram;

interface

uses
  Vcl.Graphics,
  System.SysUtils, System.Math,
  FFT, WavReader;

type
  TSpectrogramData = class
  private
    FBitmap:     TBitmap;
    FNumFrames:  Integer;
    FNumBins:    Integer;
    FSampleRate: Cardinal;
    FFFTSize:    Integer;
    FHopSize:    Integer;
    FMinDB:      Double;
    FMaxDB:      Double;
    FRawMags:    TArray<TArray<Double>>;  // [frame][bin] raw FFT magnitudes
    FProcMags:   TArray<TArray<Double>>;  // after optional background subtraction

    procedure ViridisRGB(T: Double; out R, G, B: Byte);
  public
    constructor Create;
    destructor  Destroy; override;

    { Compute all FFT frames and store raw magnitudes.  Slow — re-run only
      when file / FFT size / window function changes. }
    procedure Compute(WavFile: TWavFile;
                      FFTSize: Integer;
                      Window:  TWindowType;
                      HopFraction: Double = 0.5);

    { Apply optional per-bin background subtraction, then re-render the
      bitmap with the given gain and power-law gamma.  Fast — call this
      whenever gain, BGsub, or gamma changes without re-FFT. }
    procedure ProcessAndRender(BgSubtract: Boolean;
                               GainDB:     Double;
                               Gamma:      Double;
                               MinDB:      Double = -100.0;
                               MaxDB:      Double =    0.0);

    property Bitmap:     TBitmap  read FBitmap;
    property NumFrames:  Integer  read FNumFrames;
    property NumBins:    Integer  read FNumBins;
    property SampleRate: Cardinal read FSampleRate;
    property FFTSize:    Integer  read FFFTSize;
    property HopSize:    Integer  read FHopSize;
    property MinDB:      Double   read FMinDB;
    property MaxDB:      Double   read FMaxDB;
  end;

implementation

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

constructor TSpectrogramData.Create;
begin
  inherited;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf24bit;
end;

destructor TSpectrogramData.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

procedure TSpectrogramData.Compute(WavFile: TWavFile;
                                    FFTSize: Integer;
                                    Window:  TWindowType;
                                    HopFraction: Double);
var
  Samples:   TArray<Single>;
  HopSize:   Integer;
  NumFrames: Integer;
  I:         Integer;
begin
  Samples := WavFile.Samples;
  if Length(Samples) = 0 then Exit;

  HopSize   := Max(1, Round(FFTSize * HopFraction));
  NumFrames := (Length(Samples) - FFTSize) div HopSize + 1;
  if NumFrames < 1 then NumFrames := 1;

  FNumFrames  := NumFrames;
  FNumBins    := FFTSize shr 1;
  FSampleRate := WavFile.Info.SampleRate;
  FFFTSize    := FFTSize;
  FHopSize    := HopSize;

  SetLength(FRawMags, NumFrames);
  for I := 0 to NumFrames - 1 do
    ComputeWindowedFFT(Samples, I * HopSize, FFTSize, Window, FRawMags[I]);
end;

procedure TSpectrogramData.ProcessAndRender(BgSubtract: Boolean;
                                             GainDB: Double;
                                             Gamma:  Double;
                                             MinDB:  Double;
                                             MaxDB:  Double);
type
  TBGRPixel = packed record B, G, R: Byte; end;
  PBGRPixel  = ^TBGRPixel;
var
  I, J, Row:  Integer;
  Mag, DB:    Double;
  TLin, T:    Double;
  P:          PBGRPixel;
  PR, PG, PB: Byte;
  BgMean:     TArray<Double>;
  N:          Integer;
begin
  if FNumFrames = 0 then Exit;

  FMinDB := MinDB;
  FMaxDB := MaxDB;
  N      := FNumFrames;

  { Copy raw magnitudes into processing buffer. }
  SetLength(FProcMags, N);
  for I := 0 to N - 1 do
  begin
    SetLength(FProcMags[I], FNumBins);
    Move(FRawMags[I][0], FProcMags[I][0], FNumBins * SizeOf(Double));
  end;

  { Per-bin mean background subtraction. }
  if BgSubtract then
  begin
    SetLength(BgMean, FNumBins);
    for J := 0 to FNumBins - 1 do
    begin
      BgMean[J] := 0.0;
      for I := 0 to N - 1 do
        BgMean[J] := BgMean[J] + FProcMags[I][J];
      BgMean[J] := BgMean[J] / N;
    end;
    for I := 0 to N - 1 do
      for J := 0 to FNumBins - 1 do
      begin
        FProcMags[I][J] := FProcMags[I][J] - BgMean[J];
        if FProcMags[I][J] < 0.0 then FProcMags[I][J] := 0.0;
      end;
  end;

  { Render bitmap.  Column = time frame; row 0 = highest frequency bin. }
  FBitmap.Width  := N;
  FBitmap.Height := FNumBins;

  for Row := 0 to FNumBins - 1 do
  begin
    J := FNumBins - 1 - Row;
    P := PBGRPixel(FBitmap.ScanLine[Row]);

    for I := 0 to N - 1 do
    begin
      Mag := FProcMags[I][J];

      if Mag > 1.0e-12 then
        DB := 20.0 * Log10(Mag) + GainDB
      else
        DB := MinDB;

      TLin := (DB - MinDB) / (MaxDB - MinDB);
      if TLin < 0.0 then TLin := 0.0;
      if TLin > 1.0 then TLin := 1.0;

      { Power-law curve: Gamma > 1 keeps low values dark, pulls out peaks. }
      if (Gamma > 0.0) and (TLin > 0.0) then
        T := Power(TLin, Gamma)
      else
        T := TLin;

      ViridisRGB(T, PR, PG, PB);
      P^.R := PR;
      P^.G := PG;
      P^.B := PB;
      Inc(P);
    end;
  end;
end;

end.
