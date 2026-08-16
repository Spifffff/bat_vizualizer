unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  FFT, WavReader, Spectrogram, WaveOutPlayer;

const
  PLAYBACK_RATE     = 0.1;
  LEFT_MARGIN       = 65;
  BOTTOM_MARGIN     = 35;
  TOP_MARGIN        = 8;
  RIGHT_MARGIN      = 10;
  SPECTROGRAM_GAMMA = 2.5;

type
  TFormMain = class(TForm)
    PanelLeft:      TPanel;
    BtnOpen:        TButton;
    BtnPlay:        TButton;
    BtnPause:       TButton;
    BtnStop:        TButton;
    LblWindow:      TLabel;
    CbxWindow:      TComboBox;
    LblFFTSize:     TLabel;
    CbxFFTSize:     TComboBox;
    LblGainCaption: TLabel;
    LblGainVal:     TLabel;
    TrkGain:        TTrackBar;
    ChkBGSub:         TCheckBox;
    LblColorScheme:   TLabel;
    CbxColorScheme:   TComboBox;
    LblFloor:         TLabel;
    TrkFloor:         TTrackBar;
    LblCeiling:       TLabel;
    TrkCeiling:       TTrackBar;
    StatusBar:        TStatusBar;
    ZoomBar:        TScrollBar;
    PanelMain:      TPanel;
    WaveformBox:    TPaintBox;
    Splitter1:      TSplitter;
    PaintBox:       TPaintBox;
    OpenDialog:     TOpenDialog;
    Timer:          TTimer;
    RenderTimer:    TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOpenClick(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
                                Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
                                X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
                              Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxPaint(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure CbxWindowChange(Sender: TObject);
    procedure CbxFFTSizeChange(Sender: TObject);
    procedure TrkGainChange(Sender: TObject);
    procedure ChkBGSubChange(Sender: TObject);
    procedure CbxColorSchemeChange(Sender: TObject);
    procedure TrkFloorChange(Sender: TObject);
    procedure TrkCeilingChange(Sender: TObject);
    procedure RenderTimerTick(Sender: TObject);
    procedure ZoomBarChange(Sender: TObject);
  private
    FWavFile:    TWavFile;
    FSpecgram:   TSpectrogramData;
    FCursorPos:  Double;
    FWavePlayer: TWaveOutPlayer;
    FDisplayBmp: TBitmap;

    FZoomStart:    Double;
    FZoomEnd:      Double;
    FDragging:     Boolean;
    FDragStartX:   Integer;
    FDragZoomStart: Double;
    FDragZoomEnd:   Double;
    FDragZoomFrac:  Double;

    function  SpectRect: TRect;
    function  GetFFTSize: Integer;
    function  GetWindowType: TWindowType;
    procedure RecomputeSpectrogram;
    procedure RenderSpectrogram;
    procedure ScheduleRender;
    procedure DrawAxes(C: TCanvas; const R: TRect);
    procedure DrawCursor(C: TCanvas; const R: TRect);
    procedure ResetPlaybackUI;
    procedure UpdateZoomBar;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

function IdxToColorScheme(Idx: Integer): TColorScheme; inline;
begin
  case Idx of
    1: Result := csInferno;
    2: Result := csMagma;
    3: Result := csGrayscale;
  else Result := csViridis;
  end;
end;

{ ---- helpers --------------------------------------------------------------- }

function TFormMain.SpectRect: TRect;
begin
  Result := Rect(LEFT_MARGIN,
                 TOP_MARGIN,
                 PaintBox.Width  - RIGHT_MARGIN,
                 PaintBox.Height - BOTTOM_MARGIN);
end;

function TFormMain.GetFFTSize: Integer;
begin
  case CbxFFTSize.ItemIndex of
    0: Result := 512;
    1: Result := 1024;
    2: Result := 2048;
    3: Result := 4096;
    4: Result := 8192;
    5: Result := 16384;
  else
    Result := 4096;
  end;
end;

function TFormMain.GetWindowType: TWindowType;
begin
  case CbxWindow.ItemIndex of
    0: Result := wtRectangular;
    1: Result := wtHann;
    2: Result := wtHamming;
    3: Result := wtBlackman;
    4: Result := wtFlatTop;
  else
    Result := wtHann;
  end;
end;

procedure TFormMain.UpdateZoomBar;
var
  SI: TScrollInfo;
  PageSz, Pos: Integer;
begin
  if not ZoomBar.HandleAllocated then Exit;

  PageSz := Max(1, Min(1000, Round((FZoomEnd - FZoomStart) * 1000)));
  Pos    := Round(FZoomStart * 1000);
  if Pos > 1000 - PageSz then Pos := 1000 - PageSz;
  if Pos < 0 then Pos := 0;

  ZoomBar.OnChange := nil;
  try
    SI.cbSize    := SizeOf(TScrollInfo);
    SI.fMask     := SIF_ALL;
    SI.nMin      := 0;
    SI.nMax      := 1000;
    SI.nPage     := UINT(PageSz);
    SI.nPos      := Pos;
    SI.nTrackPos := 0;
    SetScrollInfo(ZoomBar.Handle, SB_CTL, SI, True);
  finally
    ZoomBar.OnChange := ZoomBarChange;
  end;
end;

procedure TFormMain.RecomputeSpectrogram;
begin
  RenderTimer.Enabled := False;
  FreeAndNil(FSpecgram);
  if FWavFile = nil then Exit;
  FSpecgram := TSpectrogramData.Create;
  FSpecgram.Prepare(FWavFile, GetFFTSize, GetWindowType);
  RenderSpectrogram;
  PaintBox.Invalidate;
  WaveformBox.Invalidate;
end;

procedure TFormMain.RenderSpectrogram;
var
  R: TRect;
  W, H: Integer;
begin
  if FSpecgram = nil then Exit;
  R := SpectRect;
  W := R.Right  - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then Exit;
  if FDisplayBmp = nil then
    FDisplayBmp := TBitmap.Create;
  FSpecgram.Render(FDisplayBmp, W, H, FZoomStart, FZoomEnd,
                   ChkBGSub.Checked, TrkGain.Position, SPECTROGRAM_GAMMA,
                   TrkFloor.Position, TrkCeiling.Position,
                   IdxToColorScheme(CbxColorScheme.ItemIndex));
end;

procedure TFormMain.ScheduleRender;
begin
  RenderTimer.Enabled := False;
  RenderTimer.Enabled := True;
end;

procedure TFormMain.RenderTimerTick(Sender: TObject);
begin
  RenderTimer.Enabled := False;
  if FSpecgram = nil then Exit;
  RenderSpectrogram;
  PaintBox.Invalidate;
end;

procedure TFormMain.ResetPlaybackUI;
begin
  BtnPlay.Enabled  := FWavFile <> nil;
  BtnPause.Enabled := False;
  BtnStop.Enabled  := False;
end;

{ ---- form lifecycle -------------------------------------------------------- }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FWavFile    := nil;
  FSpecgram   := nil;
  FDisplayBmp := nil;
  FCursorPos  := 0;
  FWavePlayer := TWaveOutPlayer.Create;
  FZoomStart  := 0.0;
  FZoomEnd    := 1.0;
  FDragging   := False;
  UpdateZoomBar;
  StatusBar.Panels[0].Text := 'Ready. Open a WAV file.';
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Timer.Enabled := False;
  FWavePlayer.Stop;
  FWavePlayer.Free;
  FDisplayBmp.Free;
  FSpecgram.Free;
  FWavFile.Free;
end;

{ ---- file loading ---------------------------------------------------------- }

procedure TFormMain.BtnOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;

  Timer.Enabled := False;
  FWavePlayer.Stop;
  FCursorPos := 0;
  FreeAndNil(FSpecgram);
  FreeAndNil(FWavFile);
  BtnPlay.Enabled  := False;
  BtnPause.Enabled := False;
  BtnStop.Enabled  := False;

  try
    FWavFile := TWavFile.Create;
    FWavFile.LoadFromFile(OpenDialog.FileName);

    StatusBar.Panels[0].Text := Format(
      '%s  |  %.2f s  |  %d Hz  |  %d-bit  |  %d ch',
      [ExtractFileName(OpenDialog.FileName),
       FWavFile.Info.DurationSec,
       FWavFile.Info.SampleRate,
       FWavFile.Info.BitsPerSample,
       FWavFile.Info.Channels]);

    Screen.Cursor := crHourGlass;
    try
      RecomputeSpectrogram;
    finally
      Screen.Cursor := crDefault;
    end;

    FZoomStart := 0.0;
    FZoomEnd   := 1.0;
    UpdateZoomBar;
    BtnPlay.Enabled := True;

  except
    on E: Exception do
    begin
      FreeAndNil(FWavFile);
      FreeAndNil(FSpecgram);
      ShowMessage('Error loading file:'#13#10 + E.Message);
    end;
  end;
end;

{ ---- playback controls ----------------------------------------------------- }

procedure TFormMain.BtnPlayClick(Sender: TObject);
var
  OutRate, ActualRate: Cardinal;
begin
  if FWavFile = nil then Exit;
  try
    if FWavePlayer.IsPaused then
      FWavePlayer.Resume
    else
    begin
      OutRate := Round(FWavFile.Info.SampleRate * PLAYBACK_RATE);
      FWavePlayer.Load(FWavFile.Samples, OutRate, ActualRate);
      FWavePlayer.Play;
      FCursorPos := 0;
      if ActualRate <> OutRate then
        StatusBar.Panels[0].Text := Format(
          'Requested %d Hz, using %d Hz (%.1f%% speed)',
          [OutRate, ActualRate, ActualRate / FWavFile.Info.SampleRate * 100])
      else
        StatusBar.Panels[0].Text := Format(
          '%d Hz  |  %.1f%% speed',
          [ActualRate, PLAYBACK_RATE * 100]);
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Audio playback failed:'#13#10 + E.Message);
      Exit;
    end;
  end;
  Timer.Enabled    := True;
  BtnPlay.Enabled  := False;
  BtnPause.Enabled := True;
  BtnStop.Enabled  := True;
end;

procedure TFormMain.BtnPauseClick(Sender: TObject);
begin
  Timer.Enabled := False;
  FWavePlayer.Pause;
  BtnPlay.Enabled  := True;
  BtnPause.Enabled := False;
end;

procedure TFormMain.BtnStopClick(Sender: TObject);
begin
  Timer.Enabled := False;
  FWavePlayer.Stop;
  FCursorPos := 0;
  ResetPlaybackUI;
  PaintBox.Invalidate;
  WaveformBox.Invalidate;
end;

{ ---- playback timer -------------------------------------------------------- }

procedure TFormMain.TimerTick(Sender: TObject);
var
  Pos:    Double;
  DurSec: Double;
begin
  if FWavePlayer.HasEnded then
  begin
    Timer.Enabled := False;
    FWavePlayer.Stop;
    FCursorPos := 0;
    ResetPlaybackUI;
    PaintBox.Invalidate;
    WaveformBox.Invalidate;
    Exit;
  end;

  if not (FWavePlayer.IsPlaying or FWavePlayer.IsPaused) then Exit;

  Pos        := FWavePlayer.GetNormalizedPosition;
  FCursorPos := Pos;

  if FWavFile <> nil then
  begin
    DurSec := FWavFile.Info.DurationSec;
    StatusBar.Panels[1].Text := Format('%.3f / %.3f s', [Pos * DurSec, DurSec]);
  end;

  PaintBox.Invalidate;
  WaveformBox.Invalidate;
end;

{ ---- settings -------------------------------------------------------------- }

procedure TFormMain.CbxWindowChange(Sender: TObject);
begin
  if FWavFile = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    RecomputeSpectrogram;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormMain.CbxFFTSizeChange(Sender: TObject);
begin
  CbxWindowChange(Sender);
end;

procedure TFormMain.TrkGainChange(Sender: TObject);
var
  G: Integer;
begin
  G := TrkGain.Position;
  if G = 0 then LblGainVal.Caption := '0 dB'
  else          LblGainVal.Caption := '+' + IntToStr(G) + ' dB';
  ScheduleRender;
end;

procedure TFormMain.ChkBGSubChange(Sender: TObject);
begin
  if FSpecgram = nil then Exit;
  RenderSpectrogram;
  PaintBox.Invalidate;
end;

procedure TFormMain.CbxColorSchemeChange(Sender: TObject);
begin
  if FSpecgram = nil then Exit;
  RenderSpectrogram;
  PaintBox.Invalidate;
end;

procedure TFormMain.TrkFloorChange(Sender: TObject);
begin
  LblFloor.Caption := Format('Floor: %d dB', [TrkFloor.Position]);
  ScheduleRender;
end;

procedure TFormMain.TrkCeilingChange(Sender: TObject);
begin
  LblCeiling.Caption := Format('Ceiling: %d dB', [TrkCeiling.Position]);
  ScheduleRender;
end;

procedure TFormMain.ZoomBarChange(Sender: TObject);
var
  SI:        TScrollInfo;
  ZoomWidth: Double;
begin
  SI.cbSize := SizeOf(TScrollInfo);
  SI.fMask  := SIF_POS;
  GetScrollInfo(ZoomBar.Handle, SB_CTL, SI);

  ZoomWidth  := FZoomEnd - FZoomStart;
  FZoomStart := SI.nPos / 1000.0;
  FZoomEnd   := FZoomStart + ZoomWidth;
  if FZoomEnd > 1.0 then
  begin
    FZoomEnd   := 1.0;
    FZoomStart := 1.0 - ZoomWidth;
    if FZoomStart < 0.0 then FZoomStart := 0.0;
  end;
  RenderSpectrogram;
  PaintBox.Invalidate;
  WaveformBox.Invalidate;
end;

{ ---- zoom drag ------------------------------------------------------------- }

procedure TFormMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  if (Button <> mbLeft) or (FSpecgram = nil) then Exit;
  R := SpectRect;
  if not PtInRect(R, Point(X, Y)) then Exit;

  FDragging      := True;
  FDragStartX    := X;
  FDragZoomStart := FZoomStart;
  FDragZoomEnd   := FZoomEnd;
  FDragZoomFrac  := FZoomStart +
    (X - R.Left) / Max(1, R.Right - R.Left) * (FZoomEnd - FZoomStart);
end;

procedure TFormMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
end;

procedure TFormMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  R:            TRect;
  Delta:        Integer;
  OldW, NewW:   Double;
  NewStart:     Double;
  DurSec:       Double;
  TimeAtCursor: Double;
  FreqAtCursor: Double;
begin
  R := SpectRect;

  if FDragging then
  begin
    Delta := X - FDragStartX;
    if Delta > 400  then Delta := 400;
    if Delta < -400 then Delta := -400;

    OldW := FDragZoomEnd - FDragZoomStart;
    if OldW < 1.0e-9 then OldW := 1.0e-9;

    NewW := OldW * Power(0.99, Delta);
    if NewW < 0.001 then NewW := 0.001;
    if NewW > 1.0   then NewW := 1.0;

    NewStart := FDragZoomFrac -
      (FDragZoomFrac - FDragZoomStart) / OldW * NewW;

    FZoomStart := NewStart;
    FZoomEnd   := NewStart + NewW;

    if FZoomStart < 0.0 then
    begin
      FZoomStart := 0.0;
      FZoomEnd   := NewW;
    end;
    if FZoomEnd > 1.0 then
    begin
      FZoomEnd   := 1.0;
      FZoomStart := 1.0 - NewW;
      if FZoomStart < 0.0 then FZoomStart := 0.0;
    end;

    UpdateZoomBar;
    RenderSpectrogram;
    PaintBox.Invalidate;
    WaveformBox.Invalidate;
  end;

  if (FSpecgram = nil) or (FWavFile = nil) then Exit;
  if not PtInRect(R, Point(X, Y)) then
  begin
    StatusBar.Panels[2].Text := '';
    Exit;
  end;

  DurSec       := FWavFile.Info.DurationSec;
  TimeAtCursor := FZoomStart * DurSec +
    (X - R.Left) / Max(1, R.Right - R.Left) * (FZoomEnd - FZoomStart) * DurSec;
  FreqAtCursor := (1.0 - (Y - R.Top) / Max(1, R.Bottom - R.Top)) *
    FWavFile.Info.SampleRate / 2000.0;
  StatusBar.Panels[2].Text := Format('%.4f s  |  %.1f kHz',
    [TimeAtCursor, FreqAtCursor]);
end;

{ ---- painting -------------------------------------------------------------- }

procedure TFormMain.WaveformBoxPaint(Sender: TObject);
const
  BG_COLOR   = $00202020;
  WAVE_COLOR = $00BBBBBB;
  ZERO_COLOR = $00444444;
  VPAD       = 4;
var
  Samples:      TArray<Single>;
  TotalSamples: Integer;
  R:            TRect;
  W, H, MidY:  Integer;
  X, S0, S1, I: Integer;
  Frac0, Frac1: Double;
  MinVal, MaxVal, V: Single;
  YHi, YLo:    Integer;
  VisFrac:      Double;
  CurX:         Integer;
begin
  WaveformBox.Canvas.Brush.Color := BG_COLOR;
  WaveformBox.Canvas.FillRect(WaveformBox.ClientRect);

  if FWavFile = nil then Exit;

  R    := Rect(LEFT_MARGIN, VPAD, WaveformBox.Width - RIGHT_MARGIN, WaveformBox.Height - VPAD);
  W    := R.Right - R.Left;
  H    := R.Bottom - R.Top;
  MidY := R.Top + H div 2;
  if (W <= 0) or (H <= 0) then Exit;

  Samples      := FWavFile.Samples;
  TotalSamples := Length(Samples);
  if TotalSamples = 0 then Exit;

  { Centre (zero) line }
  WaveformBox.Canvas.Pen.Color := ZERO_COLOR;
  WaveformBox.Canvas.Pen.Width := 1;
  WaveformBox.Canvas.MoveTo(R.Left,  MidY);
  WaveformBox.Canvas.LineTo(R.Right, MidY);

  { Waveform: min/max envelope per pixel column }
  WaveformBox.Canvas.Pen.Color := WAVE_COLOR;
  for X := 0 to W - 1 do
  begin
    Frac0 := FZoomStart + X       / W * (FZoomEnd - FZoomStart);
    Frac1 := FZoomStart + (X + 1) / W * (FZoomEnd - FZoomStart);
    S0 := Max(0, Min(TotalSamples - 1, Round(Frac0 * TotalSamples)));
    S1 := Max(S0 + 1, Min(TotalSamples, Round(Frac1 * TotalSamples)));

    MinVal :=  1.0;
    MaxVal := -1.0;
    for I := S0 to S1 - 1 do
    begin
      V := Samples[I];
      if V < MinVal then MinVal := V;
      if V > MaxVal then MaxVal := V;
    end;

    YHi := MidY - Round(MaxVal * (H div 2));
    YLo := MidY - Round(MinVal * (H div 2));
    if YHi = YLo then Inc(YLo);  // always at least 1 px

    WaveformBox.Canvas.MoveTo(R.Left + X, YHi);
    WaveformBox.Canvas.LineTo(R.Left + X, YLo);
  end;

  { Playback cursor }
  if (FCursorPos > 0.0) and (FZoomEnd > FZoomStart) then
  begin
    VisFrac := (FCursorPos - FZoomStart) / (FZoomEnd - FZoomStart);
    if (VisFrac >= 0.0) and (VisFrac <= 1.0) then
    begin
      CurX := R.Left + Round(VisFrac * W);
      WaveformBox.Canvas.Pen.Color := clWhite;
      WaveformBox.Canvas.Pen.Width := 2;
      WaveformBox.Canvas.MoveTo(CurX, R.Top);
      WaveformBox.Canvas.LineTo(CurX, R.Bottom);
      WaveformBox.Canvas.Pen.Width := 1;
    end;
  end;
end;

procedure TFormMain.DrawAxes(C: TCanvas; const R: TRect);
const
  CLR_AXIS = clWhite;
  CLR_GRID = $00444444;
var
  MaxHz, DurSec:               Double;
  StartTime, EndTime, ZoomDur: Double;
  FreqStep, TimeStep:          Double;
  Freq, T:                     Double;
  FirstTick:                   Double;
  I, X, Y, TextH, TextW:      Integer;
  NumTicks:                    Integer;
  Lbl:                         string;
begin
  if FWavFile = nil then Exit;

  MaxHz  := FWavFile.Info.SampleRate / 2.0;
  DurSec := FWavFile.Info.DurationSec;

  C.Font.Size   := 8;
  C.Font.Color  := CLR_AXIS;
  C.Brush.Style := bsClear;

  if MaxHz >= 40000      then FreqStep := 10000
  else if MaxHz >= 10000 then FreqStep := 5000
  else                        FreqStep := 1000;

  NumTicks := Floor(MaxHz / FreqStep);
  TextH    := C.TextHeight('0');

  for I := 0 to NumTicks do
  begin
    Freq := I * FreqStep;
    Y    := R.Bottom - Round(Freq / MaxHz * (R.Bottom - R.Top));

    C.Pen.Color := CLR_AXIS;
    C.Pen.Width := 1;
    C.MoveTo(R.Left - 4, Y);
    C.LineTo(R.Left, Y);

    C.Pen.Color := CLR_GRID;
    C.MoveTo(R.Left, Y);
    C.LineTo(R.Right, Y);

    if Freq >= 1000 then Lbl := Format('%gk', [Freq / 1000])
    else                 Lbl := Format('%g',  [Freq]);
    TextW := C.TextWidth(Lbl);
    C.Font.Color := CLR_AXIS;
    C.TextOut(R.Left - TextW - 6, Y - TextH div 2, Lbl);
  end;

  StartTime := FZoomStart * DurSec;
  EndTime   := FZoomEnd   * DurSec;
  ZoomDur   := EndTime - StartTime;
  if ZoomDur < 1.0e-9 then Exit;

  if      ZoomDur >= 8.0  then TimeStep := 2.0
  else if ZoomDur >= 4.0  then TimeStep := 1.0
  else if ZoomDur >= 2.0  then TimeStep := 0.5
  else if ZoomDur >= 0.8  then TimeStep := 0.2
  else if ZoomDur >= 0.3  then TimeStep := 0.1
  else if ZoomDur >= 0.08 then TimeStep := 0.02
  else if ZoomDur >= 0.03 then TimeStep := 0.01
  else                         TimeStep := 0.002;

  FirstTick := Ceil(StartTime / TimeStep - 1.0e-9) * TimeStep;

  T := FirstTick;
  while T <= EndTime + TimeStep * 1.0e-6 do
  begin
    X := R.Left + Round((T - StartTime) / ZoomDur * (R.Right - R.Left));
    if (X >= R.Left) and (X <= R.Right) then
    begin
      C.Pen.Color := CLR_AXIS;
      C.MoveTo(X, R.Bottom);
      C.LineTo(X, R.Bottom + 4);

      C.Pen.Color := CLR_GRID;
      C.MoveTo(X, R.Top);
      C.LineTo(X, R.Bottom);

      if ZoomDur < 0.5 then Lbl := Format('%.3f s', [T])
      else                  Lbl := Format('%.2g s', [T]);
      TextW := C.TextWidth(Lbl);
      C.Font.Color := CLR_AXIS;
      C.TextOut(X - TextW div 2, R.Bottom + 5, Lbl);
    end;
    T := T + TimeStep;
  end;
end;

procedure TFormMain.DrawCursor(C: TCanvas; const R: TRect);
var
  VisFrac: Double;
  X:       Integer;
begin
  if (FCursorPos <= 0.0) or (FZoomEnd <= FZoomStart) then Exit;
  VisFrac := (FCursorPos - FZoomStart) / (FZoomEnd - FZoomStart);
  if (VisFrac < 0.0) or (VisFrac > 1.0) then Exit;
  X := R.Left + Round(VisFrac * (R.Right - R.Left));
  C.Pen.Color := clWhite;
  C.Pen.Width := 2;
  C.MoveTo(X, R.Top);
  C.LineTo(X, R.Bottom);
  C.Pen.Width := 1;
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject);
var
  R:    TRect;
  W, H: Integer;
  Msg:  string;
begin
  R := SpectRect;
  W := R.Right  - R.Left;
  H := R.Bottom - R.Top;

  PaintBox.Canvas.Brush.Color := $00202020;
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  if FSpecgram = nil then
  begin
    Msg := 'Open a WAV file to display the spectrogram';
    PaintBox.Canvas.Font.Color  := clGray;
    PaintBox.Canvas.Font.Size   := 12;
    PaintBox.Canvas.Brush.Style := bsClear;
    PaintBox.Canvas.TextOut(
      PaintBox.Width  div 2 - PaintBox.Canvas.TextWidth(Msg)  div 2,
      PaintBox.Height div 2 - PaintBox.Canvas.TextHeight(Msg) div 2,
      Msg);
    Exit;
  end;

  if (FDisplayBmp = nil) or (FDisplayBmp.Width <> W) or (FDisplayBmp.Height <> H) then
    RenderSpectrogram;

  if (FDisplayBmp <> nil) and (FDisplayBmp.Width > 0) then
    BitBlt(PaintBox.Canvas.Handle, R.Left, R.Top, W, H,
           FDisplayBmp.Canvas.Handle, 0, 0, SRCCOPY);

  DrawAxes(PaintBox.Canvas, R);
  DrawCursor(PaintBox.Canvas, R);
end;

end.
