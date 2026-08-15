unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  FFT, WavReader, LibVLC, Spectrogram, WaveOutPlayer;

const
  PLAYBACK_RATE = 0.1;
  LEFT_MARGIN   = 65;
  BOTTOM_MARGIN = 35;
  TOP_MARGIN    = 8;
  RIGHT_MARGIN  = 10;
  SPECTROGRAM_GAMMA = 2.5;  // power-law colour curve > 1 = dark background

type
  TFormMain = class(TForm)
    PanelTop:       TPanel;
    BtnOpen:        TButton;
    BtnPlay:        TButton;
    BtnPause:       TButton;
    BtnStop:        TButton;
    LblWindow:      TLabel;
    CbxWindow:      TComboBox;
    LblFFTSize:     TLabel;
    CbxFFTSize:     TComboBox;
    LblSpeed:       TLabel;
    LblPlayMode:    TLabel;
    CbxPlayMode:    TComboBox;
    LblGainCaption: TLabel;
    TrkGain:        TTrackBar;
    LblGainVal:     TLabel;
    ChkBGSub:       TCheckBox;
    StatusBar:      TStatusBar;
    ZoomBar:        TScrollBar;
    PaintBox:       TPaintBox;
    OpenDialog:     TOpenDialog;
    Timer:          TTimer;
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
    procedure TimerTick(Sender: TObject);
    procedure CbxWindowChange(Sender: TObject);
    procedure CbxFFTSizeChange(Sender: TObject);
    procedure CbxPlayModeChange(Sender: TObject);
    procedure TrkGainChange(Sender: TObject);
    procedure ChkBGSubChange(Sender: TObject);
    procedure ZoomBarChange(Sender: TObject);
  private
    { File / spectrogram }
    FWavFile:     TWavFile;
    FSpecgram:    TSpectrogramData;
    FCurrentFile: string;
    FCursorPos:   Double;   // 0..1 normalised position in the recording

    { VLC player state }
    FVLCInst:      Plibvlc_instance_t;
    FVLCMedia:     Plibvlc_media_t;
    FVLCPlayer:    Plibvlc_media_player_t;
    FRateSetCount: Integer;

    { Native waveOut player }
    FWavePlayer: TWaveOutPlayer;

    { Zoom state (0..1 fractions of the full recording) }
    FZoomStart:    Double;
    FZoomEnd:      Double;
    FDragging:     Boolean;
    FDragStartX:   Integer;
    FDragZoomStart: Double;
    FDragZoomEnd:   Double;
    FDragZoomFrac:  Double;  // recording fraction under cursor at drag-start

    function  UseNativeMode: Boolean;
    function  SpectRect: TRect;
    function  GetFFTSize: Integer;
    function  GetWindowType: TWindowType;
    procedure RecomputeSpectrogram;
    procedure RenderSpectrogram;
    procedure StopAllPlayers;
    procedure ReleaseVLCMedia;
    procedure DrawAxes(C: TCanvas; const R: TRect);
    procedure DrawCursor(C: TCanvas; const R: TRect);
    procedure ResetPlaybackUI;
    procedure UpdateZoomBar;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

{ ---- helpers --------------------------------------------------------------- }

function TFormMain.UseNativeMode: Boolean;
begin
  Result := CbxPlayMode.ItemIndex = 1;
end;

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
  FreeAndNil(FSpecgram);
  if FWavFile = nil then Exit;
  FSpecgram := TSpectrogramData.Create;
  FSpecgram.Compute(FWavFile, GetFFTSize, GetWindowType);
  RenderSpectrogram;
  PaintBox.Invalidate;
end;

procedure TFormMain.RenderSpectrogram;
begin
  if FSpecgram = nil then Exit;
  FSpecgram.ProcessAndRender(ChkBGSub.Checked, TrkGain.Position, SPECTROGRAM_GAMMA);
end;

procedure TFormMain.StopAllPlayers;
begin
  if FVLCPlayer <> nil then
  begin
    if libvlc_media_player_is_playing(FVLCPlayer) <> 0 then
      libvlc_media_player_stop(FVLCPlayer);
    libvlc_media_player_release(FVLCPlayer);
    FVLCPlayer := nil;
  end;
  FWavePlayer.Stop;
end;

procedure TFormMain.ReleaseVLCMedia;
begin
  if FVLCMedia <> nil then
  begin
    libvlc_media_release(FVLCMedia);
    FVLCMedia := nil;
  end;
end;

procedure TFormMain.ResetPlaybackUI;
begin
  BtnPlay.Enabled  := FWavFile <> nil;
  BtnPause.Enabled := False;
  BtnStop.Enabled  := False;
end;

{ ---- form lifecycle -------------------------------------------------------- }

procedure TFormMain.FormCreate(Sender: TObject);
var
  ErrMsg:  string;
  NilArgs: PPAnsiChar;
begin
  FWavFile     := nil;
  FSpecgram    := nil;
  FVLCInst     := nil;
  FVLCMedia    := nil;
  FVLCPlayer   := nil;
  FCursorPos   := 0;
  FWavePlayer  := TWaveOutPlayer.Create;

  FZoomStart := 0.0;
  FZoomEnd   := 1.0;
  FDragging  := False;
  UpdateZoomBar;

  NilArgs := nil;
  if not LoadVLC(ErrMsg) then
    StatusBar.Panels[0].Text := 'VLC not available: ' + ErrMsg
  else
  begin
    FVLCInst := libvlc_new(0, NilArgs);
    if FVLCInst = nil then
      StatusBar.Panels[0].Text := 'VLC instance failed to initialise'
    else
      StatusBar.Panels[0].Text := 'Ready. Open a WAV file.';
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Timer.Enabled := False;
  StopAllPlayers;
  ReleaseVLCMedia;
  if FVLCInst <> nil then
  begin
    libvlc_release(FVLCInst);
    FVLCInst := nil;
  end;
  FWavePlayer.Free;
  FSpecgram.Free;
  FWavFile.Free;
  UnloadVLC;
end;

{ ---- file loading ---------------------------------------------------------- }

procedure TFormMain.BtnOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;

  Timer.Enabled := False;
  StopAllPlayers;
  ReleaseVLCMedia;
  FCursorPos := 0;
  FreeAndNil(FSpecgram);
  FreeAndNil(FWavFile);
  BtnPlay.Enabled  := False;
  BtnPause.Enabled := False;
  BtnStop.Enabled  := False;

  FCurrentFile := OpenDialog.FileName;

  try
    FWavFile := TWavFile.Create;
    FWavFile.LoadFromFile(FCurrentFile);

    StatusBar.Panels[0].Text := Format(
      '%s  |  %.2f s  |  %d Hz  |  %d-bit  |  %d ch',
      [ExtractFileName(FCurrentFile),
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

    { Reset zoom to full view for the new file. }
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
  MediaPath:  UTF8String;
  OutRate:    Cardinal;
  ActualRate: Cardinal;
begin
  if FWavFile = nil then Exit;

  if UseNativeMode then
  begin
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
          StatusBar.Panels[0].Text :=
            Format('Native: requested %d Hz, using %d Hz (%.1f%% speed)',
              [OutRate, ActualRate, ActualRate / FWavFile.Info.SampleRate * 100])
        else
          StatusBar.Panels[0].Text :=
            Format('Native: %d Hz output (%.1f%% speed — correct pitch)',
              [ActualRate, PLAYBACK_RATE * 100]);
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Native audio failed:'#13#10 + E.Message);
        Exit;
      end;
    end;
  end
  else
  begin
    if FVLCInst = nil then
    begin
      ShowMessage('VLC is not available. Switch to Native mode or install VLC.');
      Exit;
    end;
    if FCurrentFile = '' then Exit;

    if FVLCPlayer <> nil then
      libvlc_media_player_play(FVLCPlayer)
    else
    begin
      ReleaseVLCMedia;
      MediaPath  := UTF8String(FCurrentFile);
      FVLCMedia  := libvlc_media_new_path(FVLCInst, PAnsiChar(MediaPath));
      if FVLCMedia = nil then
      begin
        ShowMessage('VLC could not open: ' + FCurrentFile);
        Exit;
      end;
      FVLCPlayer := libvlc_media_player_new_from_media(FVLCMedia);
      if FVLCPlayer = nil then
      begin
        ShowMessage('VLC could not create a media player.');
        Exit;
      end;
      libvlc_media_player_play(FVLCPlayer);
      FCursorPos := 0;
      StatusBar.Panels[0].Text :=
        'VLC mode — audio above ~24 kHz is filtered before pitch shift';
    end;
    FRateSetCount := 0;
  end;

  Timer.Enabled    := True;
  BtnPlay.Enabled  := False;
  BtnPause.Enabled := True;
  BtnStop.Enabled  := True;
end;

procedure TFormMain.BtnPauseClick(Sender: TObject);
begin
  Timer.Enabled := False;
  if UseNativeMode then
    FWavePlayer.Pause
  else
    if FVLCPlayer <> nil then
      libvlc_media_player_pause(FVLCPlayer);
  BtnPlay.Enabled  := True;
  BtnPause.Enabled := False;
end;

procedure TFormMain.BtnStopClick(Sender: TObject);
begin
  Timer.Enabled := False;
  StopAllPlayers;
  ReleaseVLCMedia;
  FCursorPos := 0;
  ResetPlaybackUI;
  PaintBox.Invalidate;
end;

{ ---- playback timer -------------------------------------------------------- }

procedure TFormMain.TimerTick(Sender: TObject);
var
  Pos:        Double;
  Cur, Total: Int64;
  DurSec:     Double;
begin
  if UseNativeMode then
  begin
    if FWavePlayer.HasEnded then
    begin
      Timer.Enabled := False;
      FWavePlayer.Stop;
      FCursorPos := 0;
      ResetPlaybackUI;
      PaintBox.Invalidate;
      Exit;
    end;

    if not (FWavePlayer.IsPlaying or FWavePlayer.IsPaused) then Exit;

    Pos        := FWavePlayer.GetNormalizedPosition;
    FCursorPos := Pos;

    if FWavFile <> nil then
    begin
      DurSec := FWavFile.Info.DurationSec;
      StatusBar.Panels[1].Text := Format('%.3f / %.3f s (file)',
        [Pos * DurSec, DurSec]);
    end;

    PaintBox.Invalidate;
  end
  else
  begin
    if FVLCPlayer = nil then Exit;

    if FRateSetCount < 5 then
    begin
      libvlc_media_player_set_rate(FVLCPlayer, PLAYBACK_RATE);
      Inc(FRateSetCount);
    end;

    Cur   := libvlc_media_player_get_time(FVLCPlayer);
    Total := libvlc_media_player_get_length(FVLCPlayer);

    if Total > 0 then
    begin
      FCursorPos := Cur / Total;
      StatusBar.Panels[1].Text := Format('%.2f / %.2f s (file)',
        [Cur / 1000.0, Total / 1000.0]);
      PaintBox.Invalidate;

      if (libvlc_media_player_is_playing(FVLCPlayer) = 0)
         and (Cur >= Total - 500) then
      begin
        Timer.Enabled := False;
        StopAllPlayers;
        ReleaseVLCMedia;
        FCursorPos := 0;
        ResetPlaybackUI;
        PaintBox.Invalidate;
      end;
    end;
  end;
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

procedure TFormMain.CbxPlayModeChange(Sender: TObject);
begin
  Timer.Enabled := False;
  StopAllPlayers;
  ReleaseVLCMedia;
  FCursorPos := 0;
  ResetPlaybackUI;
  PaintBox.Invalidate;

  if UseNativeMode then
    StatusBar.Panels[0].Text :=
      'Native mode: plays at correct pitch (full frequency range).'
  else
    StatusBar.Panels[0].Text :=
      'VLC mode: audio above ~24 kHz filtered before pitch shift.';
end;

procedure TFormMain.TrkGainChange(Sender: TObject);
var
  G: Integer;
begin
  G := TrkGain.Position;
  if G = 0 then LblGainVal.Caption := '0 dB'
  else LblGainVal.Caption := '+' + IntToStr(G) + ' dB';
  if FSpecgram = nil then Exit;
  RenderSpectrogram;
  PaintBox.Invalidate;
end;

procedure TFormMain.ChkBGSubChange(Sender: TObject);
begin
  if FSpecgram = nil then Exit;
  RenderSpectrogram;
  PaintBox.Invalidate;
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
  PaintBox.Invalidate;
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
  { Recording fraction under cursor. }
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
  R:             TRect;
  Delta:         Integer;
  OldW, NewW:    Double;
  NewStart:      Double;
  DurSec:        Double;
  TimeAtCursor:  Double;
  FreqAtCursor:  Double;
begin
  R := SpectRect;

  if FDragging then
  begin
    Delta := X - FDragStartX;
    if Delta > 400 then Delta := 400;
    if Delta < -400 then Delta := -400;

    OldW := FDragZoomEnd - FDragZoomStart;
    if OldW < 1.0e-9 then OldW := 1.0e-9;

    { Right drag = zoom in (factor < 1), left drag = zoom out. }
    NewW := OldW * Power(0.99, Delta);
    if NewW < 0.001 then NewW := 0.001;
    if NewW > 1.0   then NewW := 1.0;

    { Keep the recording fraction under the drag-start cursor fixed. }
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
    PaintBox.Invalidate;
  end;

  { Coordinate readout (always, even while dragging). }
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

procedure TFormMain.DrawAxes(C: TCanvas; const R: TRect);
const
  CLR_AXIS  = clWhite;
  CLR_GRID  = $00444444;
var
  MaxHz, DurSec:           Double;
  StartTime, EndTime, ZoomDur: Double;
  FreqStep, TimeStep:      Double;
  Freq, T:                 Double;
  FirstTick:               Double;
  I, X, Y, TextH, TextW:  Integer;
  NumTicks:                Integer;
  Lbl:                     string;
begin
  if FWavFile = nil then Exit;

  MaxHz  := FWavFile.Info.SampleRate / 2.0;
  DurSec := FWavFile.Info.DurationSec;

  C.Font.Size   := 8;
  C.Font.Color  := CLR_AXIS;
  C.Brush.Style := bsClear;

  { --- Frequency (Y) axis ------------------------------------------------- }
  if MaxHz >= 40000 then FreqStep := 10000
  else if MaxHz >= 10000 then FreqStep := 5000
  else FreqStep := 1000;

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

    if Freq >= 1000 then
      Lbl := Format('%g k', [Freq / 1000])
    else
      Lbl := Format('%g', [Freq]);
    TextW := C.TextWidth(Lbl);
    C.Font.Color := CLR_AXIS;
    C.TextOut(R.Left - TextW - 6, Y - TextH div 2, Lbl);
  end;
  C.TextOut(2, R.Top, 'Hz');

  { --- Time (X) axis ------------------------------------------------------- }
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

  { First tick at or just after StartTime, snapped to TimeStep grid. }
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
  R:        TRect;
  Msg:      string;
  SrcLeft, SrcWidth: Integer;
begin
  R := SpectRect;

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

  { Render the zoomed portion of the spectrogram bitmap via StretchBlt. }
  SrcLeft  := Round(FZoomStart * FSpecgram.NumFrames);
  SrcWidth := Max(1, Round((FZoomEnd - FZoomStart) * FSpecgram.NumFrames));

  StretchBlt(
    PaintBox.Canvas.Handle,
    R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top,
    FSpecgram.Bitmap.Canvas.Handle,
    SrcLeft, 0, SrcWidth, FSpecgram.NumBins,
    SRCCOPY);

  DrawAxes(PaintBox.Canvas, R);
  DrawCursor(PaintBox.Canvas, R);
end;

end.
