unit WaveformPainter;



interface



uses Winapi.Windows, Vcl.Graphics, System.Math;

// Paints the waveform into InnerR on canvas C.
// PxW/PxH = full client dimensions (for outer background fill).
// BgColor/WaveColor come from the active colour scheme's endpoints.
procedure PaintWaveform(C: TCanvas; PxW, PxH: Integer; const InnerR: TRect;
  const Samples: TArray<Single>; ZoomStart, ZoomEnd, CursorPos: Double;
  BgColor, WaveColor: TColor);

// Semi-transparent white selection band from X1 to X2 inside R.
procedure DrawSelectionOverlay(C: TCanvas; const R: TRect; X1, X2: Integer);



implementation



var
  GOverlayBmp: TBitmap;



procedure PaintWaveform(C: TCanvas; PxW, PxH: Integer; const InnerR: TRect;
  const Samples: TArray<Single>; ZoomStart, ZoomEnd, CursorPos: Double;
  BgColor, WaveColor: TColor);
const
  GRID_COLOR = $00444444;
  AXIS_COLOR = clWhite;
  OUTER_COLOR = $00202020;
var
  TotalSamples: Integer;
  R: TRect;
  W, H, MidY: Integer;
  X, S0, S1, I: Integer;
  Frac0, Frac1: Double;
  MinVal, MaxVal, V: Single;
  YHi, YLo: Integer;
  VisFrac: Double;
  CurX: Integer;
  TextH, TextW: Integer;
  Lbl: string;
  LblY: Integer;
begin
  C.Brush.Color := OUTER_COLOR;
  C.FillRect(Rect(0, 0, PxW, PxH));

  R := InnerR;
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  MidY := R.Top + H div 2;
  if (W <= 0) or (H <= 0) then
    Exit();

  C.Brush.Color := BgColor;
  C.FillRect(R);
  C.Brush.Style := bsClear;

  C.Font.Size := 8;
  C.Font.Color := AXIS_COLOR;
  C.Pen.Width := 1;
  TextH := C.TextHeight('0');

  for I := 0 to 2 do begin
    case I of
      0: begin
          Lbl := '100%';
          LblY := R.Top;
        end;
      1: begin
          Lbl := '0%';
          LblY := MidY;
        end;
    else
      Lbl := '-100%';
      LblY := R.Bottom - 1;
    end;
    C.Pen.Color := GRID_COLOR;
    C.MoveTo(R.Left, LblY);
    C.LineTo(R.Right, LblY);
    C.Pen.Color := AXIS_COLOR;
    C.MoveTo(R.Left - 4, LblY);
    C.LineTo(R.Left, LblY);
    TextW := C.TextWidth(Lbl);
    C.TextOut(R.Left - TextW - 6, LblY - TextH div 2, Lbl);
  end;

  TotalSamples := Length(Samples);
  if TotalSamples = 0 then
    Exit();
  if ZoomEnd <= ZoomStart then
    Exit();

  C.Pen.Color := WaveColor;
  for X := 0 to W - 1 do begin
    Frac0 := ZoomStart + X / W * (ZoomEnd - ZoomStart);
    Frac1 := ZoomStart + (X + 1) / W * (ZoomEnd - ZoomStart);
    S0 := Max(0, Min(TotalSamples - 1, Round(Frac0 * TotalSamples)));
    S1 := Max(S0 + 1, Min(TotalSamples, Round(Frac1 * TotalSamples)));

    MinVal := 1.0;
    MaxVal := -1.0;
    for I := S0 to S1 - 1 do begin
      V := Samples[I];
      if V < MinVal then
        MinVal := V;
      if V > MaxVal then
        MaxVal := V;
    end;

    YHi := MidY - Round(MaxVal * (H div 2));
    YLo := MidY - Round(MinVal * (H div 2));
    if YHi = YLo then
      Inc(YLo);

    C.MoveTo(R.Left + X, YHi);
    C.LineTo(R.Left + X, YLo);
  end;

  if (CursorPos >= 0.0) and (ZoomEnd > ZoomStart) then begin
    VisFrac := (CursorPos - ZoomStart) / (ZoomEnd - ZoomStart);
    if (VisFrac >= 0.0) and (VisFrac <= 1.0) then begin
      CurX := R.Left + Round(VisFrac * W);
      C.Pen.Color := clWhite;
      C.Pen.Width := 2;
      C.MoveTo(CurX, R.Top);
      C.LineTo(CurX, R.Bottom);
      C.Pen.Width := 1;
    end;
  end;
end;



procedure DrawSelectionOverlay(C: TCanvas; const R: TRect; X1, X2: Integer);
var
  BF: TBlendFunction;
begin
  if (X2 <= X1) or (R.Bottom <= R.Top) then
    Exit();
  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := 60;
  BF.AlphaFormat := 0;
  Winapi.Windows.AlphaBlend(C.Handle, X1, R.Top, X2 - X1, R.Bottom - R.Top,
    GOverlayBmp.Canvas.Handle, 0, 0, 1, 1, BF);
end;



initialization
  GOverlayBmp := TBitmap.Create();
  GOverlayBmp.PixelFormat := pf24bit;
  GOverlayBmp.Width := 1;
  GOverlayBmp.Height := 1;
  GOverlayBmp.Canvas.Brush.Color := clWhite;
  GOverlayBmp.Canvas.FillRect(Rect(0, 0, 1, 1));

finalization
  GOverlayBmp.Free();

end.
