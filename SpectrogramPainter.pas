unit SpectrogramPainter;



interface



uses Vcl.Graphics, System.Types;

// Draws frequency (Y) and time (X) axis labels and grid lines inside R.
// MaxPlotHz: the caller passes FMaxPlotHz (always valid when a file is loaded).
// DurationSec: FWavFile.Info.DurationSec.
// AxisColor/GridColor are style-dependent, resolved by the caller.
procedure DrawSpectAxes(C: TCanvas; const R: TRect;
  DurationSec, MaxPlotHz, ZoomStart, ZoomEnd: Double; AxisColor, GridColor: TColor);

// Draws the playback-cursor line inside R.
// CursorPos < 0 means unset (no cursor drawn).
procedure DrawSpectCursor(C: TCanvas; const R: TRect;
  CursorPos, ZoomStart, ZoomEnd: Double; CursorColor: TColor);



implementation



uses System.SysUtils, System.Math;



procedure DrawSpectAxes(C: TCanvas; const R: TRect;
  DurationSec, MaxPlotHz, ZoomStart, ZoomEnd: Double; AxisColor, GridColor: TColor);
var
  StartTime, EndTime, ZoomDur: Double;
  FreqStep, TimeStep: Double;
  Freq, T: Double;
  FirstTick: Double;
  I, X, Y, TextH, TextW: Integer;
  NumTicks: Integer;
  Lbl: string;
begin
  C.Font.Size := 8;
  C.Font.Color := AxisColor;
  C.Brush.Style := bsClear;

  if MaxPlotHz >= 40000 then
    FreqStep := 10000
  else if MaxPlotHz >= 10000 then
    FreqStep := 5000
  else
    FreqStep := 1000;

  NumTicks := Floor(MaxPlotHz / FreqStep);
  TextH := C.TextHeight('0');

  for I := 0 to NumTicks do begin
    Freq := I * FreqStep;
    Y := R.Bottom - 1 - Round(Freq / MaxPlotHz * (R.Bottom - R.Top - 1));

    C.Pen.Color := AxisColor;
    C.Pen.Width := 1;
    C.MoveTo(R.Left - 4, Y);
    C.LineTo(R.Left, Y);

    C.Pen.Color := GridColor;
    C.MoveTo(R.Left, Y);
    C.LineTo(R.Right, Y);

    if Freq >= 1000 then
      Lbl := Format('%gk', [Freq / 1000])
    else
      Lbl := Format('%g', [Freq]);
    TextW := C.TextWidth(Lbl);
    C.Font.Color := AxisColor;
    C.TextOut(R.Left - TextW - 6, Y - TextH div 2, Lbl);
  end;

  StartTime := ZoomStart * DurationSec;
  EndTime := ZoomEnd * DurationSec;
  ZoomDur := EndTime - StartTime;
  if ZoomDur < 1.0E-9 then
    Exit();

  if ZoomDur >= 7200.0 then
    TimeStep := 1200.0
  else if ZoomDur >= 3600.0 then
    TimeStep := 600.0
  else if ZoomDur >= 1800.0 then
    TimeStep := 300.0
  else if ZoomDur >= 600.0 then
    TimeStep := 120.0
  else if ZoomDur >= 240.0 then
    TimeStep := 60.0
  else if ZoomDur >= 120.0 then
    TimeStep := 30.0
  else if ZoomDur >= 60.0 then
    TimeStep := 15.0
  else if ZoomDur >= 30.0 then
    TimeStep := 5.0
  else if ZoomDur >= 8.0 then
    TimeStep := 2.0
  else if ZoomDur >= 4.0 then
    TimeStep := 1.0
  else if ZoomDur >= 2.0 then
    TimeStep := 0.5
  else if ZoomDur >= 0.8 then
    TimeStep := 0.2
  else if ZoomDur >= 0.3 then
    TimeStep := 0.1
  else if ZoomDur >= 0.08 then
    TimeStep := 0.02
  else if ZoomDur >= 0.03 then
    TimeStep := 0.01
  else
    TimeStep := 0.002;

  FirstTick := Ceil(StartTime / TimeStep - 1.0E-9) * TimeStep;

  T := FirstTick;
  while T <= EndTime + TimeStep * 1.0E-6 do begin
    X := R.Left + Round((T - StartTime) / ZoomDur * (R.Right - R.Left));
    if (X >= R.Left) and (X <= R.Right) then begin
      C.Pen.Color := AxisColor;
      C.MoveTo(X, R.Bottom);
      C.LineTo(X, R.Bottom + 4);

      C.Pen.Color := GridColor;
      C.MoveTo(X, R.Top);
      C.LineTo(X, R.Bottom);

      Lbl := Format('%.3f s', [T]);
      TextW := C.TextWidth(Lbl);
      C.Font.Color := AxisColor;
      C.TextOut(X - TextW div 2, R.Bottom + 5, Lbl);
    end;
    T := T + TimeStep;
  end;
end;



procedure DrawSpectCursor(C: TCanvas; const R: TRect;
  CursorPos, ZoomStart, ZoomEnd: Double; CursorColor: TColor);
var
  VisFrac: Double;
  X: Integer;
begin
  if (CursorPos < 0.0) or (ZoomEnd <= ZoomStart) then
    Exit();
  VisFrac := (CursorPos - ZoomStart) / (ZoomEnd - ZoomStart);
  if (VisFrac < 0.0) or (VisFrac > 1.0) then
    Exit();
  X := R.Left + Round(VisFrac * (R.Right - R.Left));
  C.Pen.Color := CursorColor;
  C.MoveTo(X, R.Top);
  C.LineTo(X, R.Bottom);
end;



end.
