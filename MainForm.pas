unit MainForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.PngImage,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  FFT, WavReader, Spectrogram, WaveOutPlayer;

const
  LEFT_MARGIN = 65;
  BOTTOM_MARGIN = 35;
  TOP_MARGIN = 8;
  RIGHT_MARGIN = 10;
  SPECTROGRAM_GAMMA = 2.5;
  WAVE_VPAD = 12;

type
  TFormMain = class(TForm)
    PanelLeft: TPanel;
    BtnOpen: TButton;
    BtnPlay: TButton;
    BtnPause: TButton;
    BtnStop: TButton;
    LblWindow: TLabel;
    CbxWindow: TComboBox;
    LblFFTSize: TLabel;
    CbxFFTSize: TComboBox;
    LblGainCaption: TLabel;
    LblGainVal: TLabel;
    TrkGain: TTrackBar;
    ChkBGSub: TCheckBox;
    ChkFilter: TCheckBox;
    LblColorScheme: TLabel;
    CbxColorScheme: TComboBox;
    LblFloor: TLabel;
    TrkFloor: TTrackBar;
    LblCeiling: TLabel;
    TrkCeiling: TTrackBar;
    LblMaxFreq: TLabel;
    TrkMaxFreq: TTrackBar;
    StatusBar: TStatusBar;
    ZoomBar: TScrollBar;
    PanelMain: TPanel;
    WaveformBox: TPaintBox;
    Splitter1: TSplitter;
    PaintBox: TPaintBox;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    Timer: TTimer;
    RenderTimer: TTimer;
    LblSpeed: TLabel;
    CbxSpeed: TComboBox;
    LblSave: TLabel;
    CbxSaveTarget: TComboBox;
    BtnSavePNG: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOpenClick(Sender: TObject);
    procedure BtnSavePNGClick(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxPaint(Sender: TObject);
    procedure WaveformBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AppMouseWheel(var Msg: TMsg; var Handled: Boolean);
    procedure TimerTick(Sender: TObject);
    procedure CbxWindowChange(Sender: TObject);
    procedure CbxFFTSizeChange(Sender: TObject);
    procedure TrkGainChange(Sender: TObject);
    procedure ChkBGSubChange(Sender: TObject);
    procedure ChkFilterChange(Sender: TObject);
    procedure CbxColorSchemeChange(Sender: TObject);
    procedure TrkFloorChange(Sender: TObject);
    procedure TrkCeilingChange(Sender: TObject);
    procedure TrkMaxFreqChange(Sender: TObject);
    procedure RenderTimerTick(Sender: TObject);
    procedure ZoomBarChange(Sender: TObject);
  private
    FWavFile: TWavFile;
    FSpecgram: TSpectrogramData;
    FCursorPos: Double;
    FWavePlayer: TWaveOutPlayer;
    FDisplayBmp: TBitmap;

    FFileInfo: string;
    FMaxPlotHz: Double;
    FZoomStart: Double;
    FZoomEnd: Double;
    FDragging: Boolean;
    FDragStartX: Integer;
    FDragCurrentX: Integer;

    function SpectRect: TRect;
    function WaveRect: TRect;
    function GetFFTSize: Integer;
    function GetWindowType: TWindowType;
    function GetPlaybackRate: Double;
    procedure RecomputeSpectrogram;
    procedure RenderSpectrogram;
    procedure ScheduleRender;
    procedure DrawAxes(C: TCanvas; const R: TRect);
    procedure DrawCursor(C: TCanvas; const R: TRect);
    procedure RenderWaveform(C: TCanvas; PxW, PxH: Integer);
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
    1:
      Result := csInferno;
    2:
      Result := csMagma;
    3:
      Result := csGrayscale;
    4:
      Result := csGrayscaleInv;
    5:
      Result := csPlasma;
    6:
      Result := csCividis;
    7:
      Result := csMako;
    8:
      Result := csRocket;
    9:
      Result := csSpectral;
  else
    Result := csViridis;
  end;
end;

{ ---- helpers --------------------------------------------------------------- }



function TFormMain.SpectRect: TRect;
begin
  Result := Rect(LEFT_MARGIN, TOP_MARGIN, PaintBox.Width - RIGHT_MARGIN, PaintBox.Height - BOTTOM_MARGIN);
end;



function TFormMain.WaveRect: TRect;
begin
  Result := Rect(LEFT_MARGIN, WAVE_VPAD, WaveformBox.Width - RIGHT_MARGIN, WaveformBox.Height - WAVE_VPAD);
end;



function TFormMain.GetFFTSize: Integer;
begin
  case CbxFFTSize.ItemIndex of
    0: Result := 64;
    1: Result := 128;
    2: Result := 256;
    3: Result := 512;
    4: Result := 1024;
    5: Result := 2048;
    6: Result := 4096;
    7: Result := 8192;
    8: Result := 16384;
  else
    Result := 4096;
  end;
end;



function TFormMain.GetWindowType: TWindowType;
begin
  case CbxWindow.ItemIndex of
    0:
      Result := wtRectangular;
    1:
      Result := wtHann;
    2:
      Result := wtHamming;
    3:
      Result := wtBlackman;
    4:
      Result := wtFlatTop;
  else
    Result := wtHann;
  end;
end;



function TFormMain.GetPlaybackRate: Double;
begin
  case CbxSpeed.ItemIndex of
    0: Result := 0.05;
    1: Result := 0.10;
    2: Result := 0.125;
    3: Result := 0.20;
    4: Result := 0.25;
    5: Result := 0.50;
    6: Result := 1.00;
  else
    Result := 0.10;
  end;
end;



procedure TFormMain.UpdateZoomBar;
var
  SI: TScrollInfo;
  PageSz, Pos: Integer;
begin
  if not ZoomBar.HandleAllocated() then
    Exit();

  PageSz := Max(1, Min(1000, Round((FZoomEnd - FZoomStart) * 1000)));
  Pos := Round(FZoomStart * 1000);
  if Pos > 1000 - PageSz then
    Pos := 1000 - PageSz;
  if Pos < 0 then
    Pos := 0;

  ZoomBar.OnChange := nil;
  try
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_ALL;
    SI.nMin := 0;
    SI.nMax := 1000;
    SI.nPage := UINT(PageSz);
    SI.nPos := Pos;
    SI.nTrackPos := 0;
    SetScrollInfo(ZoomBar.Handle, SB_CTL, SI, True);
  finally
    ZoomBar.OnChange := ZoomBarChange;
  end;
  // SetScrollInfo marks dirty but doesn't always flush; force immediate repaint
  InvalidateRect(ZoomBar.Handle, nil, True);
  UpdateWindow(ZoomBar.Handle);
end;



procedure TFormMain.RecomputeSpectrogram;
begin
  RenderTimer.Enabled := False;
  FreeAndNil(FSpecgram);
  if FWavFile = nil then
    Exit();
  FSpecgram := TSpectrogramData.Create();
  FSpecgram.Prepare(FWavFile, GetFFTSize(), GetWindowType());
  RenderSpectrogram();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;



procedure TFormMain.RenderSpectrogram;
var
  R: TRect;
  W, H: Integer;
begin
  if FSpecgram = nil then
    Exit();
  R := SpectRect();
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then
    Exit();
  if FDisplayBmp = nil then
    FDisplayBmp := TBitmap.Create();
  FSpecgram.Render(FDisplayBmp, W, H, FZoomStart, FZoomEnd, ChkBGSub.Checked, TrkGain.Position, SPECTROGRAM_GAMMA, TrkFloor.Position, TrkCeiling.Position,
    IdxToColorScheme(CbxColorScheme.ItemIndex), FMaxPlotHz, ChkFilter.Checked, ChkFilter.Checked);
end;



procedure TFormMain.ScheduleRender;
begin
  RenderTimer.Enabled := False;
  RenderTimer.Enabled := True;
end;



procedure TFormMain.RenderTimerTick(Sender: TObject);
begin
  RenderTimer.Enabled := False;
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
end;



procedure TFormMain.ResetPlaybackUI;
begin
  BtnPlay.Enabled := FWavFile <> nil;
  BtnPause.Enabled := False;
  BtnStop.Enabled := False;
  if FFileInfo <> '' then
    StatusBar.Panels[0].Text := FFileInfo;
  StatusBar.Panels[1].Text := '';
end;

{ ---- form lifecycle -------------------------------------------------------- }



procedure TFormMain.FormCreate(Sender: TObject);
begin
  FWavFile := nil;
  FSpecgram := nil;
  FDisplayBmp := nil;
  FCursorPos := 0;
  FWavePlayer := TWaveOutPlayer.Create();
  FZoomStart := 0.0;
  FZoomEnd := 1.0;
  FDragging := False;
  PanelMain.ControlStyle := PanelMain.ControlStyle + [csOpaque];
  UpdateZoomBar();
  Application.OnMessage := AppMouseWheel;
  StatusBar.Panels[0].Text := 'Ready. Open an audio file.';
end;



procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Application.OnMessage := nil;
  Timer.Enabled := False;
  FWavePlayer.Stop();
  FWavePlayer.Free();
  FDisplayBmp.Free();
  FSpecgram.Free();
  FWavFile.Free();
end;

{ ---- file loading ---------------------------------------------------------- }



procedure TFormMain.BtnOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute() then
    Exit();

  Timer.Enabled := False;
  FWavePlayer.Stop();
  FCursorPos := 0;
  FreeAndNil(FSpecgram);
  FreeAndNil(FWavFile);
  BtnPlay.Enabled := False;
  BtnPause.Enabled := False;
  BtnStop.Enabled := False;

  try
    FWavFile := TWavFile.Create();
    FWavFile.LoadFromFile(OpenDialog.FileName);

    FFileInfo := Format('%s  |  %.2f s  |  %d Hz  |  %d-bit  |  %d ch', [ExtractFileName(OpenDialog.FileName), FWavFile.Info.DurationSec,
      FWavFile.Info.SampleRate, FWavFile.Info.BitsPerSample, FWavFile.Info.Channels]);
    StatusBar.Panels[0].Text := FFileInfo;

    Screen.Cursor := crHourGlass;
    try
      RecomputeSpectrogram();
    finally
      Screen.Cursor := crDefault;
    end;

    FZoomStart := 0.0;
    FZoomEnd := 1.0;
    UpdateZoomBar();

    TrkMaxFreq.Max := FWavFile.Info.SampleRate div 2000;
    TrkMaxFreq.Min := 1;
    TrkMaxFreq.Position := TrkMaxFreq.Max;
    FMaxPlotHz := TrkMaxFreq.Position * 1000.0;
    LblMaxFreq.Caption := Format('Max: %d kHz', [TrkMaxFreq.Position]);

    BtnPlay.Enabled := True;
    BtnSavePNG.Enabled := True;

  except
    on E: Exception do begin
      FreeAndNil(FWavFile);
      FreeAndNil(FSpecgram);
      ShowMessage('Error loading file:'#13#10 + E.Message);
    end;
  end;
end;

{ ---- PNG export ------------------------------------------------------------ }



procedure TFormMain.BtnSavePNGClick(Sender: TObject);
var
  WavBmp, SpectBmp, Bmp: TBitmap;
  Png: TPngImage;
begin
  if FSpecgram = nil then
    Exit();
  if not SaveDialog.Execute() then
    Exit();

  WavBmp   := TBitmap.Create();
  SpectBmp := TBitmap.Create();
  Bmp      := TBitmap.Create();
  try
    WavBmp.PixelFormat := pf24bit;
    WavBmp.Width  := WaveformBox.Width;
    WavBmp.Height := WaveformBox.Height;
    RenderWaveform(WavBmp.Canvas, WavBmp.Width, WavBmp.Height);

    SpectBmp.PixelFormat := pf24bit;
    SpectBmp.Width  := PaintBox.Width;
    SpectBmp.Height := PaintBox.Height;
    PaintBox.Perform(WM_PAINT, WPARAM(SpectBmp.Canvas.Handle), 0);

    Png := TPngImage.Create();
    try
      case CbxSaveTarget.ItemIndex of
        0: Png.Assign(WavBmp);
        1: Png.Assign(SpectBmp);
      else
        Bmp.PixelFormat := pf24bit;
        Bmp.Width  := Max(WavBmp.Width, SpectBmp.Width);
        Bmp.Height := WavBmp.Height + SpectBmp.Height;
        Bmp.Canvas.Draw(0, 0, WavBmp);
        Bmp.Canvas.Draw(0, WavBmp.Height, SpectBmp);
        Png.Assign(Bmp);
      end;
      Png.SaveToFile(SaveDialog.FileName);
    finally
      Png.Free();
    end;
  finally
    WavBmp.Free();
    SpectBmp.Free();
    Bmp.Free();
  end;
end;



{ ---- playback controls ----------------------------------------------------- }



procedure TFormMain.BtnPlayClick(Sender: TObject);
var
  OutRate, ActualRate: Cardinal;
begin
  if FWavFile = nil then
    Exit();
  try
    if FWavePlayer.IsPaused() then
      FWavePlayer.Resume()
    else begin
      OutRate := Round(FWavFile.Info.SampleRate * GetPlaybackRate());
      FWavePlayer.Load(FWavFile.Samples, OutRate, ActualRate);
      FWavePlayer.Play();
      if FZoomStart > 0.0 then begin
        FWavePlayer.SeekToNormalized(FZoomStart);
        FCursorPos := FZoomStart;
      end
      else
        FCursorPos := 0;
      if ActualRate <> OutRate then
        StatusBar.Panels[0].Text := Format('Requested %d Hz, using %d Hz (%.1f%% speed)', [OutRate, ActualRate, ActualRate / FWavFile.Info.SampleRate * 100])
      else
        StatusBar.Panels[0].Text := Format('%d Hz  |  %.1f%% speed', [ActualRate, GetPlaybackRate() * 100]);
    end;
  except
    on E: Exception do begin
      ShowMessage('Audio playback failed:'#13#10 + E.Message);
      Exit();
    end;
  end;
  Timer.Enabled := True;
  BtnPlay.Enabled := False;
  BtnPause.Enabled := True;
  BtnStop.Enabled := True;
end;



procedure TFormMain.BtnPauseClick(Sender: TObject);
begin
  Timer.Enabled := False;
  FWavePlayer.Pause();
  BtnPlay.Enabled := True;
  BtnPause.Enabled := False;
end;



procedure TFormMain.BtnStopClick(Sender: TObject);
begin
  Timer.Enabled := False;
  FWavePlayer.Stop();
  FCursorPos := 0;
  ResetPlaybackUI();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;

{ ---- playback timer -------------------------------------------------------- }



procedure TFormMain.TimerTick(Sender: TObject);
var
  Pos: Double;
  DurSec: Double;
begin
  if FWavePlayer.HasEnded() then begin
    Timer.Enabled := False;
    FWavePlayer.Stop();
    FCursorPos := 0;
    ResetPlaybackUI();
    PaintBox.Invalidate();
    WaveformBox.Invalidate();
    Exit();
  end;

  if not(FWavePlayer.IsPlaying() or FWavePlayer.IsPaused()) then
    Exit();

  Pos := FWavePlayer.GetNormalizedPosition();
  FCursorPos := Pos;

  if FWavFile <> nil then begin
    DurSec := FWavFile.Info.DurationSec;
    StatusBar.Panels[1].Text := Format('%.3f / %.3f s', [Pos * DurSec, DurSec]);
  end;

  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;

{ ---- settings -------------------------------------------------------------- }



procedure TFormMain.CbxWindowChange(Sender: TObject);
begin
  if FWavFile = nil then
    Exit();
  Screen.Cursor := crHourGlass;
  try
    RecomputeSpectrogram();
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
  if G = 0 then
    LblGainVal.Caption := '0 dB'
  else
    LblGainVal.Caption := '+' + IntToStr(G) + ' dB';
  ScheduleRender();
end;



procedure TFormMain.ChkBGSubChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
end;



procedure TFormMain.ChkFilterChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
end;



procedure TFormMain.CbxColorSchemeChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;



procedure TFormMain.TrkFloorChange(Sender: TObject);
begin
  LblFloor.Caption := Format('Floor: %d dB', [TrkFloor.Position]);
  ScheduleRender();
end;



procedure TFormMain.TrkCeilingChange(Sender: TObject);
begin
  LblCeiling.Caption := Format('Ceiling: %d dB', [TrkCeiling.Position]);
  ScheduleRender();
end;



procedure TFormMain.TrkMaxFreqChange(Sender: TObject);
begin
  FMaxPlotHz := TrkMaxFreq.Position * 1000.0;
  LblMaxFreq.Caption := Format('Max: %d kHz', [TrkMaxFreq.Position]);
  ScheduleRender();
end;



procedure TFormMain.ZoomBarChange(Sender: TObject);
var
  SI: TScrollInfo;
  ZoomWidth: Double;
begin
  SI.cbSize := SizeOf(TScrollInfo);
  SI.fMask := SIF_POS;
  GetScrollInfo(ZoomBar.Handle, SB_CTL, SI);

  ZoomWidth := FZoomEnd - FZoomStart;
  FZoomStart := SI.nPos / 1000.0;
  FZoomEnd := FZoomStart + ZoomWidth;
  if FZoomEnd > 1.0 then begin
    FZoomEnd := 1.0;
    FZoomStart := 1.0 - ZoomWidth;
    if FZoomStart < 0.0 then
      FZoomStart := 0.0;
  end;
  RenderSpectrogram();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;

{ ---- zoom drag ------------------------------------------------------------- }



procedure TFormMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  if (Button <> mbLeft) or (FSpecgram = nil) then
    Exit();
  R := SpectRect();
  if not PtInRect(R, Point(X, Y)) then
    Exit();
  FDragging := True;
  FDragStartX := X;
  FDragCurrentX := X;
end;



procedure TFormMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
  W, SelX1, SelX2: Integer;
  Frac1, Frac2, ClickFrac: Double;
begin
  if not FDragging then
    Exit();
  FDragging := False;
  R := SpectRect();
  W := Max(1, R.Right - R.Left);

  if Abs(FDragCurrentX - FDragStartX) < 4 then begin
    // Click: move playback position
    ClickFrac := FZoomStart + (Max(R.Left, Min(R.Right, FDragStartX)) - R.Left) / W * (FZoomEnd - FZoomStart);
    FCursorPos := ClickFrac;
    if FWavePlayer.IsPlaying() or FWavePlayer.IsPaused() then
      FWavePlayer.SeekToNormalized(ClickFrac);
    PaintBox.Invalidate();
    WaveformBox.Invalidate();
  end
  else if FDragCurrentX > FDragStartX then begin
    // Zoom into selected region
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    Frac1 := FZoomStart + (SelX1 - R.Left) / W * (FZoomEnd - FZoomStart);
    Frac2 := FZoomStart + (SelX2 - R.Left) / W * (FZoomEnd - FZoomStart);
    FZoomStart := Max(0.0, Frac1);
    FZoomEnd := Min(1.0, Frac2);
    if FZoomEnd <= FZoomStart then
      FZoomEnd := FZoomStart + 0.001;
    UpdateZoomBar();
    RenderSpectrogram();
    PaintBox.Invalidate();
    WaveformBox.Invalidate();
  end
  else begin
    // Drag left: zoom out completely
    FZoomStart := 0.0;
    FZoomEnd := 1.0;
    UpdateZoomBar();
    RenderSpectrogram();
    PaintBox.Invalidate();
    WaveformBox.Invalidate();
  end;
end;



procedure TFormMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
  DurSec: Double;
  TimeAtCursor: Double;
  FreqAtCursor: Double;
begin
  R := SpectRect();

  if FDragging then begin
    FDragCurrentX := X;
    PaintBox.Invalidate();
    WaveformBox.Invalidate();
  end;

  if (FSpecgram = nil) or (FWavFile = nil) then
    Exit();
  if not PtInRect(R, Point(X, Y)) then begin
    StatusBar.Panels[2].Text := '';
    Exit();
  end;

  DurSec := FWavFile.Info.DurationSec;
  TimeAtCursor := FZoomStart * DurSec + (X - R.Left) / Max(1, R.Right - R.Left) * (FZoomEnd - FZoomStart) * DurSec;
  FreqAtCursor := (1.0 - (Y - R.Top) / Max(1, R.Bottom - R.Top)) * FMaxPlotHz / 1000.0;
  StatusBar.Panels[2].Text := Format('%.4f s  |  %.1f kHz', [TimeAtCursor, FreqAtCursor]);
end;

procedure TFormMain.AppMouseWheel(var Msg: TMsg; var Handled: Boolean);
var
  MousePos: TPoint;
  LocalPos: TPoint;
  LocalX, ChartLeft, ChartRight, W: Integer;
  WheelDelta: Integer;
  Frac, T, Span, NewSpan, NewStart, NewEnd, ZoomFactor: Double;
begin
  if Msg.message <> WM_MOUSEWHEEL then
    Exit();
  if FSpecgram = nil then
    Exit();
  MousePos := Point(SmallInt(Msg.lParam and $FFFF), SmallInt(Msg.lParam shr 16));
  LocalPos := PaintBox.ScreenToClient(MousePos);
  if not PtInRect(PaintBox.ClientRect, LocalPos) then begin
    LocalPos := WaveformBox.ScreenToClient(MousePos);
    if not PtInRect(WaveformBox.ClientRect, LocalPos) then
      Exit();
  end;
  WheelDelta := SmallInt(Msg.wParam shr 16);
  ChartLeft := LEFT_MARGIN;
  ChartRight := PaintBox.Width - RIGHT_MARGIN;
  W := ChartRight - ChartLeft;
  if W <= 0 then
    Exit();
  LocalX := Max(ChartLeft, Min(ChartRight, LocalPos.X));
  Frac := (LocalX - ChartLeft) / W;
  T := FZoomStart + Frac * (FZoomEnd - FZoomStart);
  Span := FZoomEnd - FZoomStart;
  ZoomFactor := Power(0.8, WheelDelta / 120.0);
  NewSpan := Max(0.001, Min(1.0, Span * ZoomFactor));
  NewStart := T - Frac * NewSpan;
  NewEnd := NewStart + NewSpan;
  if NewStart < 0.0 then begin
    NewStart := 0.0;
    NewEnd := NewSpan;
  end;
  if NewEnd > 1.0 then begin
    NewEnd := 1.0;
    NewStart := 1.0 - NewSpan;
  end;
  FZoomStart := Max(0.0, NewStart);
  FZoomEnd := Min(1.0, NewEnd);
  UpdateZoomBar();
  RenderSpectrogram();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
  Handled := True;
end;



procedure TFormMain.WaveformBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  if (Button <> mbLeft) or (FSpecgram = nil) then
    Exit();
  R := WaveRect();
  if not PtInRect(R, Point(X, Y)) then
    Exit();
  FDragging := True;
  FDragStartX := X;
  FDragCurrentX := X;
end;



procedure TFormMain.WaveformBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FDragging then begin
    FDragCurrentX := X;
    WaveformBox.Invalidate();
    PaintBox.Invalidate();
  end;
end;



procedure TFormMain.WaveformBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  PaintBoxMouseUp(Sender, Button, Shift, X, Y);
end;



{ ---- painting -------------------------------------------------------------- }



procedure TFormMain.WaveformBoxPaint(Sender: TObject);
begin
  RenderWaveform(WaveformBox.Canvas, WaveformBox.Width, WaveformBox.Height);
end;



procedure TFormMain.RenderWaveform(C: TCanvas; PxW, PxH: Integer);
const
  GRID_COLOR = $00444444;
  AXIS_COLOR = clWhite;
  OUTER_COLOR = $00202020;
var
  Samples: TArray<Single>;
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
  Scheme: TColorScheme;
  VR, VG, VB: Byte;
  BgColor: TColor;
  WaveColor: TColor;
  SelX1, SelX2: Integer;
  OverBmp: TBitmap;
  BF: TBlendFunction;
begin
  Scheme := IdxToColorScheme(CbxColorScheme.ItemIndex);
  if FSpecgram <> nil then begin
    FSpecgram.GetColor(0.0, Scheme, VR, VG, VB);
    BgColor := RGB(VR, VG, VB);
    FSpecgram.GetColor(1.0, Scheme, VR, VG, VB);
    WaveColor := RGB(VR, VG, VB);
  end else begin
    BgColor := clBlack;
    WaveColor := $00BBBBBB;
  end;

  C.Brush.Color := OUTER_COLOR;
  C.FillRect(Rect(0, 0, PxW, PxH));

  R := Rect(LEFT_MARGIN, WAVE_VPAD, PxW - RIGHT_MARGIN, PxH - WAVE_VPAD);
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
      LblY := R.Bottom;
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

  if FWavFile = nil then
    Exit();

  Samples := FWavFile.Samples;
  TotalSamples := Length(Samples);
  if TotalSamples = 0 then
    Exit();

  C.Pen.Color := WaveColor;
  for X := 0 to W - 1 do begin
    Frac0 := FZoomStart + X / W * (FZoomEnd - FZoomStart);
    Frac1 := FZoomStart + (X + 1) / W * (FZoomEnd - FZoomStart);
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

  if (FCursorPos > 0.0) and (FZoomEnd > FZoomStart) then begin
    VisFrac := (FCursorPos - FZoomStart) / (FZoomEnd - FZoomStart);
    if (VisFrac >= 0.0) and (VisFrac <= 1.0) then begin
      CurX := R.Left + Round(VisFrac * W);
      C.Pen.Color := clWhite;
      C.Pen.Width := 2;
      C.MoveTo(CurX, R.Top);
      C.LineTo(CurX, R.Bottom);
      C.Pen.Width := 1;
    end;
  end;

  if FDragging and (FDragCurrentX > FDragStartX) then begin
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    if SelX2 > SelX1 then begin
      OverBmp := TBitmap.Create();
      try
        OverBmp.PixelFormat := pf24bit;
        OverBmp.Width := SelX2 - SelX1;
        OverBmp.Height := R.Bottom - R.Top;
        OverBmp.Canvas.Brush.Color := clWhite;
        OverBmp.Canvas.FillRect(Rect(0, 0, OverBmp.Width, OverBmp.Height));
        BF.BlendOp := AC_SRC_OVER;
        BF.BlendFlags := 0;
        BF.SourceConstantAlpha := 60;
        BF.AlphaFormat := 0;
        Winapi.Windows.AlphaBlend(C.Handle, SelX1, R.Top, SelX2 - SelX1, R.Bottom - R.Top,
          OverBmp.Canvas.Handle, 0, 0, OverBmp.Width, OverBmp.Height, BF);
      finally
        OverBmp.Free();
      end;
    end;
  end;
end;



procedure TFormMain.DrawAxes(C: TCanvas; const R: TRect);
const
  CLR_AXIS = clWhite;
  CLR_GRID = $00444444;
var
  MaxHz, DurSec: Double;
  StartTime, EndTime, ZoomDur: Double;
  FreqStep, TimeStep: Double;
  Freq, T: Double;
  FirstTick: Double;
  I, X, Y, TextH, TextW: Integer;
  NumTicks: Integer;
  Lbl: string;
begin
  if FWavFile = nil then
    Exit();

  if FMaxPlotHz > 0 then
    MaxHz := FMaxPlotHz
  else
    MaxHz := FWavFile.Info.SampleRate / 2.0;
  DurSec := FWavFile.Info.DurationSec;

  C.Font.Size := 8;
  C.Font.Color := CLR_AXIS;
  C.Brush.Style := bsClear;

  if MaxHz >= 40000 then
    FreqStep := 10000
  else if MaxHz >= 10000 then
    FreqStep := 5000
  else
    FreqStep := 1000;

  NumTicks := Floor(MaxHz / FreqStep);
  TextH := C.TextHeight('0');

  for I := 0 to NumTicks do begin
    Freq := I * FreqStep;
    Y := R.Bottom - Round(Freq / MaxHz * (R.Bottom - R.Top));

    C.Pen.Color := CLR_AXIS;
    C.Pen.Width := 1;
    C.MoveTo(R.Left - 4, Y);
    C.LineTo(R.Left, Y);

    C.Pen.Color := CLR_GRID;
    C.MoveTo(R.Left, Y);
    C.LineTo(R.Right, Y);

    if Freq >= 1000 then
      Lbl := Format('%gk', [Freq / 1000])
    else
      Lbl := Format('%g', [Freq]);
    TextW := C.TextWidth(Lbl);
    C.Font.Color := CLR_AXIS;
    C.TextOut(R.Left - TextW - 6, Y - TextH div 2, Lbl);
  end;

  StartTime := FZoomStart * DurSec;
  EndTime := FZoomEnd * DurSec;
  ZoomDur := EndTime - StartTime;
  if ZoomDur < 1.0E-9 then
    Exit();

  if ZoomDur >= 8.0 then
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
      C.Pen.Color := CLR_AXIS;
      C.MoveTo(X, R.Bottom);
      C.LineTo(X, R.Bottom + 4);

      C.Pen.Color := CLR_GRID;
      C.MoveTo(X, R.Top);
      C.LineTo(X, R.Bottom);

      if ZoomDur < 0.5 then
        Lbl := Format('%.3f s', [T])
      else
        Lbl := Format('%.2g s', [T]);
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
  X: Integer;
begin
  if (FCursorPos <= 0.0) or (FZoomEnd <= FZoomStart) then
    Exit();
  VisFrac := (FCursorPos - FZoomStart) / (FZoomEnd - FZoomStart);
  if (VisFrac < 0.0) or (VisFrac > 1.0) then
    Exit();
  X := R.Left + Round(VisFrac * (R.Right - R.Left));
  C.Pen.Color := clWhite;
  C.Pen.Width := 2;
  C.MoveTo(X, R.Top);
  C.LineTo(X, R.Bottom);
  C.Pen.Width := 1;
end;



procedure TFormMain.PaintBoxPaint(Sender: TObject);
var
  R: TRect;
  W, H: Integer;
  Msg: string;
  SelX1, SelX2: Integer;
  OverBmp: TBitmap;
  BF: TBlendFunction;
begin
  R := SpectRect();
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;

  PaintBox.Canvas.Brush.Color := $00202020;
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  if FSpecgram = nil then begin
    Msg := 'Open an audio file to display the spectrogram';
    PaintBox.Canvas.Font.Color := clGray;
    PaintBox.Canvas.Font.Size := 12;
    PaintBox.Canvas.Brush.Style := bsClear;
    PaintBox.Canvas.TextOut(PaintBox.Width div 2 - PaintBox.Canvas.TextWidth(Msg) div 2, PaintBox.Height div 2 - PaintBox.Canvas.TextHeight(Msg) div 2, Msg);
    Exit();
  end;

  if (FDisplayBmp = nil) or (FDisplayBmp.Width <> W) or (FDisplayBmp.Height <> H) then
    RenderSpectrogram();

  if (FDisplayBmp <> nil) and (FDisplayBmp.Width > 0) then
    BitBlt(PaintBox.Canvas.Handle, R.Left, R.Top, W, H, FDisplayBmp.Canvas.Handle, 0, 0, SRCCOPY);

  DrawAxes(PaintBox.Canvas, R);
  DrawCursor(PaintBox.Canvas, R);

  // Rubber-band selection overlay when dragging right
  if FDragging and (FDragCurrentX > FDragStartX) then begin
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    if SelX2 > SelX1 then begin
      OverBmp := TBitmap.Create();
      try
        OverBmp.PixelFormat := pf24bit;
        OverBmp.Width := SelX2 - SelX1;
        OverBmp.Height := R.Bottom - R.Top;
        OverBmp.Canvas.Brush.Color := clWhite;
        OverBmp.Canvas.FillRect(Rect(0, 0, OverBmp.Width, OverBmp.Height));
        BF.BlendOp := AC_SRC_OVER;
        BF.BlendFlags := 0;
        BF.SourceConstantAlpha := 60;
        BF.AlphaFormat := 0;
        Winapi.Windows.AlphaBlend(PaintBox.Canvas.Handle, SelX1, R.Top, SelX2 - SelX1, R.Bottom - R.Top,
          OverBmp.Canvas.Handle, 0, 0, OverBmp.Width, OverBmp.Height, BF);
      finally
        OverBmp.Free();
      end;
    end;
  end;
end;



end.
