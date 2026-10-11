{ Bat vizualizer
  Copyright (C) 2026

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>. }



unit MainForm;



interface



uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.Types, System.Math, System.IOUtils, System.DateUtils, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Themes,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ImgList,
  FFT, WavReader, Spectrogram, WaveOutPlayer, Heterodyne, Mp3Writer, WavWriter,
  WaveformPainter, SpectrogramPainter, PngExport, BatSpeciesTranslations, System.ImageList,
  BatIdentForm, BusyForm, NightlyActivityForm, ClipExportForm, settings;

const
  LEFT_MARGIN = 65;
  BOTTOM_MARGIN = 35;
  TOP_MARGIN = 8;
  RIGHT_MARGIN = 10;
  SPECTROGRAM_GAMMA = 2.5;
  WAVE_VPAD = 12;
  PANEL_FILES_BOTTOM_HEIGHT_WITH_CSV = 126;
  PANEL_FILES_BOTTOM_HEIGHT_NO_CSV = 94;

type
  TFormMain = class(TForm)
    PanelLeft: TPanel;
    GroupSource: TGroupBox;
    BtnOpenFile: TButton;
    BtnOpenFolder: TButton;
    BtnIdentify: TButton;
    GroupPlayback: TGroupBox;
    BtnPlay: TButton;
    BtnPause: TButton;
    BtnStop: TButton;
    GroupFFT: TGroupBox;
    LblWindow: TLabel;
    CbxWindow: TComboBox;
    LblFFTSize: TLabel;
    CbxFFTSize: TComboBox;
    LblGainCaption: TLabel;
    LblGainVal: TLabel;
    TrkGain: TTrackBar;
    BtnAutoGain: TButton;
    GroupFiltering: TGroupBox;
    ChkBGSub: TCheckBox;
    ChkFilter: TCheckBox;
    GroupSpectrogram: TGroupBox;
    LblColorScheme: TLabel;
    CbxColorScheme: TComboBox;
    LblFloor: TLabel;
    TrkFloor: TTrackBar;
    LblCeiling: TLabel;
    TrkCeiling: TTrackBar;
    LblMaxFreq: TLabel;
    TrkMaxFreq: TTrackBar;
    BtnAutoFloor: TButton;
    BtnAutoCeiling: TButton;
    BtnAutoMaxFreq: TButton;
    StatusBar: TStatusBar;
    ZoomBar: TScrollBar;
    PanelMain: TPanel;
    WaveformBox: TPaintBox;
    Splitter1: TSplitter;
    PaintBox: TPaintBox;
    DetectionMarkersBox: TPaintBox;
    PanelTransport: TPanel;
    BtnPrevResult: TButton;
    BtnNextResult: TButton;
    BtnZoomIn: TButton;
    BtnZoomOut: TButton;
    BtnZoomFull: TButton;
    ChkMeasure: TCheckBox;
    OpenDialog: TOpenDialog;
    Timer: TTimer;
    RenderTimer: TTimer;
    LivePlaybackTimer: TTimer;
    RbTimeExpansion: TRadioButton;
    CbxSpeed: TComboBox;
    RbHeterodyne: TRadioButton;
    TrkTuneFreq: TTrackBar;
    BtnExport: TButton;
    PanelRight: TPanel;
    PanelFileContent: TPanel;
    PanelFileHeader: TPanel;
    BtnCloseRightPanel: TButton;
    FileListView: TListView;
    PanelFilesBottom: TPanel;
    SplitterRight: TSplitter;
    ImageListButtons: TImageList;
    CbxLanguage: TComboBox;
    BtnPrevFile: TButton;
    BtnNextFile: TButton;
    GroupBox1: TGroupBox;
    ImageListClose: TImageList;
    BtnNightlyActivity: TButton;
    BtnExportClips: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOpenFileClick(Sender: TObject);
    procedure BtnOpenFolderClick(Sender: TObject);
    procedure BtnPrevFileClick(Sender: TObject);
    procedure BtnNextFileClick(Sender: TObject);
    procedure BtnIdentifyClick(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnPrevResultClick(Sender: TObject);
    procedure BtnNextResultClick(Sender: TObject);
    procedure BtnZoomInClick(Sender: TObject);
    procedure BtnZoomOutClick(Sender: TObject);
    procedure BtnZoomFullClick(Sender: TObject);
    procedure ChkMeasureClick(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxPaint(Sender: TObject);
    procedure DetectionMarkersBoxPaint(Sender: TObject);
    procedure DetectionMarkersBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DetectionMarkersBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure WaveformBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AppMouseWheel(var Msg: TMsg; var Handled: Boolean);
    procedure TimerTick(Sender: TObject);
    procedure CbxWindowChange(Sender: TObject);
    procedure CbxFFTSizeChange(Sender: TObject);
    procedure CbxSpeedChange(Sender: TObject);
    procedure PlaybackModeClick(Sender: TObject);
    procedure TrkTuneFreqChange(Sender: TObject);
    procedure TrkGainChange(Sender: TObject);
    procedure BtnAutoGainClick(Sender: TObject);
    procedure LivePlaybackTimerTick(Sender: TObject);
    procedure ChkBGSubChange(Sender: TObject);
    procedure ChkFilterChange(Sender: TObject);
    procedure CbxColorSchemeChange(Sender: TObject);
    procedure TrkFloorChange(Sender: TObject);
    procedure TrkCeilingChange(Sender: TObject);
    procedure TrkMaxFreqChange(Sender: TObject);
    procedure BtnAutoFloorClick(Sender: TObject);
    procedure BtnAutoCeilingClick(Sender: TObject);
    procedure BtnAutoMaxFreqClick(Sender: TObject);
    procedure RenderTimerTick(Sender: TObject);
    procedure ZoomBarChange(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnExportClipsClick(Sender: TObject);
    procedure FileListViewClick(Sender: TObject);
    procedure FileListViewDblClick(Sender: TObject);
    procedure FileListViewResize(Sender: TObject);
    procedure FileListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure CbxLanguageChange(Sender: TObject);
    procedure BtnCloseRightPanelClick(Sender: TObject);
    procedure BtnNightlyActivityClick(Sender: TObject);
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

    FMeasureMode: Boolean;
    FMeasuring: Boolean;
    FHasMeasurement: Boolean;
    FMeasureStartSec: Double;
    FMeasureStartHz: Double;
    FMeasureEndSec: Double;
    FMeasureEndHz: Double;

    FBusyDepth: Integer;
    FBusyStartTick: Cardinal;
    FBusyShown: Boolean;
    FBusyForm: TFormBusy;

    Settings: TSettings;
    FLastOpenFolder: string;
    FLastSectionsFolder: string;
    FExportTypeIdx: Integer;
    FClipFilter: TClipFilter;

    { AllowDropFiles/OnDropFiles aren't published on TCustomForm -- streaming
      them from the dfm raised EReadError, and referencing AllowDropFiles in
      code doesn't even compile (it isn't a real property/method at all, VCL
      has no built-in drop-target support). DragAcceptFiles() below is the
      actual Win32 API for this; WMDropFiles handles the message it causes. }
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
    procedure HandleDroppedFiles(const FileNames: TArray<string>);

    function SpectRect: TRect;
    function WaveRect: TRect;
    function SpectXToSec(X: Integer; const R: TRect): Double;
    function SpectYToHz(Y: Integer; const R: TRect): Double;
    function SecToSpectX(Sec: Double; const R: TRect): Integer;
    function HzToSpectY(Hz: Double; const R: TRect): Integer;
    procedure ClearMeasurement;
    procedure ApplyZoomDrag(const ChartR: TRect);
    procedure ZoomAroundCenter(Factor: Double);
    function GetFFTSize: Integer;
    function GetWindowType: TWindowType;
    function GetPlaybackRate: Double;
    function GetPlaybackGain: Double;
    function GetTuneFreqHz: Double;
    procedure BuildPlaybackBuffer(AStartSample, AEndSample: Integer; out Buffer: TArray<Single>; out TimelineStart: Integer;
      out TimeScale: Double; out OutRate: Cardinal);
    procedure UpdatePlaybackStatus(OutRate, ActualRate: Cardinal; TimeScale: Double);
    procedure ApplyPlaybackSettingsLive;
    procedure UpdateGainRange;
    procedure RecomputeSpectrogram;
    procedure ApplyAutoFloorCeiling;
    procedure RenderSpectrogram;
    procedure ScheduleRender;
    procedure ResetPlaybackUI;
    procedure UpdateZoomBar;
    procedure UpdateTransportButtons;
    procedure EnsureBusyForm;
    procedure BeginBusy(const AMessage: string);
    procedure TickBusy;
    procedure EndBusy;

  type
    TRowKind = (rkSpecies, rkDetection, rkFile);



    TRowData = record
      Kind: TRowKind;
      SpeciesIdx: Integer;
      FileIdx: Integer;
      DetIdx: Integer;
    end;



    PRowData = ^TRowData;



    TBatDetection = record
      ScientificName: string;
      CommonName: string;
      Confidence: Double;
      StartSec: Double;
      EndSec: Double;
      DateTime: TDateTime;
    end;



    TBatFileEntry = record
      FilePath: string;
      FileName: string;
      HasCsv: Boolean;
      Detections: TArray<TBatDetection>;
      RecordedAt: TDateTime;
    end;



    TFlatDet = record
      CommonName: string;
      FileIdx: Integer;
      DetIdx: Integer;
    end;



    TDetRef = record
      FileIdx: Integer;
      DetIdx: Integer;
    end;



    TSpeciesEntry = record
      CommonName: string;
      Expanded: Boolean;
      Refs: TArray<TDetRef>;
    end;



    TResultSortColumn = (rscTimestamp, rscConfidence);

  var
    FCurrentFilePath: string;
    FFileEntries: TArray<TBatFileEntry>;
    FSpeciesEntries: TArray<TSpeciesEntry>;
    FSortColumn: TResultSortColumn;
    FSortAscending: Boolean;
    FDisplayLanguage: TDisplayLanguage;
    procedure LoadFile(const AFilePath: string);
    function ParseBatResults(const ACsvPath: string): TArray<TBatDetection>;
    function MergeConsecutiveDetections(const ADetections: TArray<TBatDetection>): TArray<TBatDetection>;
    function TopMeanConfidence(const ADetections: TArray<TBatDetection>; ALow, AHigh: Integer): Double;
    procedure ScanFolderForFiles(const AFolder: string);
    procedure ScanAndShowFolder(const AFolder: string);
    function TryParseFileNameDateTime(const ABaseName: string; out ADateTime: TDateTime): Boolean;
    function FindFileNameStamp(const ABaseName: string; out ADateTime: TDateTime; out AStampPos, AStampLen: Integer): Boolean;
    function GetFileFallbackDateTime(const AFilePath: string): TDateTime;
    procedure BuildSpeciesEntries;
    procedure BuildResultsList;
    procedure ClearFileListRowData;
    procedure ApplyResultsColumnWidths;
    procedure FitResultsColumns;
    function GetCurrentFileIndex: Integer;
    function GetCurrentFileDetections: TArray<TBatDetection>;
    procedure JumpToDetection(const Det: TBatDetection);
    function GetMarkerRect(const Det: TBatDetection; DurationSec: Double; ALeft, ARight: Integer): TRect;
    function GetCurrentFileRecordedAt: TDateTime;
    function GetCurrentClipSpeciesName: string;
    function BuildDefaultExportFileName(AIncludePlaybackSuffix: Boolean): string;
    function CanCopyOriginalForExport(const ATargetExt: string): Boolean;
    function SanitizeSpeciesForFileName(const ASpecies: string): string;
    function BuildSectionFileName(const AEntry: TBatFileEntry; const Det: TBatDetection; AClipStartSec: Double): string;
    function SelectClips(const AFilter: TClipFilter): TArray<TFlatDet>;
    procedure ExportImage(const AFileName: string; ATarget: Integer);
    procedure ExportAudio(const AFileName, AExt: string);
    procedure WriteClipResultsCsv(const AFileName: string; const Det: TBatDetection; AClipStartSec, AClipEndSec: Double);
    procedure ExportDetectionSection(AWav: TWavFile; const AEntry: TBatFileEntry; const Det: TBatDetection;
      const AOutputFolder: string; AMarginSec: Double; AWriteCsv: Boolean; AUsedNames: TStrings;
      var ASavedCount, ASkippedCount: Integer; AErrorLog: TStrings);
    procedure ExportClips(const ASelected: TArray<TFlatDet>; AMarginSec: Double; AWriteCsv: Boolean;
      const AOutputFolder: string; var ASavedCount, ASkippedCount: Integer; var ACancelled: Boolean; AErrorLog: TStrings);
    procedure ReportClipExportResult(const AOutputFolder: string; ASavedCount, ASkippedCount, ATotal: Integer;
      ACancelled: Boolean; AErrorLog: TStrings);
  end;

var
  FormMain: TFormMain;



implementation



{$R *.dfm}

uses System.Generics.Collections, System.Generics.Defaults;



function IdxToColorScheme(Idx: Integer): TColorScheme; inline;
begin
  case Idx of
    1:
      Result := csPlasma;
    2:
      Result := csInferno;
    3:
      Result := csMagma;
    4:
      Result := csCividis;
    5:
      Result := csMako;
    6:
      Result := csRocket;
    7:
      Result := csGrayscale;
    8:
      Result := csGrayscaleInv;
    9:
      Result := csTurbo;
    10:
      Result := csHot;
    11:
      Result := csSpectral;
  else
    Result := csViridis;
  end;
end;



function BlendColors(C1, C2: TColor; T: Double): TColor;
var
  RGB1, RGB2: Longint;
begin
  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);
  Result := RGB(Round(GetRValue(RGB1) * (1.0 - T) + GetRValue(RGB2) * T), Round(GetGValue(RGB1) * (1.0 - T) + GetGValue(RGB2) * T),
    Round(GetBValue(RGB1) * (1.0 - T) + GetBValue(RGB2) * T));
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



function TFormMain.SpectXToSec(X: Integer; const R: TRect): Double;
begin
  if FWavFile = nil then begin
    Result := 0.0;
    Exit();
  end;
  Result := (FZoomStart + (X - R.Left) / Max(1, R.Right - R.Left) * (FZoomEnd - FZoomStart)) * FWavFile.Info.DurationSec;
end;



function TFormMain.SpectYToHz(Y: Integer; const R: TRect): Double;
begin
  Result := (1.0 - (Y - R.Top) / Max(1, R.Bottom - R.Top)) * FMaxPlotHz;
end;



function TFormMain.SecToSpectX(Sec: Double; const R: TRect): Integer;
begin
  if (FWavFile = nil) or (FWavFile.Info.DurationSec <= 0.0) or (FZoomEnd <= FZoomStart) then begin
    Result := R.Left;
    Exit();
  end;
  Result := R.Left + Round((Sec / FWavFile.Info.DurationSec - FZoomStart) / (FZoomEnd - FZoomStart) * (R.Right - R.Left));
end;



function TFormMain.HzToSpectY(Hz: Double; const R: TRect): Integer;
begin
  if FMaxPlotHz <= 0.0 then begin
    Result := R.Bottom;
    Exit();
  end;
  Result := R.Top + Round((1.0 - Hz / FMaxPlotHz) * (R.Bottom - R.Top));
end;



procedure TFormMain.ClearMeasurement;
begin
  FMeasuring := False;
  FHasMeasurement := False;
end;



function TFormMain.GetFFTSize: Integer;
begin
  case CbxFFTSize.ItemIndex of
    0:
      Result := 64;
    1:
      Result := 128;
    2:
      Result := 256;
    3:
      Result := 512;
    4:
      Result := 1024;
    5:
      Result := 2048;
    6:
      Result := 4096;
    7:
      Result := 8192;
    8:
      Result := 16384;
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
    0:
      Result := 0.05;
    1:
      Result := 0.10;
    2:
      Result := 0.125;
    3:
      Result := 0.20;
    4:
      Result := 0.25;
    5:
      Result := 0.50;
    6:
      Result := 1.00;
  else
    Result := 0.10;
  end;
end;



function TFormMain.GetPlaybackGain: Double;
begin
  Result := Power(10.0, TrkGain.Position / 20.0);
end;



function TFormMain.GetTuneFreqHz: Double;
begin
  Result := TrkTuneFreq.Position * 1000.0;
end;



procedure TFormMain.BuildPlaybackBuffer(AStartSample, AEndSample: Integer; out Buffer: TArray<Single>; out TimelineStart: Integer;
  out TimeScale: Double; out OutRate: Cardinal);
var
  DecimationFactor: Integer;
begin
  TimelineStart := AStartSample;
  if RbHeterodyne.Checked then begin
    MixHeterodyne(FWavFile.Samples, AStartSample, AEndSample, FWavFile.Info.SampleRate, GetTuneFreqHz(), Buffer, DecimationFactor,
      OutRate);
    TimeScale := DecimationFactor;
  end else begin
    Buffer := Copy(FWavFile.Samples, AStartSample, AEndSample - AStartSample);
    TimeScale := 1.0;
    OutRate := Round(FWavFile.Info.SampleRate * GetPlaybackRate());
  end;
end;



procedure TFormMain.UpdatePlaybackStatus(OutRate, ActualRate: Cardinal; TimeScale: Double);
var
  SpeedPct: Double;
begin
  SpeedPct := ActualRate * TimeScale / FWavFile.Info.SampleRate * 100.0;
  if ActualRate <> OutRate then
    StatusBar.Panels[0].Text := Format('Requested %d Hz, using %d Hz (%.1f%% speed)', [OutRate, ActualRate, SpeedPct])
  else
    StatusBar.Panels[0].Text := Format('%d Hz  |  %.1f%% speed', [ActualRate, SpeedPct]);
end;



procedure TFormMain.UpdateGainRange;
const
  FALLBACK_MAX_GAIN_DB = 96;
  MIN_MAX_GAIN_DB = 10;
var
  I, StartSample, EndSample: Integer;
  PeakAbs: Double;
  MaxGainDB: Double;
begin
  if FWavFile = nil then
    Exit();
  { Scoped to the visible (zoomed) section, not the whole file, so the
    slider's ceiling reflects what's actually on screen right now. }
  StartSample := EnsureRange(Round(FZoomStart * FWavFile.Info.NumSamples), 0, FWavFile.Info.NumSamples);
  EndSample := EnsureRange(Round(FZoomEnd * FWavFile.Info.NumSamples), StartSample, FWavFile.Info.NumSamples);
  PeakAbs := 0.0;
  for I := StartSample to EndSample - 1 do
    PeakAbs := Max(PeakAbs, Abs(FWavFile.Samples[I]));
  if PeakAbs > 0.0 then
    MaxGainDB := 20.0 * Log10(1.0 / PeakAbs)
  else
    MaxGainDB := FALLBACK_MAX_GAIN_DB;
  { Never below MIN_MAX_GAIN_DB, even if that means clipping becomes
    possible: an already-loud section shouldn't leave the user with no
    boost headroom at all. }
  TrkGain.Max := Max(MIN_MAX_GAIN_DB, Round(MaxGainDB));
  if TrkGain.Position > TrkGain.Max then
    TrkGain.Position := TrkGain.Max;
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



{ ---- busy indicator --------------------------------------------------------
  Long operations (opening a file, recomputing the spectrogram after an FFT
  size/window change) run synchronously on the main thread, so the only way
  to show a "please wait" popup partway through is for those operations to
  call TickBusy() periodically from their own loops -- it pumps the message
  queue so the popup can appear/repaint, but only once 0.5s have elapsed, so
  a fast operation never shows it at all. BeginBusy/EndBusy nest (via
  FBusyDepth) so a call that itself triggers another busy operation -- e.g.
  LoadFile calling RecomputeSpectrogram -- keeps a single popup and a single
  clock running across both, instead of restarting the 0.5s countdown. }



procedure TFormMain.EnsureBusyForm;
begin
  if FBusyForm <> nil then
    Exit();
  FBusyForm := TFormBusy.Create(Self);
end;



procedure TFormMain.BeginBusy(const AMessage: string);
begin
  Inc(FBusyDepth);
  if FBusyDepth > 1 then
    Exit();
  FBusyStartTick := GetTickCount();
  FBusyShown := False;
  EnsureBusyForm();
  FBusyForm.SetMarquee();
  FBusyForm.ShowCancel(False);
  FBusyForm.LblMessage.Caption := AMessage;
end;



procedure TFormMain.TickBusy;
begin
  if FBusyDepth <= 0 then
    Exit();
  if not FBusyShown then begin
    if GetTickCount() - FBusyStartTick < 500 then
      Exit();
    FBusyShown := True;
    FBusyForm.Show();
  end;
  Application.ProcessMessages();
end;



procedure TFormMain.EndBusy;
begin
  if FBusyDepth <= 0 then
    Exit();
  Dec(FBusyDepth);
  if FBusyDepth > 0 then
    Exit();
  if FBusyShown then
    FBusyForm.Hide();
  FBusyShown := False;
end;



procedure TFormMain.RecomputeSpectrogram;
begin
  RenderTimer.Enabled := False;
  FreeAndNil(FSpecgram);
  if FWavFile = nil then
    Exit();
  BeginBusy('Analyzing spectrogram...');
  try
    FSpecgram := TSpectrogramData.Create();
    FSpecgram.Prepare(FWavFile, GetFFTSize(), GetWindowType(), TickBusy);
  finally
    EndBusy();
  end;
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
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
  FSpecgram.Render(FDisplayBmp, W, H, FZoomStart, FZoomEnd, ChkBGSub.Checked, SPECTROGRAM_GAMMA, TrkFloor.Position, TrkCeiling.Position,
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
  DetectionMarkersBox.Invalidate();
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



procedure TFormMain.UpdateTransportButtons;
var
  HasFile, HasPrevResult, HasNextResult, FullyZoomedOut: Boolean;
  Idx, I: Integer;
  Detections: TArray<TBatDetection>;
  RefTime: Double;
begin
  HasFile := FWavFile <> nil;
  Idx := GetCurrentFileIndex();
  BtnPrevFile.Enabled := HasFile and (Idx > 0);
  BtnNextFile.Enabled := HasFile and (Idx >= 0) and (Idx < High(FFileEntries));

  HasPrevResult := False;
  HasNextResult := False;
  if HasFile then begin
    Detections := GetCurrentFileDetections();
    RefTime := (FZoomStart + FZoomEnd) / 2.0 * FWavFile.Info.DurationSec;
    for I := 0 to High(Detections) do begin
      if Detections[I].StartSec < RefTime - 0.01 then
        HasPrevResult := True;
      if Detections[I].StartSec > RefTime + 0.01 then
        HasNextResult := True;
    end;
  end;
  BtnPrevResult.Enabled := HasFile and HasPrevResult;
  BtnNextResult.Enabled := HasFile and HasNextResult;

  FullyZoomedOut := HasFile and SameValue(FZoomStart, 0.0) and SameValue(FZoomEnd, 1.0);
  BtnZoomIn.Enabled := HasFile;
  BtnZoomOut.Enabled := HasFile and not FullyZoomedOut;
  BtnZoomFull.Enabled := HasFile and not FullyZoomedOut;

  ChkMeasure.Enabled := HasFile;
  if not HasFile and ChkMeasure.Checked then begin
    ChkMeasure.Checked := False;
    FMeasureMode := False;
    ClearMeasurement();
  end;
end;

{ ---- form lifecycle -------------------------------------------------------- }



procedure TFormMain.FormCreate(Sender: TObject);
begin
  FWavFile := nil;
  FSpecgram := nil;
  FDisplayBmp := nil;
  FCursorPos := -1;
  FWavePlayer := TWaveOutPlayer.Create();
  FZoomStart := 0.0;
  FZoomEnd := 1.0;
  FDragging := False;
  FCurrentFilePath := '';
  FSortColumn := rscConfidence;
  FSortAscending := False;
  FDisplayLanguage := dlDutch;
  PanelRight.Visible := False;
  SplitterRight.Visible := False;
  DragAcceptFiles(Handle, True);
  { Created here rather than via the dfm: a dfm-declared TPaintBox at this
    spot has twice raised "EReadError: Invalid property value" for a reason
    I haven't been able to pin down without a compiler; a plain method-pointer
    assignment for OnPaint sidesteps dfm streaming entirely. Among alTop
    siblings, VCL docks in order of each control's Top at the time Align is
    set, so Top must be pushed below Splitter1 first -- left at the default 0
    it ties with WaveformBox and ends up docked before Splitter1 instead of
    after it. }
  // DetectionMarkersBox := TPaintBox.Create(Self);
  // DetectionMarkersBox.Parent := PanelMain;
  // DetectionMarkersBox.Top := Splitter1.Top + Splitter1.Height;
  // DetectionMarkersBox.Height := 4;
  // DetectionMarkersBox.Align := alTop;
  // DetectionMarkersBox.OnPaint := DetectionMarkersBoxPaint;
  PanelMain.ControlStyle := PanelMain.ControlStyle + [csOpaque];
  UpdateZoomBar();
  ResetPlaybackUI();
  UpdateTransportButtons();
  Application.OnMessage := AppMouseWheel;
  StatusBar.Panels[0].Text := 'Ready. Open an audio file.';

  Settings := TSettings.Create(Self);
  Settings.RaiseExceptions := False;
  Settings.StoredProps.Add('CbxLanguage.ItemIndex');
  Settings.StoredProps.Add('CbxColorScheme.ItemIndex');
  Settings.StoredProps.Add('CbxWindow.ItemIndex');
  Settings.StoredProps.Add('CbxFFTSize.ItemIndex');
  Settings.StoredProps.Add('ChkBGSub.Checked');
  Settings.StoredProps.Add('ChkFilter.Checked');
  Settings.StoredProps.Add('CbxSpeed.ItemIndex');
  Settings.StoredProps.Add('RbHeterodyne.Checked');
  Settings.StoredProps.Add('WaveformBox.Height');
  Settings.StoredProps.Add('PanelRight.Width');
  Settings.StoredProps.Add('OpenDialog.InitialDir');
  Settings.LoadSettings();
  Settings.ReadFormPositions(Self);
  FDisplayLanguage := TDisplayLanguage(CbxLanguage.ItemIndex);
  CbxSpeed.Enabled := RbTimeExpansion.Checked;
  TrkTuneFreq.Enabled := RbHeterodyne.Checked;
  FSortColumn := TResultSortColumn(EnsureRange(Settings.ReadInteger('SortColumn', Ord(FSortColumn)), 0, Ord(High(TResultSortColumn))));
  FSortAscending := Settings.ReadBoolean('SortAscending', FSortAscending);
  FLastOpenFolder := Settings.ReadString('LastOpenFolder', '');
  FLastSectionsFolder := Settings.ReadString('LastSectionsFolder', '');
  FExportTypeIdx := Settings.ReadInteger('ExportType', 1);
  FClipFilter := DefaultClipFilter();
  FClipFilter.UseBestN := Settings.ReadBoolean('ClipUseBestN', FClipFilter.UseBestN);
  FClipFilter.BestN := Settings.ReadInteger('ClipBestN', FClipFilter.BestN);
  FClipFilter.UseMinConfidence := Settings.ReadBoolean('ClipUseMinConfidence', FClipFilter.UseMinConfidence);
  FClipFilter.MinConfidence := Settings.ReadFloat('ClipMinConfidence', FClipFilter.MinConfidence);
  FClipFilter.MarginSec := Settings.ReadFloat('ClipMarginSec', FClipFilter.MarginSec);
  FClipFilter.WriteCsv := Settings.ReadBoolean('ClipWriteCsv', FClipFilter.WriteCsv);

  FitResultsColumns();
end;



procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  { A busy operation pumps messages via Application.ProcessMessages() so its
    "please wait" popup can show/repaint; refuse to close the form mid-load
    so that pump can never let FormDestroy tear down FWavFile/FSpecgram out
    from under the load still in progress. }
  CanClose := FBusyDepth <= 0;
end;



procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Settings.WriteInteger('SortColumn', Ord(FSortColumn));
  Settings.WriteBoolean('SortAscending', FSortAscending);
  Settings.WriteString('LastOpenFolder', FLastOpenFolder);
  Settings.WriteString('LastSectionsFolder', FLastSectionsFolder);
  Settings.WriteInteger('ExportType', FExportTypeIdx);
  Settings.WriteBoolean('ClipUseBestN', FClipFilter.UseBestN);
  Settings.WriteInteger('ClipBestN', FClipFilter.BestN);
  Settings.WriteBoolean('ClipUseMinConfidence', FClipFilter.UseMinConfidence);
  Settings.WriteFloat('ClipMinConfidence', FClipFilter.MinConfidence);
  Settings.WriteFloat('ClipMarginSec', FClipFilter.MarginSec);
  Settings.WriteBoolean('ClipWriteCsv', FClipFilter.WriteCsv);
  Settings.WriteFormPositions(Self);
  Settings.SaveSettings();

  Application.OnMessage := nil;
  Timer.Enabled := False;
  FWavePlayer.Stop();
  FWavePlayer.Free();
  FDisplayBmp.Free();
  FSpecgram.Free();
  FWavFile.Free();
  ClearFileListRowData();
end;

{ ---- file loading ---------------------------------------------------------- }



procedure TFormMain.LoadFile(const AFilePath: string);
var
  Detections: TArray<TBatDetection>;
  I: Integer;
begin
  Timer.Enabled := False;
  FWavePlayer.Stop();
  FCursorPos := -1;
  ClearMeasurement();
  FreeAndNil(FSpecgram);
  FreeAndNil(FWavFile);
  BtnPlay.Enabled := False;
  BtnPause.Enabled := False;
  BtnStop.Enabled := False;
  FCurrentFilePath := '';
  Screen.Cursor := crHourGlass;
  Enabled := False;
  BeginBusy('Loading ' + ExtractFileName(AFilePath) + '...');
  try
    try
      FWavFile := TWavFile.Create();
      FWavFile.LoadFromFile(AFilePath, TickBusy);
      FCurrentFilePath := AFilePath;
      FFileInfo := Format('%s  |  %.2f s  |  %d Hz  |  %d-bit  |  %d ch', [ExtractFileName(AFilePath), FWavFile.Info.DurationSec, FWavFile.Info.SampleRate,
        FWavFile.Info.BitsPerSample, FWavFile.Info.Channels]);
      StatusBar.Panels[0].Text := FFileInfo;
      { Everything RenderSpectrogram() reads -- zoom window and max plot
        frequency -- must be set for the NEW file before RecomputeSpectrogram
        renders, not after: PaintBoxPaint only re-renders when FDisplayBmp's
        size changes, so a render done here with the previous file's leftover
        zoom/frequency stays cached and on-screen until something else (a
        manual zoom or frequency change) happens to force a fresh one. }
      FZoomStart := 0.0;
      FZoomEnd := 1.0;
      UpdateZoomBar();
      TrkMaxFreq.Max := FWavFile.Info.SampleRate div 2000;
      TrkMaxFreq.Min := 1;
      TrkMaxFreq.Position := TrkMaxFreq.Max;
      FMaxPlotHz := TrkMaxFreq.Position * 1000.0;
      LblMaxFreq.Caption := Format('Max: %d kHz', [TrkMaxFreq.Position]);
      TrkTuneFreq.Max := FWavFile.Info.SampleRate div 2000;
      TrkTuneFreq.Min := 1;
      TrkTuneFreq.Position := EnsureRange(45, TrkTuneFreq.Min, TrkTuneFreq.Max);
      RbHeterodyne.Caption := Format('Heterodyne (%d kHz)', [TrkTuneFreq.Position]);
      RecomputeSpectrogram();
      ApplyAutoFloorCeiling();
      UpdateGainRange();
      BtnPlay.Enabled := True;
      BtnExport.Enabled := True;
      BtnAutoFloor.Enabled := True;
      BtnAutoCeiling.Enabled := True;
      BtnAutoMaxFreq.Enabled := True;
      BtnAutoGain.Enabled := True;
      Detections := GetCurrentFileDetections();
    except
      on E: Exception do begin
        FreeAndNil(FWavFile);
        FreeAndNil(FSpecgram);
        FCurrentFilePath := '';
        MessageDlg('Error loading file:'#13#10 + E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    { Re-enable the form before hiding the busy popup, not after: while the
      form is still disabled Windows has nothing it can reactivate once the
      popup (its owner's only visible window at that moment) disappears, so
      the whole app can end up with no active window -- i.e. "hidden". }
    Enabled := True;
    Screen.Cursor := crDefault;
    EndBusy();
  end;
  UpdateTransportButtons();
end;



procedure TFormMain.BtnOpenFileClick(Sender: TObject);
begin
  if not OpenDialog.Execute() then
    Exit();
  OpenDialog.InitialDir := ExtractFileDir(OpenDialog.FileName);
  LoadFile(OpenDialog.FileName);
  PanelRight.Visible := False;
  SplitterRight.Visible := False;
end;

{ ---- file browser panel ---------------------------------------------------- }



procedure TFormMain.ClearFileListRowData;
var
  I: Integer;
begin
  for I := 0 to FileListView.Items.Count - 1 do
    if FileListView.Items[I].Data <> nil then
      Dispose(PRowData(FileListView.Items[I].Data));
  FileListView.Items.Clear;
end;



procedure TFormMain.ApplyResultsColumnWidths;
const
  CONFIDENCE_COL_WIDTH = 80;
  MIN_TIMESTAMP_COL_WIDTH = 60;
begin
  FileListView.Columns[1].Width := CONFIDENCE_COL_WIDTH;
  FileListView.Columns[0].Width := Max(MIN_TIMESTAMP_COL_WIDTH, FileListView.ClientWidth - CONFIDENCE_COL_WIDTH);
  { The common control sometimes shows a horizontal scrollbar for a tick after
    items are added even though the columns fit, and only clears it on the next
    scroll notification. Force it hidden rather than wait for that. }
  ShowScrollBar(FileListView.Handle, SB_HORZ, False);
end;



procedure TFormMain.FitResultsColumns;
begin
  ApplyResultsColumnWidths();
  { The vertical scrollbar's presence isn't reflected in ClientWidth until
    Windows finishes its own layout pass, so a column fit computed right after
    adding/removing items can be stale (causing a spurious horizontal
    scrollbar). Re-apply once more on the next message-loop iteration. }
  TThread.ForceQueue(nil,
    procedure
    begin
      if not(csDestroying in ComponentState) then
        ApplyResultsColumnWidths();
    end);
end;



procedure TFormMain.FileListViewResize(Sender: TObject);
begin
  FitResultsColumns();
end;



procedure TFormMain.FileListViewColumnClick(Sender: TObject; Column: TListColumn);
var
  NewSortColumn: TResultSortColumn;
begin
  NewSortColumn := TResultSortColumn(Column.Index);
  if NewSortColumn = FSortColumn then
    FSortAscending := not FSortAscending
  else begin
    FSortColumn := NewSortColumn;
    FSortAscending := FSortColumn = rscTimestamp;
  end;
  BuildSpeciesEntries;
  BuildResultsList;
end;



function TFormMain.ParseBatResults(const ACsvPath: string): TArray<TBatDetection>;
var
  Lines: TStringList;
  I, K: Integer;
  Parts: TArray<string>;
  Det: TBatDetection;
  FS: TFormatSettings;
  Name: string;
begin
  Result := [];
  FS := TFormatSettings.Invariant;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ACsvPath);
    for I := 1 to Lines.Count - 1 do begin
      if Trim(Lines[I]) = '' then
        Continue;
      Parts := Lines[I].Split([',']);
      if Length(Parts) < 5 then
        Continue;
      Det.StartSec := StrToFloatDef(Trim(Parts[0]), 0, FS);
      Det.EndSec := StrToFloatDef(Trim(Parts[1]), 0, FS);
      Det.Confidence := StrToFloatDef(Trim(Parts[High(Parts)]), 0, FS);
      Det.ScientificName := Trim(Parts[2]);
      Name := '';
      for K := 3 to High(Parts) - 1 do begin
        if K > 3 then
          Name := Name + ',';
        Name := Name + Trim(Parts[K]);
      end;
      Det.CommonName := Name;
      Result := Result + [Det];
    end;
  finally
    Lines.Free;
  end;
end;



function TFormMain.TopMeanConfidence(const ADetections: TArray<TBatDetection>; ALow, AHigh: Integer): Double;
var
  Vals: TArray<Double>;
  I, N: Integer;
  Sum: Double;
begin
  SetLength(Vals, AHigh - ALow + 1);
  for I := 0 to High(Vals) do
    Vals[I] := ADetections[ALow + I].Confidence;
  TArray.Sort<Double>(Vals, TComparer<Double>.Construct(
    function(const L, R: Double): Integer
    begin
      Result := CompareValue(R, L);
    end));
  N := Min(3, Length(Vals));
  Sum := 0;
  for I := 0 to N - 1 do
    Sum := Sum + Vals[I];
  Result := Sum / N;
end;



function TFormMain.MergeConsecutiveDetections(const ADetections: TArray<TBatDetection>): TArray<TBatDetection>;
const
  GAP_TOLERANCE_SEC = 5;
var
  GroupStart, GroupEnd: Integer;
  Merged: TBatDetection;
begin
  Result := [];
  if Length(ADetections) = 0 then
    Exit();
  GroupStart := 0;
  while GroupStart <= High(ADetections) do begin
    GroupEnd := GroupStart;
    while (GroupEnd < High(ADetections)) and (ADetections[GroupEnd + 1].CommonName = ADetections[GroupStart].CommonName) and
      (ADetections[GroupEnd + 1].StartSec <= ADetections[GroupEnd].EndSec + GAP_TOLERANCE_SEC) do
      Inc(GroupEnd);
    Merged := ADetections[GroupStart];
    Merged.EndSec := ADetections[GroupEnd].EndSec;
    Merged.Confidence := TopMeanConfidence(ADetections, GroupStart, GroupEnd);
    Result := Result + [Merged];
    GroupStart := GroupEnd + 1;
  end;
end;



function TFormMain.TryParseFileNameDateTime(const ABaseName: string; out ADateTime: TDateTime): Boolean;
var
  StampPos, StampLen: Integer;
begin
  Result := FindFileNameStamp(ABaseName, ADateTime, StampPos, StampLen);
end;



function TFormMain.FindFileNameStamp(const ABaseName: string; out ADateTime: TDateTime; out AStampPos, AStampLen: Integer): Boolean;
var
  P, I: Integer;
  IsStamp: Boolean;
  Y, Mo, D, H, Mi, S: Integer;
begin
  { Looks for the first yyyymmdd_hhnnss anywhere in the name, as a separate run of digits, so recordings such as
    "1.000_7_20250812_034000" and exported clips are read as well as plain "20250812_034000". Exported clips can
    carry tenths of a second after it ("20250812_034000.3"). }
  Result := False;
  AStampPos := 0;
  AStampLen := 15;
  for P := 1 to Length(ABaseName) - 14 do begin
    if (P > 1) and CharInSet(ABaseName[P - 1], ['0'..'9']) then
      Continue;
    if (P + 15 <= Length(ABaseName)) and CharInSet(ABaseName[P + 15], ['0'..'9']) then
      Continue;
    if ABaseName[P + 8] <> '_' then
      Continue;
    IsStamp := True;
    for I := 0 to 14 do
      if (I <> 8) and not CharInSet(ABaseName[P + I], ['0'..'9']) then begin
        IsStamp := False;
        Break;
      end;
    if not IsStamp then
      Continue;
    Y := StrToInt(Copy(ABaseName, P, 4));
    Mo := StrToInt(Copy(ABaseName, P + 4, 2));
    D := StrToInt(Copy(ABaseName, P + 6, 2));
    H := StrToInt(Copy(ABaseName, P + 9, 2));
    Mi := StrToInt(Copy(ABaseName, P + 11, 2));
    S := StrToInt(Copy(ABaseName, P + 13, 2));
    if TryEncodeDateTime(Y, Mo, D, H, Mi, S, 0, ADateTime) then begin
      AStampPos := P;
      if (P + 16 <= Length(ABaseName)) and (ABaseName[P + 15] = '.') and CharInSet(ABaseName[P + 16], ['0'..'9']) and
        ((P + 17 > Length(ABaseName)) or not CharInSet(ABaseName[P + 17], ['0'..'9'])) then begin
        ADateTime := IncMilliSecond(ADateTime, StrToInt(ABaseName[P + 16]) * 100);
        AStampLen := 17;
      end;
      Result := True;
      Exit();
    end;
  end;
end;



function TFormMain.GetFileFallbackDateTime(const AFilePath: string): TDateTime;
const
  SECONDS_PER_DAY = 86400.0;
var
  Created, Modified: TDateTime;
  DurSec: Double;
begin
  Created := TFile.GetCreationTime(AFilePath);
  Modified := TFile.GetLastWriteTime(AFilePath);
  if Modified <= Created then begin
    DurSec := GetWavDurationSec(AFilePath);
    Result := Modified - (DurSec / SECONDS_PER_DAY);
  end
  else
    Result := Created;
end;



procedure TFormMain.ScanFolderForFiles(const AFolder: string);
const
  SECONDS_PER_DAY = 86400.0;
var
  SR: TSearchRec;
  Entry: TBatFileEntry;
  CsvPath, BaseName: string;
  K: Integer;
begin
  SetLength(FFileEntries, 0);
  if FindFirst(AFolder + '\*.wav', faAnyFile, SR) = 0 then begin
    try
      repeat
        if (SR.Attr and faDirectory) <> 0 then
          Continue;
        Entry.FilePath := AFolder + '\' + SR.Name;
        Entry.FileName := SR.Name;
        BaseName := ChangeFileExt(SR.Name, '');
        if not TryParseFileNameDateTime(BaseName, Entry.RecordedAt) then
          Entry.RecordedAt := GetFileFallbackDateTime(Entry.FilePath);
        CsvPath := ChangeFileExt(Entry.FilePath, '.results.csv');
        Entry.HasCsv := FileExists(CsvPath);
        if Entry.HasCsv then
          Entry.Detections := MergeConsecutiveDetections(ParseBatResults(CsvPath))
        else
          Entry.Detections := [];
        for K := 0 to High(Entry.Detections) do
          Entry.Detections[K].DateTime := Entry.RecordedAt + (Entry.Detections[K].StartSec / SECONDS_PER_DAY);
        FFileEntries := FFileEntries + [Entry];
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
  BuildSpeciesEntries;
  BuildResultsList;
end;



function TFormMain.GetCurrentFileIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FFileEntries) do
    if FFileEntries[I].FilePath = FCurrentFilePath then begin
      Result := I;
      Exit();
    end;
end;



function TFormMain.GetCurrentFileDetections: TArray<TBatDetection>;
var
  Idx: Integer;
begin
  Idx := GetCurrentFileIndex();
  if Idx >= 0 then
    Result := FFileEntries[Idx].Detections
  else
    Result := [];
end;



procedure TFormMain.JumpToDetection(const Det: TBatDetection);
begin
  if FWavFile = nil then
    Exit();
  FZoomStart := Max(0.0, (Det.StartSec - 0.5) / FWavFile.Info.DurationSec);
  FZoomEnd := Min(1.0, (Det.EndSec + 0.5) / FWavFile.Info.DurationSec);
  if FZoomEnd <= FZoomStart then
    FZoomEnd := Min(1.0, FZoomStart + 0.01);
  UpdateZoomBar();
  ApplyAutoFloorCeiling();
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
end;



function TFormMain.GetMarkerRect(const Det: TBatDetection; DurationSec: Double; ALeft, ARight: Integer): TRect;
const
  MARKER_MIN_WIDTH = 5;
var
  W, Mid: Integer;
  Frac0, Frac1: Double;
begin
  W := ARight - ALeft;
  Frac0 := (Det.StartSec / DurationSec - FZoomStart) / (FZoomEnd - FZoomStart);
  Frac1 := (Det.EndSec / DurationSec - FZoomStart) / (FZoomEnd - FZoomStart);
  Result.Left := ALeft + Round(Frac0 * W);
  Result.Right := ALeft + Round(Frac1 * W);
  if Result.Right - Result.Left < MARKER_MIN_WIDTH then begin
    Mid := (Result.Left + Result.Right) div 2;
    Result.Left := Mid - MARKER_MIN_WIDTH div 2;
    Result.Right := Result.Left + MARKER_MIN_WIDTH;
  end;
  Result.Left := Max(ALeft, Result.Left);
  Result.Right := Min(ARight, Result.Right);
  Result.Top := 0;
  Result.Bottom := 0;
end;



function TFormMain.GetCurrentFileRecordedAt: TDateTime;
var
  BaseName: string;
begin
  BaseName := ChangeFileExt(ExtractFileName(FCurrentFilePath), '');
  if not TryParseFileNameDateTime(BaseName, Result) then
    Result := GetFileFallbackDateTime(FCurrentFilePath);
end;



function TFormMain.GetCurrentClipSpeciesName: string;
var
  Detections: TArray<TBatDetection>;
  I: Integer;
  ClipStart, ClipEnd: Double;
begin
  Result := '';
  if FWavFile = nil then
    Exit();
  Detections := GetCurrentFileDetections();
  ClipStart := FZoomStart * FWavFile.Info.DurationSec;
  ClipEnd := FZoomEnd * FWavFile.Info.DurationSec;
  for I := 0 to High(Detections) do
    if (Detections[I].StartSec < ClipEnd) and (Detections[I].EndSec > ClipStart) then begin
      if Result = '' then
        Result := Detections[I].CommonName
      else if not SameText(Result, Detections[I].CommonName) then
        Exit('');
    end;
end;



function TFormMain.SanitizeSpeciesForFileName(const ASpecies: string): string;
const
  INVALID_CHARS: TSysCharSet = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
var
  ParenPos, I: Integer;
begin
  { The translated name is "Common name (Scientific name)" -- keep just the
    common name for the filename. }
  Result := TranslateSpeciesName(ASpecies, FDisplayLanguage);
  ParenPos := Pos(' (', Result);
  if ParenPos > 0 then
    Result := Copy(Result, 1, ParenPos - 1);
  Result := StringReplace(Result, ' ', '_', [rfReplaceAll]);
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], INVALID_CHARS) then
      Result[I] := '_';
end;



function TFormMain.SelectClips(const AFilter: TClipFilter): TArray<TFlatDet>;
var
  Candidates: TArray<TFlatDet>;
  I, J, GroupStart, KeepCount, Count: Integer;
  Det: TBatDetection;
begin
  SetLength(Candidates, 0);
  Count := 0;
  for I := 0 to High(FFileEntries) do
    for J := 0 to High(FFileEntries[I].Detections) do begin
      Det := FFileEntries[I].Detections[J];
      if AFilter.UseMinConfidence and (Det.Confidence < AFilter.MinConfidence) then
        Continue;
      if Count >= Length(Candidates) then
        SetLength(Candidates, Max(64, Length(Candidates) * 2));
      Candidates[Count].CommonName := Det.CommonName;
      Candidates[Count].FileIdx := I;
      Candidates[Count].DetIdx := J;
      Inc(Count);
    end;
  SetLength(Candidates, Count);

  if AFilter.UseBestN then begin
    TArray.Sort<TFlatDet>(Candidates, TComparer<TFlatDet>.Construct(
      function(const A, B: TFlatDet): Integer
      begin
        Result := CompareText(A.CommonName, B.CommonName);
        if Result <> 0 then
          Exit();
        Result := CompareValue(FFileEntries[B.FileIdx].Detections[B.DetIdx].Confidence,
          FFileEntries[A.FileIdx].Detections[A.DetIdx].Confidence);
      end));
    SetLength(Result, Count);
    Count := 0;
    I := 0;
    while I <= High(Candidates) do begin
      GroupStart := I;
      while (I <= High(Candidates)) and SameText(Candidates[I].CommonName, Candidates[GroupStart].CommonName) do
        Inc(I);
      KeepCount := Min(AFilter.BestN, I - GroupStart);
      for J := GroupStart to GroupStart + KeepCount - 1 do begin
        Result[Count] := Candidates[J];
        Inc(Count);
      end;
    end;
    SetLength(Result, Count);
  end
  else
    Result := Candidates;

  TArray.Sort<TFlatDet>(Result, TComparer<TFlatDet>.Construct(
    function(const A, B: TFlatDet): Integer
    begin
      Result := CompareValue(A.FileIdx, B.FileIdx);
      if Result = 0 then
        Result := CompareValue(A.DetIdx, B.DetIdx);
    end));
end;



{ The timestamp in the name is the start of the clip itself, so that opening the exported folder gives every clip its
  true recording time (TryParseFileNameDateTime reads the first timestamp in a name). The source recording's own
  timestamp is left out, since it would only repeat the time; whatever else its name holds is kept after the clip time. }
function TFormMain.BuildSectionFileName(const AEntry: TBatFileEntry; const Det: TBatDetection; AClipStartSec: Double): string;
var
  SourceName, Rest: string;
  SourceTime: TDateTime;
  StampPos, StampLen, Tenths: Integer;
begin
  { The clip starts on a tenth of a second (see ExportDetectionSection), counted here from the whole second of the
    recording time, so the name can hold it exactly as "yyyymmdd_hhnnss.t". }
  Tenths := Round((MilliSecondOf(AEntry.RecordedAt) / 1000.0 + AClipStartSec) * 10);
  Result := SanitizeSpeciesForFileName(Det.CommonName) + '_' +
    FormatDateTime('yyyymmdd_hhnnss', IncSecond(RecodeMilliSecond(AEntry.RecordedAt, 0), Tenths div 10), TFormatSettings.Invariant) +
    '.' + IntToStr(Tenths mod 10);
  SourceName := ChangeFileExt(AEntry.FileName, '');
  if FindFileNameStamp(SourceName, SourceTime, StampPos, StampLen) then
    SourceName := Copy(SourceName, 1, StampPos - 1) + Copy(SourceName, StampPos + StampLen, MaxInt);
  Rest := Trim(SourceName);
  while (Rest <> '') and CharInSet(Rest[1], ['_', '-', ' ', '.']) do
    Delete(Rest, 1, 1);
  while (Rest <> '') and CharInSet(Rest[Length(Rest)], ['_', '-', ' ', '.']) do
    Delete(Rest, Length(Rest), 1);
  if Rest <> '' then
    Result := Result + '_' + Rest;
end;



function TFormMain.BuildDefaultExportFileName(AIncludePlaybackSuffix: Boolean): string;
var
  Species, Expansion, DateTimePart: string;
  ExpansionFactor: Double;
begin
  DateTimePart := FormatDateTime('yyyymmdd_hhnnss', GetCurrentFileRecordedAt(), TFormatSettings.Invariant);
  Species := GetCurrentClipSpeciesName();
  if Species <> '' then
    Result := SanitizeSpeciesForFileName(Species) + '_' + DateTimePart
  else
    Result := DateTimePart;
  if AIncludePlaybackSuffix then begin
    if RbHeterodyne.Checked then
      Result := Result + '_HET_' + IntToStr(TrkTuneFreq.Position) + 'kHz'
    else begin
      ExpansionFactor := 1.0 / GetPlaybackRate();
      if SameValue(Frac(ExpansionFactor), 0.0) then
        Expansion := IntToStr(Round(ExpansionFactor))
      else
        Expansion := FormatFloat('0.#', ExpansionFactor, TFormatSettings.Invariant);
      Result := Result + '_TE_x' + Expansion;
    end;
  end;
end;



function TFormMain.CanCopyOriginalForExport(const ATargetExt: string): Boolean;
begin
  { A straight file copy is only equivalent to re-encoding when nothing
    would actually change: same format, the whole file (not just a zoomed
    section), no time expansion, no gain. Copying preserves the original's
    exact bit depth and (for MP3) avoids a second lossy encode -- both of
    which re-encoding through Samples always loses, even at these settings. }
  Result := (FCurrentFilePath <> '') and SameText(ExtractFileExt(FCurrentFilePath), ATargetExt) and
    SameValue(FZoomStart, 0.0) and SameValue(FZoomEnd, 1.0) and
    SameValue(GetPlaybackRate(), 1.0) and (TrkGain.Position = 0);
end;



function MakeUniqueName(const ABaseName: string; AUsedNames: TStrings): string;
var
  N: Integer;
begin
  Result := ABaseName;
  N := 1;
  while AUsedNames.IndexOf(Result) >= 0 do begin
    Inc(N);
    Result := Format('%s_%d', [ABaseName, N]);
  end;
  AUsedNames.Add(Result);
end;



{ Writes "<clip>.results.csv" in the format BattyBirdNET itself produces, with a single row: the result that led to
  the clip, with its times counted from the start of the clip. }
procedure TFormMain.WriteClipResultsCsv(const AFileName: string; const Det: TBatDetection; AClipStartSec, AClipEndSec: Double);
var
  Lines: TStringList;
  RowStart, RowEnd: Double;
begin
  RowStart := Max(0.0, Det.StartSec - AClipStartSec);
  RowEnd := Min(AClipEndSec - AClipStartSec, Det.EndSec - AClipStartSec);
  Lines := TStringList.Create();
  try
    Lines.Add('Start (s),End (s),Scientific name,Common name,Confidence');
    Lines.Add(FormatFloat('0.####', RowStart, TFormatSettings.Invariant) + ',' +
      FormatFloat('0.####', RowEnd, TFormatSettings.Invariant) + ',' + Det.ScientificName + ',' + Det.CommonName + ',' +
      FormatFloat('0.0000', Det.Confidence, TFormatSettings.Invariant));
    Lines.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Lines.Free();
  end;
end;



procedure TFormMain.ExportDetectionSection(AWav: TWavFile; const AEntry: TBatFileEntry; const Det: TBatDetection;
  const AOutputFolder: string; AMarginSec: Double; AWriteCsv: Boolean; AUsedNames: TStrings;
  var ASavedCount, ASkippedCount: Integer; AErrorLog: TStrings);
var
  ZoomStart, ZoomEnd, ClipStartSec, ClipEndSec, SecFraction: Double;
  BaseName, FilePath: string;
  ActualRate: Cardinal;
begin
  { The clip name holds tenths of a second, so the clip starts on a tenth of the recording time (less than 0.1 s
    earlier than the margin asks for). That keeps the times of the clips and of the results in them exact. }
  SecFraction := MilliSecondOf(AEntry.RecordedAt) / 1000.0;
  ClipStartSec := Max(0.0, Floor((Det.StartSec - AMarginSec + SecFraction) * 10 + 1.0E-6) / 10.0 - SecFraction);
  ClipEndSec := Min(AWav.Info.DurationSec, Det.EndSec + AMarginSec);
  ZoomStart := ClipStartSec / AWav.Info.DurationSec;
  ZoomEnd := ClipEndSec / AWav.Info.DurationSec;
  if ZoomEnd <= ZoomStart then
    ZoomEnd := Min(1.0, ZoomStart + 0.01);
  { Two detections can map to the same name (same species, same second); without a suffix the second clip would
    silently overwrite the first while both were counted as exported. }
  BaseName := MakeUniqueName(BuildSectionFileName(AEntry, Det, ClipStartSec), AUsedNames);
  FilePath := IncludeTrailingPathDelimiter(AOutputFolder) + BaseName;
  try
    SaveWav(AWav.Samples, ZoomStart, ZoomEnd, FilePath + '.wav', AWav.Info.SampleRate, 1.0, ActualRate);
    Inc(ASavedCount);
  except
    on E: Exception do begin
      Inc(ASkippedCount);
      AErrorLog.Add(BaseName + ': ' + E.Message);
      Exit();
    end;
  end;
  if AWriteCsv then
    try
      WriteClipResultsCsv(FilePath + '.results.csv', Det, ClipStartSec, ClipEndSec);
    except
      on E: Exception do
        AErrorLog.Add(BaseName + '.results.csv: ' + E.Message);
    end;
end;



procedure TFormMain.ExportClips(const ASelected: TArray<TFlatDet>; AMarginSec: Double; AWriteCsv: Boolean;
  const AOutputFolder: string; var ASavedCount, ASkippedCount: Integer; var ACancelled: Boolean; AErrorLog: TStrings);
var
  Wav: TWavFile;
  Entry: TBatFileEntry;
  UsedNames: TStringList;
  Loaded: Boolean;
  I, J, FileStart, FileIdx, Total: Integer;
begin
  Total := Length(ASelected);
  UsedNames := TStringList.Create();
  try
    UsedNames.Sorted := True;
    UsedNames.CaseSensitive := False;
    UsedNames.Duplicates := dupIgnore;
    I := 0;
    while (I < Total) and not ACancelled do begin
      FileIdx := ASelected[I].FileIdx;
      FileStart := I;
      while (I < Total) and (ASelected[I].FileIdx = FileIdx) do
        Inc(I);
      Entry := FFileEntries[FileIdx];
      FBusyForm.SetProgress(ASavedCount + ASkippedCount, Total);
      FBusyForm.LblMessage.Caption := Format('Loading %s...', [Entry.FileName]);
      Wav := TWavFile.Create();
      try
        Loaded := True;
        try
          Wav.LoadFromFile(Entry.FilePath, TickBusy);
        except
          on E: Exception do begin
            Loaded := False;
            AErrorLog.Add(Entry.FileName + ': ' + E.Message);
            Inc(ASkippedCount, I - FileStart);
          end;
        end;
        if Loaded then
          for J := FileStart to I - 1 do begin
            FBusyForm.SetProgress(ASavedCount + ASkippedCount, Total);
            FBusyForm.LblMessage.Caption :=
              Format('Exporting clip %d of %d: %s', [ASavedCount + ASkippedCount + 1, Total, Entry.FileName]);
            TickBusy();
            if FBusyForm.Cancelled then begin
              ACancelled := True;
              Break;
            end;
            ExportDetectionSection(Wav, Entry, Entry.Detections[ASelected[J].DetIdx], AOutputFolder, AMarginSec, AWriteCsv,
              UsedNames, ASavedCount, ASkippedCount, AErrorLog);
          end;
      finally
        Wav.Free();
      end;
      if FBusyForm.Cancelled then
        ACancelled := True;
    end;
  finally
    UsedNames.Free();
  end;
end;



procedure TFormMain.ReportClipExportResult(const AOutputFolder: string; ASavedCount, ASkippedCount, ATotal: Integer;
  ACancelled: Boolean; AErrorLog: TStrings);
const
  MAX_ERROR_LINES = 5;
var
  Msg: string;
  I: Integer;
begin
  if ACancelled then
    Msg := Format('Cancelled. Exported %d of %d section(s) to %s.', [ASavedCount, ATotal, AOutputFolder])
  else if ASkippedCount = 0 then
    Msg := Format('Exported %d section(s) to %s.', [ASavedCount, AOutputFolder])
  else
    Msg := Format('Exported %d section(s), %d skipped, to %s.', [ASavedCount, ASkippedCount, AOutputFolder]);
  for I := 0 to Min(MAX_ERROR_LINES, AErrorLog.Count) - 1 do
    Msg := Msg + #13#10 + AErrorLog[I];
  if AErrorLog.Count > MAX_ERROR_LINES then
    Msg := Msg + #13#10 + Format('(%d more)', [AErrorLog.Count - MAX_ERROR_LINES]);
  if (AErrorLog.Count = 0) and not ACancelled then
    MessageDlg(Msg, mtInformation, [mbOK], 0)
  else
    MessageDlg(Msg, mtWarning, [mbOK], 0);
end;



procedure TFormMain.BuildSpeciesEntries;
var
  Flat: TArray<TFlatDet>;
  I, J, StartIdx: Integer;
  FD: TFlatDet;
  Species: TSpeciesEntry;
begin
  Flat := [];
  for I := 0 to High(FFileEntries) do
    if FFileEntries[I].HasCsv then
      for J := 0 to High(FFileEntries[I].Detections) do begin
        FD.CommonName := FFileEntries[I].Detections[J].CommonName;
        FD.FileIdx := I;
        FD.DetIdx := J;
        Flat := Flat + [FD];
      end;
  TArray.Sort<TFlatDet>(Flat, TComparer<TFlatDet>.Construct(
    function(const A, B: TFlatDet): Integer
    var
      DA, DB: TBatDetection;
    begin
      Result := CompareText(A.CommonName, B.CommonName);
      if Result <> 0 then
        Exit;
      DA := FFileEntries[A.FileIdx].Detections[A.DetIdx];
      DB := FFileEntries[B.FileIdx].Detections[B.DetIdx];
      if FSortColumn = rscTimestamp then
        Result := CompareValue(DA.DateTime, DB.DateTime)
      else
        Result := CompareValue(DA.Confidence, DB.Confidence);
      if not FSortAscending then
        Result := -Result;
    end));
  SetLength(FSpeciesEntries, 0);
  I := 0;
  while I <= High(Flat) do begin
    StartIdx := I;
    while (I <= High(Flat)) and SameText(Flat[I].CommonName, Flat[StartIdx].CommonName) do
      Inc(I);
    Species.CommonName := Flat[StartIdx].CommonName;
    Species.Expanded := True;
    SetLength(Species.Refs, I - StartIdx);
    for J := StartIdx to I - 1 do begin
      Species.Refs[J - StartIdx].FileIdx := Flat[J].FileIdx;
      Species.Refs[J - StartIdx].DetIdx := Flat[J].DetIdx;
    end;
    FSpeciesEntries := FSpeciesEntries + [Species];
  end;
  TArray.Sort<TSpeciesEntry>(FSpeciesEntries, TComparer<TSpeciesEntry>.Construct(
    function(const A, B: TSpeciesEntry): Integer
    begin
      Result := CompareText(TranslateSpeciesName(A.CommonName, FDisplayLanguage), TranslateSpeciesName(B.CommonName, FDisplayLanguage));
    end));
end;



procedure TFormMain.BuildResultsList;
var
  I, J: Integer;
  Item: TListItem;
  Species: TSpeciesEntry;
  Entry: TBatFileEntry;
  Det: TBatDetection;
  RD: PRowData;
  Cap: string;
  AnyCsv: Boolean;
begin
  ClearFileListRowData;
  FileListView.Items.BeginUpdate;
  try
    AnyCsv := False;
    for I := 0 to High(FFileEntries) do
      if FFileEntries[I].HasCsv then begin
        AnyCsv := True;
        Break;
      end;
    FileListView.ShowColumnHeaders := AnyCsv;
    BtnNightlyActivity.Visible := AnyCsv;
    BtnExportClips.Enabled := AnyCsv;
    if AnyCsv then
      PanelFilesBottom.Height := PANEL_FILES_BOTTOM_HEIGHT_WITH_CSV
    else
      PanelFilesBottom.Height := PANEL_FILES_BOTTOM_HEIGHT_NO_CSV;
    if not AnyCsv then begin
      for I := 0 to High(FFileEntries) do begin
        Item := FileListView.Items.Add;
        Item.Caption := FFileEntries[I].FileName;
        Item.SubItems.Add('');
        New(RD);
        RD^.Kind := rkFile;
        RD^.SpeciesIdx := -1;
        RD^.FileIdx := I;
        RD^.DetIdx := -1;
        Item.Data := RD;
      end;
    end else begin
      for I := 0 to High(FSpeciesEntries) do begin
        Species := FSpeciesEntries[I];
        if Species.Expanded then
          Cap := #$25BC + ' ' + TranslateSpeciesName(Species.CommonName, FDisplayLanguage)
        else
          Cap := #$25B6 + ' ' + TranslateSpeciesName(Species.CommonName, FDisplayLanguage);
        Item := FileListView.Items.Add;
        Item.Caption := Cap;
        Item.SubItems.Add('');
        New(RD);
        RD^.Kind := rkSpecies;
        RD^.SpeciesIdx := I;
        RD^.FileIdx := -1;
        RD^.DetIdx := -1;
        Item.Data := RD;
        if Species.Expanded then begin
          for J := 0 to High(Species.Refs) do begin
            Entry := FFileEntries[Species.Refs[J].FileIdx];
            Det := Entry.Detections[Species.Refs[J].DetIdx];
            Item := FileListView.Items.Add;
            Item.Caption := '    ' + LowerCase(FormatDateTime('d mmmm, hh:nn:ss', Det.DateTime, TFormatSettings.Invariant));
            Item.SubItems.Add(Format('%.2f%%', [Det.Confidence * 100]));
            New(RD);
            RD^.Kind := rkDetection;
            RD^.SpeciesIdx := I;
            RD^.FileIdx := Species.Refs[J].FileIdx;
            RD^.DetIdx := Species.Refs[J].DetIdx;
            Item.Data := RD;
          end;
        end;
      end;
    end;
  finally
    FileListView.Items.EndUpdate;
  end;
  FitResultsColumns();
end;



procedure TFormMain.ScanAndShowFolder(const AFolder: string);
begin
  ScanFolderForFiles(AFolder);
  if Length(FFileEntries) = 0 then
    MessageDlg('No WAV files found in the selected folder.', mtWarning, [mbOK], 0)
  else begin
    PanelRight.Visible := True;
    SplitterRight.Visible := True;
  end;
  UpdateTransportButtons();
end;



procedure TFormMain.BtnOpenFolderClick(Sender: TObject);
var
  D: TFileOpenDialog;
begin
  D := TFileOpenDialog.Create(nil);
  try
    D.Options := [fdoPickFolders, fdoPathMustExist];
    if FLastOpenFolder <> '' then
      D.DefaultFolder := FLastOpenFolder;
    if D.Execute then begin
      FLastOpenFolder := ExcludeTrailingPathDelimiter(D.FileName);
      ScanAndShowFolder(FLastOpenFolder);
    end;
  finally
    D.Free;
  end;
end;



procedure TFormMain.WMDropFiles(var Msg: TMessage);
var
  Drop: HDROP;
  FileNames: TArray<string>;
  Buf: array [0 .. MAX_PATH] of Char;
  Count, I: Integer;
begin
  Drop := HDROP(Msg.WParam);
  try
    Count := DragQueryFile(Drop, $FFFFFFFF, nil, 0);
    SetLength(FileNames, Count);
    for I := 0 to Count - 1 do begin
      DragQueryFile(Drop, I, @Buf[0], MAX_PATH);
      FileNames[I] := PChar(@Buf[0]);
    end;
  finally
    DragFinish(Drop);
  end;
  Msg.Result := 0;
  HandleDroppedFiles(FileNames);
end;



procedure TFormMain.HandleDroppedFiles(const FileNames: TArray<string>);
var
  Ext: string;
begin
  if Length(FileNames) = 0 then
    Exit();
  if Length(FileNames) = 1 then begin
    if DirectoryExists(FileNames[0]) then begin
      ScanAndShowFolder(ExcludeTrailingPathDelimiter(FileNames[0]));
      Exit();
    end;
    Ext := ExtractFileExt(FileNames[0]);
    if not (SameText(Ext, '.wav') or SameText(Ext, '.mp3')) then begin
      MessageDlg('Only a WAV/MP3 file or a folder can be dropped here.', mtWarning, [mbOK], 0);
      Exit();
    end;
    LoadFile(FileNames[0]);
    PanelRight.Visible := False;
    SplitterRight.Visible := False;
    Exit();
  end;
  { Multiple files dropped at once -- browse them like Open Folder, using
    the folder they were dropped from. }
  ScanAndShowFolder(ExcludeTrailingPathDelimiter(ExtractFileDir(FileNames[0])));
end;



procedure TFormMain.BtnIdentifyClick(Sender: TObject);
var
  Form: TFormBatIdent;
begin
  Form := TFormBatIdent.Create(Self);
  try
    Form.ShowModal();
    if Form.Completed and (Form.WAVFolder <> '') then
      ScanAndShowFolder(Form.WAVFolder);
  finally
    Form.Free();
  end;
end;



procedure TFormMain.BtnPrevFileClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := GetCurrentFileIndex();
  if Idx > 0 then
    LoadFile(FFileEntries[Idx - 1].FilePath);
end;



procedure TFormMain.BtnNextFileClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := GetCurrentFileIndex();
  if (Idx >= 0) and (Idx < High(FFileEntries)) then
    LoadFile(FFileEntries[Idx + 1].FilePath);
end;



procedure TFormMain.BtnCloseRightPanelClick(Sender: TObject);
begin
  PanelRight.Visible := False;
  SplitterRight.Visible := False;
end;



procedure TFormMain.BtnNightlyActivityClick(Sender: TObject);
var
  Items: TArray<TNightlyActivityItem>;
  Item: TNightlyActivityItem;
  I, J, ParenPos: Integer;
  DisplayName: string;
begin
  Items := [];
  for I := 0 to High(FFileEntries) do
    if FFileEntries[I].HasCsv then
      for J := 0 to High(FFileEntries[I].Detections) do begin
        { Strip the "(Scientific name)" suffix TranslateSpeciesName appends,
          same as BuildDefaultExportFileName does, so the legend stays short. }
        DisplayName := TranslateSpeciesName(FFileEntries[I].Detections[J].CommonName, FDisplayLanguage);
        ParenPos := Pos(' (', DisplayName);
        if ParenPos > 0 then
          DisplayName := Copy(DisplayName, 1, ParenPos - 1);
        Item.DateTime := FFileEntries[I].Detections[J].DateTime;
        Item.SpeciesName := DisplayName;
        Items := Items + [Item];
      end;
  ShowNightlyActivity(Self, Items);
end;



procedure TFormMain.CbxLanguageChange(Sender: TObject);
begin
  FDisplayLanguage := TDisplayLanguage(CbxLanguage.ItemIndex);
  BuildSpeciesEntries;
  BuildResultsList;
end;



procedure TFormMain.FileListViewClick(Sender: TObject);
var
  Item: TListItem;
  RD: PRowData;
begin
  Item := FileListView.Selected;
  if Item = nil then
    Exit();
  RD := PRowData(Item.Data);
  if RD = nil then
    Exit();
  if RD^.Kind = rkSpecies then begin
    FSpeciesEntries[RD^.SpeciesIdx].Expanded := not FSpeciesEntries[RD^.SpeciesIdx].Expanded;
    BuildResultsList;
  end;
end;



procedure TFormMain.FileListViewDblClick(Sender: TObject);
var
  Item: TListItem;
  RD: PRowData;
  Entry: TBatFileEntry;
begin
  Item := FileListView.Selected;
  if Item = nil then
    Exit();
  RD := PRowData(Item.Data);
  if RD = nil then
    Exit();
  if RD^.Kind = rkFile then begin
    LoadFile(FFileEntries[RD^.FileIdx].FilePath);
    Exit();
  end;
  if RD^.Kind <> rkDetection then
    Exit();
  Entry := FFileEntries[RD^.FileIdx];
  if FCurrentFilePath <> Entry.FilePath then
    LoadFile(Entry.FilePath);
  JumpToDetection(Entry.Detections[RD^.DetIdx]);
end;

{ ---- export ---------------------------------------------------------------- }



type
  TExportType = record
    DisplayName: string;
    Mask: string;
    Ext: string;
  end;

const
  EXPORT_TYPES: array[0..4] of TExportType = (
    (DisplayName: 'PNG image: waveform and spectrogram'; Mask: '*.png'; Ext: '.png'),
    (DisplayName: 'PNG image: spectrogram only'; Mask: '*.png'; Ext: '.png'),
    (DisplayName: 'PNG image: waveform only'; Mask: '*.png'; Ext: '.png'),
    (DisplayName: 'WAV audio'; Mask: '*.wav'; Ext: '.wav'),
    (DisplayName: 'MP3 audio'; Mask: '*.mp3'; Ext: '.mp3'));
  EXPORT_TYPE_FIRST_AUDIO = 4;



procedure TFormMain.ExportImage(const AFileName: string; ATarget: Integer);
var
  WavBmp, SpectBmp: TBitmap;
  Scheme: TColorScheme;
  VR, VG, VB: Byte;
  BgColor, WaveColor, OuterColor, AxisColor, GridColor: TColor;
  Samples: TArray<Single>;
begin
  if FSpecgram = nil then
    Exit();
  Scheme := IdxToColorScheme(CbxColorScheme.ItemIndex);
  FSpecgram.GetColor(0.0, Scheme, VR, VG, VB);
  BgColor := RGB(VR, VG, VB);
  FSpecgram.GetColor(1.0, Scheme, VR, VG, VB);
  WaveColor := RGB(VR, VG, VB);
  OuterColor := StyleServices.GetSystemColor(clWindow);
  AxisColor := StyleServices.GetSystemColor(clWindowText);
  GridColor := BlendColors(OuterColor, AxisColor, 0.3);
  Samples := FWavFile.Samples;
  WavBmp := TBitmap.Create();
  SpectBmp := TBitmap.Create();
  try
    WavBmp.PixelFormat := pf24bit;
    WavBmp.Width := WaveformBox.Width;
    WavBmp.Height := WaveformBox.Height;
    PaintWaveform(WavBmp.Canvas, WavBmp.Width, WavBmp.Height, Rect(LEFT_MARGIN, WAVE_VPAD, WavBmp.Width - RIGHT_MARGIN, WavBmp.Height - WAVE_VPAD), Samples,
      FZoomStart, FZoomEnd, FCursorPos, OuterColor, BgColor, WaveColor, AxisColor, GridColor, AxisColor);
    SpectBmp.PixelFormat := pf24bit;
    SpectBmp.Width := PaintBox.Width;
    SpectBmp.Height := PaintBox.Height;
    FDragging := False;
    WaveformBox.Invalidate();
    PaintBox.Perform(WM_PAINT, WPARAM(SpectBmp.Canvas.Handle), 0);
    try
      SavePng(WavBmp, SpectBmp, ATarget, AFileName);
    except
      on E: Exception do
        MessageDlg('Error saving PNG:'#13#10 + E.Message, mtError, [mbOK], 0);
    end;
  finally
    WavBmp.Free();
    SpectBmp.Free();
  end;
end;



procedure TFormMain.ExportAudio(const AFileName, AExt: string);
var
  DesiredRate, ActualRate: Cardinal;
  Fmt: string;
begin
  if FWavFile = nil then
    Exit();
  Fmt := UpperCase(Copy(AExt, 2, MaxInt));
  Screen.Cursor := crHourGlass;
  try
    try
      if CanCopyOriginalForExport(AExt) then begin
        TFile.Copy(FCurrentFilePath, AFileName, True);
        StatusBar.Panels[0].Text := Fmt + ' saved — copied original file';
      end else begin
        DesiredRate := Round(FWavFile.Info.SampleRate * GetPlaybackRate());
        if SameText(AExt, '.mp3') then
          SaveMp3(FWavFile.Samples, FZoomStart, FZoomEnd, AFileName, DesiredRate, GetPlaybackGain(), ActualRate)
        else
          SaveWav(FWavFile.Samples, FZoomStart, FZoomEnd, AFileName, DesiredRate, GetPlaybackGain(), ActualRate);
        StatusBar.Panels[0].Text := Format('%s saved — %d Hz (%.1f%% speed)',
          [Fmt, ActualRate, DesiredRate / FWavFile.Info.SampleRate * 100]);
      end;
    except
      on E: Exception do
        MessageDlg('Error saving ' + Fmt + ':'#13#10 + E.Message, mtError, [mbOK], 0);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;



procedure TFormMain.BtnExportClick(Sender: TObject);
var
  D: TFileSaveDialog;
  Item: TFileTypeItem;
  I, TypeIdx: Integer;
  FileName, Ext, TypedExt: string;
begin
  if FWavFile = nil then
    Exit();
  D := TFileSaveDialog.Create(nil);
  try
    for I := 0 to High(EXPORT_TYPES) do begin
      Item := D.FileTypes.Add();
      Item.DisplayName := EXPORT_TYPES[I].DisplayName;
      Item.FileMask := EXPORT_TYPES[I].Mask;
    end;
    D.FileTypeIndex := EnsureRange(FExportTypeIdx, 1, Length(EXPORT_TYPES));
    D.DefaultExtension := Copy(EXPORT_TYPES[D.FileTypeIndex - 1].Ext, 2, MaxInt);
    D.Options := [fdoOverWritePrompt, fdoPathMustExist];
    D.FileName := BuildDefaultExportFileName(D.FileTypeIndex >= EXPORT_TYPE_FIRST_AUDIO);
    if not D.Execute() then
      Exit();
    TypeIdx := D.FileTypeIndex;
    FileName := D.FileName;
  finally
    D.Free();
  end;

  FExportTypeIdx := TypeIdx;
  Ext := EXPORT_TYPES[TypeIdx - 1].Ext;
  TypedExt := ExtractFileExt(FileName);
  if not SameText(TypedExt, Ext) then
    if SameText(TypedExt, '.png') or SameText(TypedExt, '.wav') or SameText(TypedExt, '.mp3') then
      FileName := ChangeFileExt(FileName, Ext)
    else
      FileName := FileName + Ext;
  case TypeIdx of
    1:
      ExportImage(FileName, 2);
    2:
      ExportImage(FileName, 1);
    3:
      ExportImage(FileName, 0);
  else
    ExportAudio(FileName, Ext);
  end;
end;



procedure TFormMain.BtnExportClipsClick(Sender: TObject);
var
  Dlg: TFormClipExport;
  D: TFileOpenDialog;
  Filter: TClipFilter;
  Selected: TArray<TFlatDet>;
  ErrorLog: TStringList;
  SavedCount, SkippedCount: Integer;
  Cancelled, Accepted: Boolean;
begin
  if Length(FFileEntries) = 0 then
    Exit();
  Filter := FClipFilter;
  Dlg := TFormClipExport.Create(Self);
  try
    Accepted := Dlg.Execute(Filter,
      function(const AFilter: TClipFilter): Integer
      begin
        Result := Length(SelectClips(AFilter));
      end);
  finally
    Dlg.Free();
  end;
  if not Accepted then
    Exit();
  FClipFilter := Filter;

  D := TFileOpenDialog.Create(nil);
  try
    D.Options := [fdoPickFolders, fdoPathMustExist];
    if FLastSectionsFolder <> '' then
      D.DefaultFolder := FLastSectionsFolder;
    if not D.Execute then
      Exit();
    FLastSectionsFolder := ExcludeTrailingPathDelimiter(D.FileName);
  finally
    D.Free();
  end;

  Selected := SelectClips(Filter);
  SavedCount := 0;
  SkippedCount := 0;
  Cancelled := False;
  ErrorLog := TStringList.Create();
  try
    Screen.Cursor := crHourGlass;
    Enabled := False;
    BeginBusy('Exporting clips...');
    FBusyForm.ShowCancel(True);
    FBusyForm.SetProgress(0, Length(Selected));
    try
      ExportClips(Selected, Filter.MarginSec, Filter.WriteCsv, FLastSectionsFolder, SavedCount, SkippedCount, Cancelled, ErrorLog);
    finally
      EndBusy();
      Enabled := True;
      Screen.Cursor := crDefault;
    end;
    ReportClipExportResult(FLastSectionsFolder, SavedCount, SkippedCount, Length(Selected), Cancelled, ErrorLog);
  finally
    ErrorLog.Free();
  end;
end;

{ ---- playback controls ----------------------------------------------------- }



procedure TFormMain.BtnPlayClick(Sender: TObject);
var
  OutRate, ActualRate: Cardinal;
  StartSample, EndSample, TimelineStart: Integer;
  StartFrac: Double;
  TimeScale: Double;
  Buffer: TArray<Single>;
begin
  if FWavFile = nil then
    Exit();
  try
    if FWavePlayer.IsPaused() then
      FWavePlayer.Resume()
    else begin
      { Only load/convert the current zoom window, not the whole file --
        for a large recording zoomed into a single call, this keeps the
        playback buffer from ballooning to the size of the entire (possibly
        multi-hour) file. Playback also now stops at the zoom end instead of
        continuing into the rest of the file. }
      { If the cursor was placed (by clicking) inside the current zoom
        window before pressing Play, start from there instead of from the
        start of the selection. }
      if (FCursorPos >= FZoomStart) and (FCursorPos <= FZoomEnd) then
        StartFrac := FCursorPos
      else
        StartFrac := FZoomStart;
      StartSample := EnsureRange(Round(StartFrac * FWavFile.Info.NumSamples), 0, FWavFile.Info.NumSamples);
      EndSample := EnsureRange(Round(FZoomEnd * FWavFile.Info.NumSamples), StartSample, FWavFile.Info.NumSamples);
      BuildPlaybackBuffer(StartSample, EndSample, Buffer, TimelineStart, TimeScale, OutRate);
      FWavePlayer.Load(Buffer, FWavFile.Info.NumSamples, TimelineStart, TimeScale, OutRate, GetPlaybackGain(), ActualRate);
      FWavePlayer.Play();
      FCursorPos := StartFrac;
      UpdatePlaybackStatus(OutRate, ActualRate, TimeScale);
    end;
  except
    on E: Exception do begin
      MessageDlg('Audio playback failed:'#13#10 + E.Message, mtError, [mbOK], 0);
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
  FCursorPos := -1;
  ResetPlaybackUI();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
end;



procedure TFormMain.ApplyPlaybackSettingsLive;
var
  WasPaused: Boolean;
  Pos: Double;
  OutRate, ActualRate: Cardinal;
  StartSample, EndSample, TimelineStart: Integer;
  TimeScale: Double;
  Buffer: TArray<Single>;
begin
  if (FWavFile = nil) or not(FWavePlayer.IsPlaying() or FWavePlayer.IsPaused()) then
    Exit();
  WasPaused := FWavePlayer.IsPaused();
  Pos := FWavePlayer.GetNormalizedPosition();
  StartSample := EnsureRange(Round(FZoomStart * FWavFile.Info.NumSamples), 0, FWavFile.Info.NumSamples);
  EndSample := EnsureRange(Round(FZoomEnd * FWavFile.Info.NumSamples), StartSample, FWavFile.Info.NumSamples);
  BuildPlaybackBuffer(StartSample, EndSample, Buffer, TimelineStart, TimeScale, OutRate);
  { Reload with the new speed/gain, then seek back to where playback was and
    resume -- SeekToNormalized() alone can't restart playback here since it
    decides whether to (re)submit the buffer from the state Load() just
    reset, not from the state we captured above, so Play()/Pause() below
    take care of that explicitly. }
  FWavePlayer.Load(Buffer, FWavFile.Info.NumSamples, TimelineStart, TimeScale, OutRate, GetPlaybackGain(), ActualRate);
  FWavePlayer.SeekToNormalized(Pos);
  FWavePlayer.Play();
  if WasPaused then
    FWavePlayer.Pause();
  UpdatePlaybackStatus(OutRate, ActualRate, TimeScale);
end;



procedure TFormMain.BtnPrevResultClick(Sender: TObject);
var
  Detections: TArray<TBatDetection>;
  I, Best: Integer;
  RefTime: Double;
begin
  if FWavFile = nil then
    Exit();
  Detections := GetCurrentFileDetections();
  RefTime := (FZoomStart + FZoomEnd) / 2.0 * FWavFile.Info.DurationSec;
  Best := -1;
  for I := 0 to High(Detections) do
    if Detections[I].StartSec < RefTime - 0.01 then
      Best := I;
  if Best >= 0 then
    JumpToDetection(Detections[Best]);
end;



procedure TFormMain.BtnNextResultClick(Sender: TObject);
var
  Detections: TArray<TBatDetection>;
  I: Integer;
  RefTime: Double;
begin
  if FWavFile = nil then
    Exit();
  Detections := GetCurrentFileDetections();
  RefTime := (FZoomStart + FZoomEnd) / 2.0 * FWavFile.Info.DurationSec;
  for I := 0 to High(Detections) do
    if Detections[I].StartSec > RefTime + 0.01 then begin
      JumpToDetection(Detections[I]);
      Exit();
    end;
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
    FCursorPos := -1;
    ResetPlaybackUI();
    PaintBox.Invalidate();
    DetectionMarkersBox.Invalidate();
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
  { Dragging the slider fires this on every intermediate position; debounce
    so a live reload/reopen of the audio device only happens once dragging
    settles, instead of on every pixel of movement. }
  LivePlaybackTimer.Enabled := False;
  LivePlaybackTimer.Enabled := True;
end;



procedure TFormMain.CbxSpeedChange(Sender: TObject);
begin
  ApplyPlaybackSettingsLive();
end;



procedure TFormMain.PlaybackModeClick(Sender: TObject);
begin
  CbxSpeed.Enabled := RbTimeExpansion.Checked;
  TrkTuneFreq.Enabled := RbHeterodyne.Checked;
  ApplyPlaybackSettingsLive();
end;



procedure TFormMain.TrkTuneFreqChange(Sender: TObject);
begin
  RbHeterodyne.Caption := Format('Heterodyne (%d kHz)', [TrkTuneFreq.Position]);
  { Dragging the slider fires this on every intermediate position; debounce
    so a live reload/reopen of the audio device only happens once dragging
    settles, instead of on every pixel of movement. }
  LivePlaybackTimer.Enabled := False;
  LivePlaybackTimer.Enabled := True;
end;



procedure TFormMain.LivePlaybackTimerTick(Sender: TObject);
begin
  LivePlaybackTimer.Enabled := False;
  ApplyPlaybackSettingsLive();
end;



procedure TFormMain.BtnAutoGainClick(Sender: TObject);
const
  TARGET_PEAK = 0.98;
var
  Samples: TArray<Single>;
  StartSample, EndSample, I: Integer;
  PeakAbs: Double;
  GainDB: Double;
begin
  if FWavFile = nil then
    Exit();
  Samples := FWavFile.Samples;
  StartSample := EnsureRange(Round(FZoomStart * FWavFile.Info.NumSamples), 0, FWavFile.Info.NumSamples);
  EndSample := EnsureRange(Round(FZoomEnd * FWavFile.Info.NumSamples), StartSample, FWavFile.Info.NumSamples);
  PeakAbs := 0.0;
  for I := StartSample to EndSample - 1 do
    PeakAbs := Max(PeakAbs, Abs(Samples[I]));
  if PeakAbs <= 0.0 then
    Exit();
  GainDB := 20.0 * Log10(TARGET_PEAK / PeakAbs);
  TrkGain.Position := EnsureRange(Round(GainDB), TrkGain.Min, TrkGain.Max);
  TrkGainChange(TrkGain);
end;



procedure TFormMain.ChkBGSubChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
end;



procedure TFormMain.ChkFilterChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
end;



procedure TFormMain.CbxColorSchemeChange(Sender: TObject);
begin
  if FSpecgram = nil then
    Exit();
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
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



procedure TFormMain.ApplyAutoFloorCeiling;
var
  FloorDB, CeilingDB, MaxFreqHz: Double;
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  FSpecgram.ComputeAutoRangeForWindow(FZoomStart, FZoomEnd, FloorDB, CeilingDB, MaxFreqHz);
  TrkFloor.Position := EnsureRange(Round(FloorDB), TrkFloor.Min, TrkFloor.Max);
  TrkFloorChange(TrkFloor);
  TrkCeiling.Position := EnsureRange(Round(CeilingDB), TrkCeiling.Min, TrkCeiling.Max);
  TrkCeilingChange(TrkCeiling);
end;



procedure TFormMain.BtnAutoFloorClick(Sender: TObject);
var
  FloorDB, CeilingDB, MaxFreqHz: Double;
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  FSpecgram.ComputeAutoRangeForWindow(FZoomStart, FZoomEnd, FloorDB, CeilingDB, MaxFreqHz);
  TrkFloor.Position := EnsureRange(Round(FloorDB), TrkFloor.Min, TrkFloor.Max);
  TrkFloorChange(TrkFloor);
end;



procedure TFormMain.BtnAutoCeilingClick(Sender: TObject);
var
  FloorDB, CeilingDB, MaxFreqHz: Double;
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  FSpecgram.ComputeAutoRangeForWindow(FZoomStart, FZoomEnd, FloorDB, CeilingDB, MaxFreqHz);
  TrkCeiling.Position := EnsureRange(Round(CeilingDB), TrkCeiling.Min, TrkCeiling.Max);
  TrkCeilingChange(TrkCeiling);
end;



procedure TFormMain.BtnAutoMaxFreqClick(Sender: TObject);
var
  FloorDB, CeilingDB, MaxFreqHz: Double;
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  FSpecgram.ComputeAutoRangeForWindow(FZoomStart, FZoomEnd, FloorDB, CeilingDB, MaxFreqHz);
  TrkMaxFreq.Position := EnsureRange(Round(MaxFreqHz / 1000.0), TrkMaxFreq.Min, TrkMaxFreq.Max);
  TrkMaxFreqChange(TrkMaxFreq);
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
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
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
  if FMeasureMode or (ssShift in Shift) then begin
    FMeasuring := True;
    FHasMeasurement := True;
    FMeasureStartSec := SpectXToSec(X, R);
    FMeasureStartHz := SpectYToHz(Y, R);
    FMeasureEndSec := FMeasureStartSec;
    FMeasureEndHz := FMeasureStartHz;
    PaintBox.Invalidate();
    Exit();
  end;
  FDragging := True;
  FDragStartX := X;
  FDragCurrentX := X;
end;



procedure TFormMain.ApplyZoomDrag(const ChartR: TRect);
var
  W, SelX1, SelX2, AnchorX, DragDist: Integer;
  Frac1, Frac2, ClickFrac, Frac, T, NewSpan, NewStart, NewEnd: Double;
begin
  W := Max(1, ChartR.Right - ChartR.Left);

  if Abs(FDragCurrentX - FDragStartX) < 4 then begin
    ClickFrac := FZoomStart + (Max(ChartR.Left, Min(ChartR.Right, FDragStartX)) - ChartR.Left) / W * (FZoomEnd - FZoomStart);
    FCursorPos := ClickFrac;
    if FWavePlayer.IsPlaying() or FWavePlayer.IsPaused() then
      FWavePlayer.SeekToNormalized(ClickFrac);
  end else if FDragCurrentX > FDragStartX then begin
    SelX1 := Max(ChartR.Left, Min(ChartR.Right, FDragStartX));
    SelX2 := Max(ChartR.Left, Min(ChartR.Right, FDragCurrentX));
    Frac1 := FZoomStart + (SelX1 - ChartR.Left) / W * (FZoomEnd - FZoomStart);
    Frac2 := FZoomStart + (SelX2 - ChartR.Left) / W * (FZoomEnd - FZoomStart);
    FZoomStart := Max(0.0, Frac1);
    FZoomEnd := Min(1.0, Frac2);
    if FZoomEnd <= FZoomStart then
      FZoomEnd := FZoomStart + 0.001;
    UpdateZoomBar();
    RenderSpectrogram();
  end else begin
    { Dragging left zooms out, anchored at the drag start point (so that data
      point stays under the cursor), with the same distance-to-zoom-factor
      relationship used for the zoom-in drag above: covering a small fraction
      of the chart width gives a strong zoom change, a nearly full-width drag
      barely changes the view. }
    AnchorX := Max(ChartR.Left, Min(ChartR.Right, FDragStartX));
    Frac := (AnchorX - ChartR.Left) / W;
    T := FZoomStart + Frac * (FZoomEnd - FZoomStart);
    DragDist := Min(W, Abs(FDragStartX - FDragCurrentX));
    NewSpan := Min(1.0, (FZoomEnd - FZoomStart) * (W / DragDist));
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
  end;
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
end;



procedure TFormMain.ZoomAroundCenter(Factor: Double);
var
  T, Span, NewSpan, NewStart, NewEnd: Double;
begin
  if FWavFile = nil then
    Exit();
  Span := FZoomEnd - FZoomStart;
  T := FZoomStart + 0.5 * Span;
  NewSpan := Max(0.001, Min(1.0, Span * Factor));
  NewStart := T - 0.5 * NewSpan;
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
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
end;



procedure TFormMain.BtnZoomInClick(Sender: TObject);
begin
  ZoomAroundCenter(0.7);
end;



procedure TFormMain.BtnZoomOutClick(Sender: TObject);
begin
  ZoomAroundCenter(1.0 / 0.7);
end;



procedure TFormMain.BtnZoomFullClick(Sender: TObject);
begin
  if FWavFile = nil then
    Exit();
  FZoomStart := 0.0;
  FZoomEnd := 1.0;
  UpdateZoomBar();
  RenderSpectrogram();
  PaintBox.Invalidate();
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
end;



procedure TFormMain.ChkMeasureClick(Sender: TObject);
begin
  FMeasureMode := ChkMeasure.Checked;
  if not FMeasureMode then begin
    ClearMeasurement();
    PaintBox.Invalidate();
  end;
end;



procedure TFormMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit();
  if FMeasuring then begin
    FMeasuring := False;
    Exit();
  end;
  if not FDragging then
    Exit();
  FDragging := False;
  ApplyZoomDrag(SpectRect());
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
    DetectionMarkersBox.Invalidate();
    WaveformBox.Invalidate();
  end;

  if FMeasuring then begin
    FMeasureEndSec := SpectXToSec(X, R);
    FMeasureEndHz := SpectYToHz(Y, R);
    PaintBox.Invalidate();
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
  InPaintBox: Boolean;
  Frac, T, Span, NewSpan, NewStart, NewEnd, ZoomFactor: Double;
begin
  if Msg.Message <> WM_MOUSEWHEEL then
    Exit();
  if FBusyDepth > 0 then
    Exit();
  if FSpecgram = nil then
    Exit();
  MousePos := Point(SmallInt(Msg.lParam and $FFFF), SmallInt(Msg.lParam shr 16));
  LocalPos := PaintBox.ScreenToClient(MousePos);
  InPaintBox := PtInRect(PaintBox.ClientRect, LocalPos);
  if not InPaintBox then begin
    LocalPos := WaveformBox.ScreenToClient(MousePos);
    if not PtInRect(WaveformBox.ClientRect, LocalPos) then
      Exit();
  end;
  WheelDelta := SmallInt(Msg.WPARAM shr 16);
  ChartLeft := LEFT_MARGIN;
  if InPaintBox then
    ChartRight := PaintBox.Width - RIGHT_MARGIN
  else
    ChartRight := WaveformBox.Width - RIGHT_MARGIN;
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
  DetectionMarkersBox.Invalidate();
  WaveformBox.Invalidate();
  UpdateGainRange();
  UpdateTransportButtons();
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
    DetectionMarkersBox.Invalidate();
  end;
end;



procedure TFormMain.WaveformBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or not FDragging then
    Exit();
  FDragging := False;
  ApplyZoomDrag(WaveRect());
end;



{ ---- painting -------------------------------------------------------------- }



procedure TFormMain.DetectionMarkersBoxPaint(Sender: TObject);
const
  BAR_HEIGHT = 3;
var
  Detections: TArray<TBatDetection>;
  I, Left, Right, W: Integer;
  DurationSec, Frac0, Frac1: Double;
  R: TRect;
begin
  { Docked alTop above (not overlapping) PaintBox, one row taller than the bar
    itself so a 1px margin separates it from the spectrogram below -- that
    margin row is left at clBtnFace (the form's own background) rather than
    the spectrogram's own fill color (clWindow, matching PaintBox/WaveformBox).
    Spans the full panel width, so the time axis is inset by the same
    LEFT_MARGIN/RIGHT_MARGIN PaintBox itself uses for its own time axis
    (SpectRect). }
  DetectionMarkersBox.Canvas.Brush.Color := StyleServices.GetSystemColor(clBtnFace);
  DetectionMarkersBox.Canvas.FillRect(DetectionMarkersBox.ClientRect);
  DetectionMarkersBox.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
  DetectionMarkersBox.Canvas.FillRect(Rect(0, 0, DetectionMarkersBox.Width, BAR_HEIGHT));
  if (FWavFile = nil) or (FZoomEnd <= FZoomStart) then
    Exit();
  DurationSec := FWavFile.Info.DurationSec;
  if DurationSec <= 0.0 then
    Exit();
  Detections := GetCurrentFileDetections();
  if Length(Detections) = 0 then
    Exit();
  Left := LEFT_MARGIN;
  Right := DetectionMarkersBox.Width - RIGHT_MARGIN;
  W := Right - Left;
  if W <= 0 then
    Exit();
  DetectionMarkersBox.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindowText);
  DetectionMarkersBox.Canvas.Pen.Style := psClear;
  for I := 0 to High(Detections) do begin
    Frac0 := (Detections[I].StartSec / DurationSec - FZoomStart) / (FZoomEnd - FZoomStart);
    Frac1 := (Detections[I].EndSec / DurationSec - FZoomStart) / (FZoomEnd - FZoomStart);
    if (Frac1 < 0.0) or (Frac0 > 1.0) then
      Continue;
    R := GetMarkerRect(Detections[I], DurationSec, Left, Right);
    if R.Right > R.Left then
      DetectionMarkersBox.Canvas.FillRect(Rect(R.Left, 0, R.Right, BAR_HEIGHT));
  end;
  DetectionMarkersBox.Canvas.Pen.Style := psSolid;
end;



procedure TFormMain.DetectionMarkersBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Detections: TArray<TBatDetection>;
  DurationSec: Double;
  Left, Right, I: Integer;
  R: TRect;
begin
  if (Button <> mbLeft) or (FWavFile = nil) or (FZoomEnd <= FZoomStart) then
    Exit();
  DurationSec := FWavFile.Info.DurationSec;
  if DurationSec <= 0.0 then
    Exit();
  Left := LEFT_MARGIN;
  Right := DetectionMarkersBox.Width - RIGHT_MARGIN;
  if Right - Left <= 0 then
    Exit();
  Detections := GetCurrentFileDetections();
  for I := 0 to High(Detections) do begin
    R := GetMarkerRect(Detections[I], DurationSec, Left, Right);
    if (X >= R.Left) and (X <= R.Right) then begin
      JumpToDetection(Detections[I]);
      Exit();
    end;
  end;
end;



procedure TFormMain.DetectionMarkersBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Detections: TArray<TBatDetection>;
  DurationSec: Double;
  Left, Right, I: Integer;
  R: TRect;
begin
  if (FWavFile = nil) or (FZoomEnd <= FZoomStart) then begin
    StatusBar.Panels[2].Text := '';
    Exit();
  end;
  DurationSec := FWavFile.Info.DurationSec;
  Left := LEFT_MARGIN;
  Right := DetectionMarkersBox.Width - RIGHT_MARGIN;
  if (DurationSec > 0.0) and (Right - Left > 0) then begin
    Detections := GetCurrentFileDetections();
    for I := 0 to High(Detections) do begin
      R := GetMarkerRect(Detections[I], DurationSec, Left, Right);
      if (X >= R.Left) and (X <= R.Right) then begin
        StatusBar.Panels[2].Text := Format('%s — %.1f%%',
          [TranslateSpeciesName(Detections[I].CommonName, FDisplayLanguage), Detections[I].Confidence * 100]);
        Exit();
      end;
    end;
  end;
  StatusBar.Panels[2].Text := '';
end;



procedure TFormMain.WaveformBoxPaint(Sender: TObject);
var
  Scheme: TColorScheme;
  VR, VG, VB: Byte;
  OuterColor, BgColor, WaveColor, AxisColor, GridColor: TColor;
  Samples: TArray<Single>;
  R: TRect;
  SelX1, SelX2: Integer;
begin
  Scheme := IdxToColorScheme(CbxColorScheme.ItemIndex);
  OuterColor := StyleServices.GetSystemColor(clWindow);
  AxisColor := StyleServices.GetSystemColor(clWindowText);
  GridColor := BlendColors(OuterColor, AxisColor, 0.3);
  if FSpecgram <> nil then begin
    FSpecgram.GetColor(0.0, Scheme, VR, VG, VB);
    BgColor := RGB(VR, VG, VB);
    FSpecgram.GetColor(1.0, Scheme, VR, VG, VB);
    WaveColor := RGB(VR, VG, VB);
  end else begin
    BgColor := OuterColor;
    WaveColor := $00BBBBBB;
  end;
  if FWavFile <> nil then
    Samples := FWavFile.Samples;
  R := WaveRect();
  PaintWaveform(WaveformBox.Canvas, WaveformBox.Width, WaveformBox.Height, R, Samples, FZoomStart, FZoomEnd, FCursorPos, OuterColor, BgColor, WaveColor,
    AxisColor, GridColor, AxisColor);
  if FDragging and (FDragCurrentX > FDragStartX) then begin
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    DrawSelectionOverlay(WaveformBox.Canvas, R, SelX1, SelX2);
  end;
end;



procedure TFormMain.PaintBoxPaint(Sender: TObject);
var
  R: TRect;
  W, H: Integer;
  Msg: string;
  SelX1, SelX2: Integer;
  AxisColor, GridColor: TColor;
  MX1, MY1, MX2, MY2: Integer;
  MeasureColor: TColor;
  DeltaTMs, DeltaFKhz: Double;
  SlopeText, ReadoutText: string;
begin
  R := SpectRect();
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;

  PaintBox.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  if FSpecgram = nil then begin
    Msg := 'Open an audio file to display the spectrogram';
    PaintBox.Canvas.Font.Color := StyleServices.GetSystemColor(clGrayText);
    PaintBox.Canvas.Font.Size := 12;
    PaintBox.Canvas.Brush.Style := bsClear;
    PaintBox.Canvas.TextOut(PaintBox.Width div 2 - PaintBox.Canvas.TextWidth(Msg) div 2, PaintBox.Height div 2 - PaintBox.Canvas.TextHeight(Msg) div 2, Msg);
    Exit();
  end;

  if (FDisplayBmp = nil) or (FDisplayBmp.Width <> W) or (FDisplayBmp.Height <> H) then
    RenderSpectrogram();

  if (FDisplayBmp <> nil) and (FDisplayBmp.Width > 0) then
    BitBlt(PaintBox.Canvas.Handle, R.Left, R.Top, W, H, FDisplayBmp.Canvas.Handle, 0, 0, SRCCOPY);

  AxisColor := StyleServices.GetSystemColor(clWindowText);
  if (W > 0) and (H > 0) then begin
    GridColor := BlendColors(StyleServices.GetSystemColor(clWindow), AxisColor, 0.3);
    if FWavFile <> nil then
      DrawSpectAxes(PaintBox.Canvas, R, FWavFile.Info.DurationSec, FMaxPlotHz, FZoomStart, FZoomEnd, AxisColor, GridColor);
    DrawSpectCursor(PaintBox.Canvas, R, FCursorPos, FZoomStart, FZoomEnd, AxisColor);
  end;

  if FDragging and (FDragCurrentX > FDragStartX) then begin
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    DrawSelectionOverlay(PaintBox.Canvas, R, SelX1, SelX2);
  end;

  if FHasMeasurement and (W > 0) and (H > 0) then begin
    MX1 := SecToSpectX(FMeasureStartSec, R);
    MY1 := HzToSpectY(FMeasureStartHz, R);
    MX2 := SecToSpectX(FMeasureEndSec, R);
    MY2 := HzToSpectY(FMeasureEndHz, R);
    MeasureColor := StyleServices.GetSystemColor(clWindowText);
    PaintBox.Canvas.Pen.Color := MeasureColor;
    PaintBox.Canvas.Pen.Width := 2;
    PaintBox.Canvas.MoveTo(MX1, MY1);
    PaintBox.Canvas.LineTo(MX2, MY2);
    PaintBox.Canvas.Pen.Width := 1;
    PaintBox.Canvas.Brush.Style := bsSolid;
    PaintBox.Canvas.Brush.Color := MeasureColor;
    PaintBox.Canvas.Ellipse(MX1 - 3, MY1 - 3, MX1 + 3, MY1 + 3);
    PaintBox.Canvas.Ellipse(MX2 - 3, MY2 - 3, MX2 + 3, MY2 + 3);

    DeltaTMs := Abs(FMeasureEndSec - FMeasureStartSec) * 1000.0;
    DeltaFKhz := Abs(FMeasureEndHz - FMeasureStartHz) / 1000.0;
    if DeltaTMs > 0.001 then
      SlopeText := Format('%.2f kHz/ms', [(FMeasureEndHz - FMeasureStartHz) / 1000.0 / DeltaTMs])
    else
      SlopeText := 'n/a';
    ReadoutText := Format(#$0394 + 't %.2f ms (duration)   ' + #$0394 + 'f %.1f kHz (bandwidth)   slope %s',
      [DeltaTMs, DeltaFKhz, SlopeText]);

    PaintBox.Canvas.Brush.Style := bsSolid;
    PaintBox.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    PaintBox.Canvas.Font.Color := AxisColor;
    PaintBox.Canvas.TextOut(R.Left + 6, R.Top + 4, ReadoutText);
  end;
end;



end.
