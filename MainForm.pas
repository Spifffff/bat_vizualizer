unit MainForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math, System.IOUtils, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ImgList,
  FFT, WavReader, Spectrogram, WaveOutPlayer, Mp3Writer,
  WaveformPainter, SpectrogramPainter, PngExport, BatSpeciesTranslations, System.ImageList;

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
    BtnOpenFile: TButton;
    BtnOpenFolder: TButton;
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
    BtnAutoFloor: TButton;
    BtnAutoCeiling: TButton;
    BtnAutoMaxFreq: TButton;
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
    BtnSaveMp3: TButton;
    SaveDialogMp3: TSaveDialog;
    PanelRight: TPanel;
    PanelFileContent: TPanel;
    CbxLanguage: TComboBox;
    FileListView: TListView;
    SplitterRight: TSplitter;
    ImageListButtons: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOpenFileClick(Sender: TObject);
    procedure BtnOpenFolderClick(Sender: TObject);
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
    procedure BtnAutoFloorClick(Sender: TObject);
    procedure BtnAutoCeilingClick(Sender: TObject);
    procedure BtnAutoMaxFreqClick(Sender: TObject);
    procedure RenderTimerTick(Sender: TObject);
    procedure ZoomBarChange(Sender: TObject);
    procedure BtnSaveMp3Click(Sender: TObject);
    procedure FileListViewClick(Sender: TObject);
    procedure FileListViewDblClick(Sender: TObject);
    procedure FileListViewResize(Sender: TObject);
    procedure FileListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure CbxLanguageChange(Sender: TObject);
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
    procedure ApplyZoomDrag(const ChartR: TRect);
    function GetFFTSize: Integer;
    function GetWindowType: TWindowType;
    function GetPlaybackRate: Double;
    procedure RecomputeSpectrogram;
    procedure RenderSpectrogram;
    procedure ScheduleRender;
    procedure ResetPlaybackUI;
    procedure UpdateZoomBar;
    type
      TRowKind = (rkSpecies, rkDetection);
      TRowData = record
        Kind: TRowKind;
        SpeciesIdx: Integer;
        FileIdx: Integer;
        DetIdx: Integer;
      end;
      PRowData = ^TRowData;
      TBatDetection = record
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
    function TryParseFileNameDateTime(const ABaseName: string; out ADateTime: TDateTime): Boolean;
    function GetFileFallbackDateTime(const AFilePath: string): TDateTime;
    procedure BuildSpeciesEntries;
    procedure BuildResultsList;
    procedure ClearFileListRowData;
    procedure ApplyResultsColumnWidths;
    procedure FitResultsColumns;
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
  PanelMain.ControlStyle := PanelMain.ControlStyle + [csOpaque];
  UpdateZoomBar();
  Application.OnMessage := AppMouseWheel;
  StatusBar.Panels[0].Text := 'Ready. Open an audio file.';
  FitResultsColumns();
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
  ClearFileListRowData();
end;

{ ---- file loading ---------------------------------------------------------- }



procedure TFormMain.LoadFile(const AFilePath: string);
begin
  Timer.Enabled := False;
  FWavePlayer.Stop();
  FCursorPos := -1;
  FreeAndNil(FSpecgram);
  FreeAndNil(FWavFile);
  BtnPlay.Enabled := False;
  BtnPause.Enabled := False;
  BtnStop.Enabled := False;
  FCurrentFilePath := '';
  Screen.Cursor := crHourGlass;
  Enabled := False;
  try
    try
      FWavFile := TWavFile.Create();
      FWavFile.LoadFromFile(AFilePath);
      FCurrentFilePath := AFilePath;
      FFileInfo := Format('%s  |  %.2f s  |  %d Hz  |  %d-bit  |  %d ch',
        [ExtractFileName(AFilePath), FWavFile.Info.DurationSec,
         FWavFile.Info.SampleRate, FWavFile.Info.BitsPerSample, FWavFile.Info.Channels]);
      StatusBar.Panels[0].Text := FFileInfo;
      RecomputeSpectrogram();
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
      BtnSaveMp3.Enabled := True;
      BtnAutoFloor.Enabled := True;
      BtnAutoCeiling.Enabled := True;
      BtnAutoMaxFreq.Enabled := True;
    except
      on E: Exception do begin
        FreeAndNil(FWavFile);
        FreeAndNil(FSpecgram);
        FCurrentFilePath := '';
        MessageDlg('Error loading file:'#13#10 + E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;



procedure TFormMain.BtnOpenFileClick(Sender: TObject);
begin
  if not OpenDialog.Execute() then
    Exit();
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
  FileListView.Columns[0].Width :=
    Max(MIN_TIMESTAMP_COL_WIDTH, FileListView.ClientWidth - CONFIDENCE_COL_WIDTH);
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
      if not (csDestroying in ComponentState) then
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
      Name := '';
      for K := 3 to High(Parts) - 1 do begin
        if K > 3 then Name := Name + ',';
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
    while (GroupEnd < High(ADetections))
      and (ADetections[GroupEnd + 1].CommonName = ADetections[GroupStart].CommonName)
      and (ADetections[GroupEnd + 1].StartSec <= ADetections[GroupEnd].EndSec + GAP_TOLERANCE_SEC) do
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
  Y, Mo, D, H, Mi, S: Integer;
begin
  Result := False;
  if (Length(ABaseName) <> 15) or (ABaseName[9] <> '_') then
    Exit();
  if not TryStrToInt(Copy(ABaseName, 1, 4), Y) then Exit();
  if not TryStrToInt(Copy(ABaseName, 5, 2), Mo) then Exit();
  if not TryStrToInt(Copy(ABaseName, 7, 2), D) then Exit();
  if not TryStrToInt(Copy(ABaseName, 10, 2), H) then Exit();
  if not TryStrToInt(Copy(ABaseName, 12, 2), Mi) then Exit();
  if not TryStrToInt(Copy(ABaseName, 14, 2), S) then Exit();
  Result := TryEncodeDateTime(Y, Mo, D, H, Mi, S, 0, ADateTime);
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
  end else
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
        CsvPath := ChangeFileExt(Entry.FilePath, '.bat.results.csv');
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
  TArray.Sort<TFlatDet>(Flat,
    TComparer<TFlatDet>.Construct(
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
  TArray.Sort<TSpeciesEntry>(FSpeciesEntries,
    TComparer<TSpeciesEntry>.Construct(
      function(const A, B: TSpeciesEntry): Integer
      begin
        Result := CompareText(
          TranslateSpeciesName(A.CommonName, FDisplayLanguage),
          TranslateSpeciesName(B.CommonName, FDisplayLanguage));
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
begin
  ClearFileListRowData;
  FileListView.Items.BeginUpdate;
  try
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
          Item.Caption := '    ' +
            LowerCase(FormatDateTime('d mmmm, hh:nn:ss', Det.DateTime, TFormatSettings.Invariant));
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
  finally
    FileListView.Items.EndUpdate;
  end;
  FitResultsColumns();
end;



procedure TFormMain.BtnOpenFolderClick(Sender: TObject);
var
  D: TFileOpenDialog;
begin
  D := TFileOpenDialog.Create(nil);
  try
    D.Options := [fdoPickFolders, fdoPathMustExist];
    if D.Execute then begin
      ScanFolderForFiles(ExcludeTrailingPathDelimiter(D.FileName));
      PanelRight.Visible := True;
      SplitterRight.Visible := True;
    end;
  finally
    D.Free;
  end;
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
  Det: TBatDetection;
  ZStart, ZEnd: Double;
begin
  Item := FileListView.Selected;
  if Item = nil then
    Exit();
  RD := PRowData(Item.Data);
  if (RD = nil) or (RD^.Kind <> rkDetection) then
    Exit();
  Entry := FFileEntries[RD^.FileIdx];
  Det := Entry.Detections[RD^.DetIdx];
  if FCurrentFilePath <> Entry.FilePath then
    LoadFile(Entry.FilePath);
  if FWavFile = nil then
    Exit();
  ZStart := (Det.StartSec - 0.5) / FWavFile.Info.DurationSec;
  ZEnd := (Det.EndSec + 0.5) / FWavFile.Info.DurationSec;
  FZoomStart := Max(0.0, ZStart);
  FZoomEnd := Min(1.0, ZEnd);
  if FZoomEnd <= FZoomStart then
    FZoomEnd := Min(1.0, FZoomStart + 0.01);
  UpdateZoomBar();
  RenderSpectrogram();
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;



{ ---- PNG export ------------------------------------------------------------ }



procedure TFormMain.BtnSavePNGClick(Sender: TObject);
var
  WavBmp, SpectBmp: TBitmap;
  Scheme: TColorScheme;
  VR, VG, VB: Byte;
  BgColor, WaveColor: TColor;
  Samples: TArray<Single>;
begin
  if FSpecgram = nil then
    Exit();
  if not SaveDialog.Execute() then
    Exit();
  Scheme := IdxToColorScheme(CbxColorScheme.ItemIndex);
  FSpecgram.GetColor(0.0, Scheme, VR, VG, VB);
  BgColor := RGB(VR, VG, VB);
  FSpecgram.GetColor(1.0, Scheme, VR, VG, VB);
  WaveColor := RGB(VR, VG, VB);
  Samples := FWavFile.Samples;
  WavBmp := TBitmap.Create();
  SpectBmp := TBitmap.Create();
  try
    WavBmp.PixelFormat := pf24bit;
    WavBmp.Width  := WaveformBox.Width;
    WavBmp.Height := WaveformBox.Height;
    PaintWaveform(WavBmp.Canvas, WavBmp.Width, WavBmp.Height,
      Rect(LEFT_MARGIN, WAVE_VPAD, WavBmp.Width - RIGHT_MARGIN, WavBmp.Height - WAVE_VPAD),
      Samples, FZoomStart, FZoomEnd, FCursorPos, BgColor, WaveColor);
    SpectBmp.PixelFormat := pf24bit;
    SpectBmp.Width  := PaintBox.Width;
    SpectBmp.Height := PaintBox.Height;
    FDragging := False;
    WaveformBox.Invalidate();
    PaintBox.Perform(WM_PAINT, WPARAM(SpectBmp.Canvas.Handle), 0);
    try
      SavePng(WavBmp, SpectBmp, CbxSaveTarget.ItemIndex, SaveDialog.FileName);
    except
      on E: Exception do
        MessageDlg('Error saving PNG:'#13#10 + E.Message, mtError, [mbOK], 0);
    end;
  finally
    WavBmp.Free();
    SpectBmp.Free();
  end;
end;



{ ---- MP3 export ------------------------------------------------------------ }



procedure TFormMain.BtnSaveMp3Click(Sender: TObject);
var
  DesiredRate, ActualRate: Cardinal;
begin
  if FWavFile = nil then
    Exit();
  if not SaveDialogMp3.Execute() then
    Exit();
  DesiredRate := Round(FWavFile.Info.SampleRate * GetPlaybackRate());
  Screen.Cursor := crHourGlass;
  try
    try
      SaveMp3(FWavFile.Samples, FZoomStart, FZoomEnd, SaveDialogMp3.FileName, DesiredRate, ActualRate);
      StatusBar.Panels[0].Text := Format('MP3 saved — %d Hz (%.1f%% speed)',
        [ActualRate, DesiredRate / FWavFile.Info.SampleRate * 100]);
    except
      on E: Exception do
        MessageDlg('Error saving MP3:'#13#10 + E.Message, mtError, [mbOK], 0);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;



{ ---- playback controls ----------------------------------------------------- }



procedure TFormMain.BtnPlayClick(Sender: TObject);
var
  OutRate, ActualRate: Cardinal;
  StartSample, EndSample: Integer;
begin
  if FWavFile = nil then
    Exit();
  try
    if FWavePlayer.IsPaused() then
      FWavePlayer.Resume()
    else begin
      OutRate := Round(FWavFile.Info.SampleRate * GetPlaybackRate());
      { Only load/convert the current zoom window, not the whole file --
        for a large recording zoomed into a single call, this keeps the
        16-bit playback buffer from ballooning to the size of the entire
        (possibly multi-hour) file. Playback also now stops at the zoom
        end instead of continuing into the rest of the file. }
      StartSample := EnsureRange(Round(FZoomStart * FWavFile.Info.NumSamples), 0, FWavFile.Info.NumSamples);
      EndSample := EnsureRange(Round(FZoomEnd * FWavFile.Info.NumSamples), StartSample, FWavFile.Info.NumSamples);
      FWavePlayer.Load(FWavFile.Samples, StartSample, EndSample, OutRate, ActualRate);
      FWavePlayer.Play();
      FCursorPos := FZoomStart;
      if ActualRate <> OutRate then
        StatusBar.Panels[0].Text := Format('Requested %d Hz, using %d Hz (%.1f%% speed)', [OutRate, ActualRate, ActualRate / FWavFile.Info.SampleRate * 100])
      else
        StatusBar.Panels[0].Text := Format('%d Hz  |  %.1f%% speed', [ActualRate, GetPlaybackRate() * 100]);
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
    FCursorPos := -1;
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



procedure TFormMain.BtnAutoFloorClick(Sender: TObject);
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  TrkFloor.Position := EnsureRange(Round(FSpecgram.AutoFloorDB), TrkFloor.Min, TrkFloor.Max);
  TrkFloorChange(TrkFloor);
end;



procedure TFormMain.BtnAutoCeilingClick(Sender: TObject);
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  TrkCeiling.Position := EnsureRange(Round(FSpecgram.AutoCeilingDB), TrkCeiling.Min, TrkCeiling.Max);
  TrkCeilingChange(TrkCeiling);
end;



procedure TFormMain.BtnAutoMaxFreqClick(Sender: TObject);
begin
  if (FWavFile = nil) or (FSpecgram = nil) then
    Exit();
  TrkMaxFreq.Position := EnsureRange(Round(FSpecgram.AutoMaxFreqHz / 1000.0), TrkMaxFreq.Min, TrkMaxFreq.Max);
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



procedure TFormMain.ApplyZoomDrag(const ChartR: TRect);
var
  W, SelX1, SelX2: Integer;
  Frac1, Frac2, ClickFrac: Double;
begin
  W := Max(1, ChartR.Right - ChartR.Left);

  if Abs(FDragCurrentX - FDragStartX) < 4 then begin
    ClickFrac := FZoomStart + (Max(ChartR.Left, Min(ChartR.Right, FDragStartX)) - ChartR.Left) / W * (FZoomEnd - FZoomStart);
    FCursorPos := ClickFrac;
    if FWavePlayer.IsPlaying() or FWavePlayer.IsPaused() then
      FWavePlayer.SeekToNormalized(ClickFrac);
  end
  else if FDragCurrentX > FDragStartX then begin
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
  end
  else begin
    FZoomStart := 0.0;
    FZoomEnd := 1.0;
    UpdateZoomBar();
    RenderSpectrogram();
  end;
  PaintBox.Invalidate();
  WaveformBox.Invalidate();
end;



procedure TFormMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or not FDragging then
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
  InPaintBox: Boolean;
  Frac, T, Span, NewSpan, NewStart, NewEnd, ZoomFactor: Double;
begin
  if Msg.message <> WM_MOUSEWHEEL then
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
  WheelDelta := SmallInt(Msg.wParam shr 16);
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
  if (Button <> mbLeft) or not FDragging then
    Exit();
  FDragging := False;
  ApplyZoomDrag(WaveRect());
end;



{ ---- painting -------------------------------------------------------------- }



procedure TFormMain.WaveformBoxPaint(Sender: TObject);
var
  Scheme: TColorScheme;
  VR, VG, VB: Byte;
  BgColor, WaveColor: TColor;
  Samples: TArray<Single>;
  R: TRect;
  SelX1, SelX2: Integer;
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
  if FWavFile <> nil then
    Samples := FWavFile.Samples;
  R := WaveRect();
  PaintWaveform(WaveformBox.Canvas, WaveformBox.Width, WaveformBox.Height, R,
    Samples, FZoomStart, FZoomEnd, FCursorPos, BgColor, WaveColor);
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

  if (W > 0) and (H > 0) then begin
    if FWavFile <> nil then
      DrawSpectAxes(PaintBox.Canvas, R, FWavFile.Info.DurationSec, FMaxPlotHz, FZoomStart, FZoomEnd);
    DrawSpectCursor(PaintBox.Canvas, R, FCursorPos, FZoomStart, FZoomEnd);
  end;

  if FDragging and (FDragCurrentX > FDragStartX) then begin
    SelX1 := Max(R.Left, Min(R.Right, FDragStartX));
    SelX2 := Max(R.Left, Min(R.Right, FDragCurrentX));
    DrawSelectionOverlay(PaintBox.Canvas, R, SelX1, SelX2);
  end;
end;



end.
