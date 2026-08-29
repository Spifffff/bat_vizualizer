unit BatIdentForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl;

const
  MAX_SLOTS = 64;

type
  TSlotState = (ssIdle, ssBatIdent);

  TFileSlot = record
    WavFile: string;
    BaseName: string;
    OutCsv: string;
    ProcessHandle: THandle;
    StdOutRead: THandle;
    PipeBuffer: string;
    State: TSlotState;
  end;

  TFormBatIdent = class(TForm)
    GrpFolders: TGroupBox;
    LblWavFolder: TLabel;
    EdtWavFolder: TEdit;
    BtnBrowseWav: TButton;
    LblOutputFolder: TLabel;
    EdtOutputFolder: TEdit;
    BtnBrowseOutput: TButton;
    LblBattyFolder: TLabel;
    EdtBattyFolder: TEdit;
    BtnBrowseBatty: TButton;
    GrpParams: TGroupBox;
    LblArea: TLabel;
    CbxArea: TComboBox;
    LblKHz: TLabel;
    CbxKHz: TComboBox;
    LblParallel: TLabel;
    CbxParallel: TComboBox;
    LblMinConf: TLabel;
    EdtMinConf: TEdit;
    LblSfThresh: TLabel;
    EdtSfThresh: TEdit;
    LblSensitivity: TLabel;
    EdtSensitivity: TEdit;
    PrgBar: TProgressBar;
    MemoLog: TMemo;
    BtnStart: TButton;
    BtnStop: TButton;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure BtnBrowseWavClick(Sender: TObject);
    procedure BtnBrowseOutputClick(Sender: TObject);
    procedure BtnBrowseBattyClick(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FSlots: array[0..MAX_SLOTS - 1] of TFileSlot;
    FSlotCount: Integer;
    FPendingFiles: TStringList;
    FPendingIdx: Integer;
    FTotalFiles: Integer;
    FDoneCount: Integer;
    FRunning: Boolean;
    procedure Log(const Msg: string);
    procedure StartProcessing();
    procedure StopAll();
    procedure FillSlot(SlotIdx: Integer);
    procedure AdvanceSlot(SlotIdx: Integer);
    procedure LaunchBatIdent(SlotIdx: Integer);
    procedure FinishSlot(SlotIdx: Integer);
    procedure DrainSlotPipe(SlotIdx: Integer);
    procedure CloseSlotPipe(SlotIdx: Integer);
    function CsvExists(const OutCsv: string): Boolean;
    function LaunchProcess(const CmdLine: string; out PipeRead: THandle): THandle;
    function ValidateInputs(): Boolean;
    procedure SetControlsEnabled(AEnabled: Boolean);
  public
    WAVFolder: string;
    OutputFolder: string;
  end;

var
  FormBatIdent: TFormBatIdent;

implementation

{$R *.dfm}

procedure TFormBatIdent.FormCreate(Sender: TObject);
var
  SI: TSystemInfo;
  CPUCount, I: Integer;
begin
  CbxArea.Items.AddStrings(['Bavaria', 'EU', 'UK', 'USA', 'USA-EAST', 'USA-WEST']);
  CbxArea.ItemIndex := 0;
  CbxKHz.Items.AddStrings(['144', '256']);
  CbxKHz.ItemIndex := 1;
  GetSystemInfo(SI);
  CPUCount := SI.dwNumberOfProcessors;
  for I := 1 to CPUCount do
    CbxParallel.Items.Add(IntToStr(I));
  CbxParallel.ItemIndex := Min(3, CPUCount - 1);
  FPendingFiles := TStringList.Create();
  FRunning := False;
end;

procedure TFormBatIdent.FormShow(Sender: TObject);
begin
  if (WAVFolder <> '') and (EdtWavFolder.Text = '') then
  begin
    EdtWavFolder.Text := WAVFolder;
    EdtOutputFolder.Text := WAVFolder + '\output';
  end;
end;

procedure TFormBatIdent.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FRunning then
    StopAll();
  OutputFolder := EdtOutputFolder.Text;
end;

procedure TFormBatIdent.FormDestroy(Sender: TObject);
begin
  FPendingFiles.Free();
end;

procedure TFormBatIdent.Log(const Msg: string);
begin
  MemoLog.Lines.Add(Msg);
  SendMessage(MemoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TFormBatIdent.BtnBrowseWavClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := EdtWavFolder.Text;
  if SelectDirectory('Select WAV folder', '', Dir) then
  begin
    EdtWavFolder.Text := Dir;
    if EdtOutputFolder.Text = '' then
      EdtOutputFolder.Text := Dir + '\output';
  end;
end;

procedure TFormBatIdent.BtnBrowseOutputClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := EdtOutputFolder.Text;
  if SelectDirectory('Select output folder', '', Dir) then
    EdtOutputFolder.Text := Dir;
end;

procedure TFormBatIdent.BtnBrowseBattyClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := EdtBattyFolder.Text;
  if SelectDirectory('Select BattyBirdNET folder', '', Dir) then
    EdtBattyFolder.Text := Dir;
end;

function TFormBatIdent.ValidateInputs(): Boolean;
begin
  Result := False;
  if EdtWavFolder.Text = '' then
  begin
    MessageDlg('Please select a WAV folder.', mtError, [mbOK], 0);
    Exit();
  end;
  if not DirectoryExists(EdtWavFolder.Text) then
  begin
    MessageDlg('WAV folder does not exist.', mtError, [mbOK], 0);
    Exit();
  end;
  if EdtBattyFolder.Text = '' then
  begin
    MessageDlg('Please select the BattyBirdNET folder.', mtError, [mbOK], 0);
    Exit();
  end;
  if not FileExists(EdtBattyFolder.Text + '\bat_ident.py') then
  begin
    MessageDlg('bat_ident.py not found in the BattyBirdNET folder.', mtError, [mbOK], 0);
    Exit();
  end;
  Result := True;
end;

procedure TFormBatIdent.SetControlsEnabled(AEnabled: Boolean);
begin
  BtnStart.Enabled := AEnabled;
  BtnStop.Enabled := not AEnabled;
  EdtWavFolder.Enabled := AEnabled;
  BtnBrowseWav.Enabled := AEnabled;
  EdtOutputFolder.Enabled := AEnabled;
  BtnBrowseOutput.Enabled := AEnabled;
  EdtBattyFolder.Enabled := AEnabled;
  BtnBrowseBatty.Enabled := AEnabled;
  CbxArea.Enabled := AEnabled;
  CbxKHz.Enabled := AEnabled;
  CbxParallel.Enabled := AEnabled;
  EdtMinConf.Enabled := AEnabled;
  EdtSfThresh.Enabled := AEnabled;
  EdtSensitivity.Enabled := AEnabled;
end;

function TFormBatIdent.LaunchProcess(const CmdLine: string; out PipeRead: THandle): THandle;
var
  SA: TSecurityAttributes;
  PipeWrite, NulHandle: THandle;
  SI: TStartupInfo;
  PI: TProcessInformation;
  Cmd: string;
  Err: DWORD;
begin
  Result := INVALID_HANDLE_VALUE;
  PipeRead := INVALID_HANDLE_VALUE;
  SA.nLength := SizeOf(SA);
  SA.lpSecurityDescriptor := nil;
  SA.bInheritHandle := True;
  if not CreatePipe(PipeRead, PipeWrite, @SA, 0) then
  begin
    OutputDebugString('[BatIdent] CreatePipe failed');
    Exit();
  end;
  SetHandleInformation(PipeRead, HANDLE_FLAG_INHERIT, 0);
  NulHandle := CreateFile('nul', GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, @SA, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Cmd := CmdLine;
  OutputDebugString(PChar('[BatIdent] CMD: ' + Cmd));
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  SI.wShowWindow := SW_HIDE;
  SI.hStdInput := NulHandle;
  SI.hStdOutput := PipeWrite;
  SI.hStdError := PipeWrite;
  if CreateProcess(nil, PChar(Cmd), nil, nil, True,
    CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, nil, SI, PI) then
  begin
    CloseHandle(PI.hThread);
    CloseHandle(PipeWrite);
    if NulHandle <> INVALID_HANDLE_VALUE then
      CloseHandle(NulHandle);
    Result := PI.hProcess;
    OutputDebugString(PChar('[BatIdent] launched PID=' + IntToStr(PI.dwProcessId)));
  end
  else
  begin
    Err := GetLastError();
    CloseHandle(PipeWrite);
    if NulHandle <> INVALID_HANDLE_VALUE then
      CloseHandle(NulHandle);
    CloseHandle(PipeRead);
    PipeRead := INVALID_HANDLE_VALUE;
    OutputDebugString(PChar('[BatIdent] CreateProcess failed, error=' + IntToStr(Err)));
  end;
end;

procedure TFormBatIdent.DrainSlotPipe(SlotIdx: Integer);
var
  Available, BytesRead: DWORD;
  Buf: array[0..4095] of AnsiChar;
  P: Integer;
  Line: string;
begin
  if FSlots[SlotIdx].StdOutRead = INVALID_HANDLE_VALUE then
    Exit();
  while PeekNamedPipe(FSlots[SlotIdx].StdOutRead, nil, 0, nil, @Available, nil)
    and (Available > 0) do
  begin
    FillChar(Buf, SizeOf(Buf), 0);
    if not ReadFile(FSlots[SlotIdx].StdOutRead,
      Buf[0], Min(Available, DWORD(SizeOf(Buf) - 1)), BytesRead, nil) then
      Break;
    if BytesRead = 0 then
      Break;
    FSlots[SlotIdx].PipeBuffer :=
      FSlots[SlotIdx].PipeBuffer + string(AnsiString(PAnsiChar(@Buf[0])));
  end;
  repeat
    P := Pos(#10, FSlots[SlotIdx].PipeBuffer);
    if P = 0 then
      Break;
    Line := Copy(FSlots[SlotIdx].PipeBuffer, 1, P - 1);
    Delete(FSlots[SlotIdx].PipeBuffer, 1, P);
    Line := StringReplace(Line, #13, '', [rfReplaceAll]);
    Line := Trim(Line);
    if Line <> '' then
      Log('[' + FSlots[SlotIdx].BaseName + '] ' + Line);
  until False;
end;

procedure TFormBatIdent.CloseSlotPipe(SlotIdx: Integer);
begin
  if FSlots[SlotIdx].StdOutRead <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FSlots[SlotIdx].StdOutRead);
    FSlots[SlotIdx].StdOutRead := INVALID_HANDLE_VALUE;
  end;
  FSlots[SlotIdx].PipeBuffer := '';
end;

function TFormBatIdent.CsvExists(const OutCsv: string): Boolean;
begin
  Result := FileExists(OutCsv);
end;

procedure TFormBatIdent.LaunchBatIdent(SlotIdx: Integer);
var
  Cmd: string;
begin
  ForceDirectories(EdtOutputFolder.Text);
  Cmd := 'python3 "' + EdtBattyFolder.Text + '\bat_ident.py"' +
    ' --i "' + FSlots[SlotIdx].WavFile + '"' +
    ' --o "' + FSlots[SlotIdx].OutCsv + '"' +
    ' --kHz ' + CbxKHz.Text +
    ' --area ' + CbxArea.Text +
    ' --sensitivity ' + EdtSensitivity.Text +
    ' --min_conf ' + EdtMinConf.Text +
    ' --sf_thresh ' + EdtSfThresh.Text +
    ' --threads 1';
  Log('Processing: ' + FSlots[SlotIdx].BaseName);
  FSlots[SlotIdx].ProcessHandle := LaunchProcess(Cmd, FSlots[SlotIdx].StdOutRead);
  if FSlots[SlotIdx].ProcessHandle = INVALID_HANDLE_VALUE then
  begin
    Log('Error: could not start bat_ident for ' + FSlots[SlotIdx].BaseName);
    FSlots[SlotIdx].State := ssIdle;
    Inc(FDoneCount);
    PrgBar.Position := FDoneCount;
    Exit();
  end;
  FSlots[SlotIdx].State := ssBatIdent;
end;

procedure TFormBatIdent.FinishSlot(SlotIdx: Integer);
begin
  Log('Finished: ' + FSlots[SlotIdx].BaseName);
  FSlots[SlotIdx].State := ssIdle;
  Inc(FDoneCount);
  PrgBar.Position := FDoneCount;
end;

procedure TFormBatIdent.AdvanceSlot(SlotIdx: Integer);
begin
  if FSlots[SlotIdx].State = ssBatIdent then
    FinishSlot(SlotIdx);
end;

procedure TFormBatIdent.FillSlot(SlotIdx: Integer);
var
  WavFile, BaseName, OutCsv, OutputDir: string;
begin
  if FPendingIdx >= FPendingFiles.Count then
    Exit();
  WavFile := FPendingFiles[FPendingIdx];
  Inc(FPendingIdx);
  BaseName := ChangeFileExt(ExtractFileName(WavFile), '');
  OutputDir := EdtOutputFolder.Text;
  OutCsv := OutputDir + '\' + BaseName + '.bat.results.csv';
  FSlots[SlotIdx].WavFile := WavFile;
  FSlots[SlotIdx].BaseName := BaseName;
  FSlots[SlotIdx].OutCsv := OutCsv;
  FSlots[SlotIdx].ProcessHandle := INVALID_HANDLE_VALUE;
  FSlots[SlotIdx].StdOutRead := INVALID_HANDLE_VALUE;
  FSlots[SlotIdx].PipeBuffer := '';
  if CsvExists(OutCsv) then
  begin
    Log('Skipped: ' + BaseName);
    FSlots[SlotIdx].State := ssIdle;
    Inc(FDoneCount);
    PrgBar.Position := FDoneCount;
    Exit();
  end;
  LaunchBatIdent(SlotIdx);
end;

procedure TFormBatIdent.StartProcessing();
var
  SR: TSearchRec;
  WavDir: string;
  I, ParallelCount: Integer;
begin
  if not ValidateInputs() then
    Exit();
  WavDir := ExcludeTrailingPathDelimiter(EdtWavFolder.Text);
  ForceDirectories(EdtOutputFolder.Text);
  FPendingFiles.Clear();
  if FindFirst(WavDir + '\*.wav', faAnyFile - faDirectory, SR) = 0 then
  try
    repeat
      FPendingFiles.Add(WavDir + '\' + SR.Name);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
  if FPendingFiles.Count = 0 then
  begin
    MessageDlg('No WAV files found in the selected folder.', mtError, [mbOK], 0);
    Exit();
  end;
  FTotalFiles := FPendingFiles.Count;
  FPendingIdx := 0;
  FDoneCount := 0;
  FRunning := True;
  PrgBar.Min := 0;
  PrgBar.Max := FTotalFiles;
  PrgBar.Position := 0;
  MemoLog.Clear();
  ParallelCount := CbxParallel.ItemIndex + 1;
  FSlotCount := ParallelCount;
  for I := 0 to FSlotCount - 1 do
  begin
    FSlots[I].State := ssIdle;
    FSlots[I].ProcessHandle := INVALID_HANDLE_VALUE;
    FSlots[I].StdOutRead := INVALID_HANDLE_VALUE;
    FSlots[I].PipeBuffer := '';
  end;
  SetControlsEnabled(False);
  for I := 0 to FSlotCount - 1 do
    FillSlot(I);
  Timer.Enabled := True;
end;

procedure TFormBatIdent.StopAll();
var
  I: Integer;
begin
  Timer.Enabled := False;
  for I := 0 to FSlotCount - 1 do
  begin
    if (FSlots[I].State = ssBatIdent) and
      (FSlots[I].ProcessHandle <> INVALID_HANDLE_VALUE) then
    begin
      TerminateProcess(FSlots[I].ProcessHandle, 0);
      CloseHandle(FSlots[I].ProcessHandle);
      FSlots[I].ProcessHandle := INVALID_HANDLE_VALUE;
    end;
    CloseSlotPipe(I);
    FSlots[I].State := ssIdle;
  end;
  FRunning := False;
  SetControlsEnabled(True);
  Log('Stopped.');
end;

procedure TFormBatIdent.TimerTimer(Sender: TObject);
var
  I: Integer;
  ExitCode: DWORD;
  AllDone: Boolean;
begin
  for I := 0 to FSlotCount - 1 do
    if FSlots[I].State = ssBatIdent then
      DrainSlotPipe(I);
  for I := 0 to FSlotCount - 1 do
  begin
    if (FSlots[I].State = ssBatIdent) and
      (FSlots[I].ProcessHandle <> INVALID_HANDLE_VALUE) then
    begin
      if WaitForSingleObject(FSlots[I].ProcessHandle, 0) = WAIT_OBJECT_0 then
      begin
        ExitCode := 0;
        GetExitCodeProcess(FSlots[I].ProcessHandle, ExitCode);
        OutputDebugString(PChar('[BatIdent] ' + FSlots[I].BaseName +
          ' state=' + IntToStr(Ord(FSlots[I].State)) + ' exitcode=' + IntToStr(ExitCode)));
        CloseHandle(FSlots[I].ProcessHandle);
        FSlots[I].ProcessHandle := INVALID_HANDLE_VALUE;
        DrainSlotPipe(I);
        CloseSlotPipe(I);
        AdvanceSlot(I);
      end;
    end;
  end;
  for I := 0 to FSlotCount - 1 do
    while (FSlots[I].State = ssIdle) and (FPendingIdx < FPendingFiles.Count) do
      FillSlot(I);
  AllDone := FPendingIdx >= FPendingFiles.Count;
  if AllDone then
    for I := 0 to FSlotCount - 1 do
      if FSlots[I].State <> ssIdle then
      begin
        AllDone := False;
        Break;
      end;
  if AllDone then
  begin
    Timer.Enabled := False;
    FRunning := False;
    SetControlsEnabled(True);
    PrgBar.Position := PrgBar.Max;
    Log('Done. Processed ' + IntToStr(FDoneCount) + ' of ' + IntToStr(FTotalFiles) + ' files.');
  end;
end;

procedure TFormBatIdent.BtnStartClick(Sender: TObject);
begin
  StartProcessing();
end;

procedure TFormBatIdent.BtnStopClick(Sender: TObject);
begin
  StopAll();
end;

end.
