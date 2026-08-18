unit WaveOutPlayer;

{ Plays audio via the Windows waveOut API at an arbitrary output sample rate.
  All MMSystem types and function imports are declared locally so that this
  unit compiles regardless of how Winapi.MMSystem defines them. }



interface



uses
  Winapi.Windows,
  System.SysUtils;

type
  TWaveOutPlayer = class
  private
    FDevHandle: THandle;
    FWaveHdrBuf: array [0 .. 63] of Byte; // enough for WAVEHDR on 32-bit
    FBuffer: TArray<SmallInt>;
    FTotalSamples: Integer;
    FSeekOffset: Integer;
    FActualRate: Cardinal;
    FLoaded: Boolean;
    FSubmitted: Boolean;
    FPaused: Boolean;

    procedure CloseDevice;
    function WavHdrFlags: DWORD;
  public
    destructor Destroy; override;

    { Convert samples to 16-bit and open the device at RequestedRate Hz
      (= SrcRate * PlaybackRate, e.g. 19 200 for 192 000 * 0.1).
      ActualRate is set to the rate that Windows accepted. }
    procedure Load(const Samples: TArray<Single>; RequestedRate: Cardinal; out ActualRate: Cardinal);

    procedure Play;
    procedure Pause;
    procedure Resume;
    procedure Stop;

    { Seek to a normalised position 0..1; restarts playback from that point
      if the device was playing or paused. }
    procedure SeekToNormalized(Pos: Double);

    { Normalised position 0..1 (samples consumed / total samples). }
    function GetNormalizedPosition: Double;

    { State queries. }
    function IsPlaying: Boolean;
    function IsPaused: Boolean;
    function HasEnded: Boolean;

    property ActualRate: Cardinal read FActualRate;
    property TotalSamples: Integer read FTotalSamples;
  end;



implementation



{ =========================================================================
  Minimal MMSystem declarations — avoids dependency on Winapi.MMSystem.
  ========================================================================= }

const
  WinmmDll = 'winmm.dll';
  WAVE_MAPPER = UINT($FFFFFFFF);
  WAVE_FORMAT_PCM = 1;
  MMSYSERR_NOERROR = 0;
  CALLBACK_NULL = DWORD(0);
  TIME_SAMPLES = $0002;
  WHDR_DONE = $00000001;
  WHDR_PREPARED = $00000002;
  WHDR_INQUEUE = $00000010;

type
  MMRESULT = UINT;
  HWAVEOUT = THandle;
  PHWAVEOUT = ^HWAVEOUT;



  TWaveFormatEx = packed record
    wFormatTag: Word;
    nChannels: Word;
    nSamplesPerSec: DWORD;
    nAvgBytesPerSec: DWORD;
    nBlockAlign: Word;
    wBitsPerSample: Word;
    cbSize: Word;
  end;



  PWaveFormatEx = ^TWaveFormatEx;



  { 32-bit layout of WAVEHDR (32 bytes). }
  TWaveHdr = packed record
    lpData: PAnsiChar;
    dwBufferLength: DWORD;
    dwBytesRecorded: DWORD;
    dwUser: NativeUInt;
    dwFlags: DWORD;
    dwLoops: DWORD;
    lpNext: Pointer;
    reserved: NativeUInt;
  end;



  PWaveHdr = ^TWaveHdr;



  { MMTIME — only the fields we use (wType + 4-byte value). }
  TMMTime = packed record
    wType: UINT;
    sample: DWORD; // overlaps ms / cb / ticks / ...
    _pad: array [0 .. 3] of Byte; // enough to match Windows struct size
  end;



  PMMTime = ^TMMTime;

function waveOutOpen(phwo: PHWAVEOUT; uDeviceID: UINT; lpFormat: PWaveFormatEx; dwCallback, dwCallbackInstance: NativeUInt; fdwOpen: DWORD): MMRESULT; stdcall;
  external WinmmDll;

function waveOutClose(hwo: HWAVEOUT): MMRESULT; stdcall; external WinmmDll;

function waveOutPrepareHeader(hwo: HWAVEOUT; pwh: PWaveHdr; cbwh: UINT): MMRESULT; stdcall; external WinmmDll;

function waveOutUnprepareHeader(hwo: HWAVEOUT; pwh: PWaveHdr; cbwh: UINT): MMRESULT; stdcall; external WinmmDll;

function waveOutWrite(hwo: HWAVEOUT; pwh: PWaveHdr; cbwh: UINT): MMRESULT; stdcall; external WinmmDll;

function waveOutReset(hwo: HWAVEOUT): MMRESULT; stdcall; external WinmmDll;

function waveOutPause(hwo: HWAVEOUT): MMRESULT; stdcall; external WinmmDll;

function waveOutRestart(hwo: HWAVEOUT): MMRESULT; stdcall; external WinmmDll;

function waveOutGetPosition(hwo: HWAVEOUT; pmmt: PMMTime; cbmmt: UINT): MMRESULT; stdcall; external WinmmDll;

{ =========================================================================
  TWaveOutPlayer
  ========================================================================= }



function TWaveOutPlayer.WavHdrFlags: DWORD;
begin
  Result := PWaveHdr(@FWaveHdrBuf)^.dwFlags;
end;



procedure TWaveOutPlayer.CloseDevice;
var
  H: PWaveHdr;
begin
  if FDevHandle = 0 then
    Exit;
  H := PWaveHdr(@FWaveHdrBuf);
  waveOutReset(FDevHandle);
  if FLoaded then begin
    waveOutUnprepareHeader(FDevHandle, H, SizeOf(TWaveHdr));
    FLoaded := False;
  end;
  waveOutClose(FDevHandle);
  FDevHandle := 0;
  FSubmitted := False;
  FPaused := False;
end;



destructor TWaveOutPlayer.Destroy;
begin
  CloseDevice;
  inherited;
end;



procedure TWaveOutPlayer.Load(const Samples: TArray<Single>; RequestedRate: Cardinal; out ActualRate: Cardinal);
const
  Fallbacks: array [0 .. 3] of Cardinal = (22050, 16000, 11025, 44100);
var
  Fmt: TWaveFormatEx;
  H: PWaveHdr;
  Res: MMRESULT;
  I, V: Integer;
  Rate: Cardinal;
begin
  CloseDevice;

  FTotalSamples := Length(Samples);
  if FTotalSamples = 0 then
    raise Exception.Create('No samples to load.');

  { Float -1..1 → Int16. }
  SetLength(FBuffer, FTotalSamples);
  for I := 0 to FTotalSamples - 1 do begin
    V := Round(Samples[I] * 32767.0);
    if V > 32767 then
      V := 32767;
    if V < -32768 then
      V := -32768;
    FBuffer[I] := SmallInt(V);
  end;

  { Try RequestedRate first, then fallbacks. }
  Rate := RequestedRate;
  FDevHandle := 0;

  for I := -1 to High(Fallbacks) do begin
    if I >= 0 then
      Rate := Fallbacks[I];

    FillChar(Fmt, SizeOf(Fmt), 0);
    Fmt.wFormatTag := WAVE_FORMAT_PCM;
    Fmt.nChannels := 1;
    Fmt.nSamplesPerSec := Rate;
    Fmt.wBitsPerSample := 16;
    Fmt.nBlockAlign := 2;
    Fmt.nAvgBytesPerSec := Rate * 2;
    Fmt.cbSize := 0;

    Res := waveOutOpen(@FDevHandle, WAVE_MAPPER, @Fmt, 0, 0, CALLBACK_NULL);
    if Res = MMSYSERR_NOERROR then
      Break;
    FDevHandle := 0;
    if I = High(Fallbacks) then
      raise Exception.CreateFmt('Cannot open audio output (last error %d). No supported sample rate found.', [Res]);
  end;

  FActualRate := Rate;
  ActualRate := Rate;
  FSeekOffset := 0;

  { Prepare the header for the entire buffer. }
  H := PWaveHdr(@FWaveHdrBuf);
  FillChar(H^, SizeOf(TWaveHdr), 0);
  H^.lpData := PAnsiChar(@FBuffer[0]);
  H^.dwBufferLength := DWORD(FTotalSamples * SizeOf(SmallInt));

  Res := waveOutPrepareHeader(FDevHandle, H, SizeOf(TWaveHdr));
  if Res <> MMSYSERR_NOERROR then begin
    CloseDevice;
    raise Exception.CreateFmt('waveOutPrepareHeader failed (error %d).', [Res]);
  end;
  FLoaded := True;
end;



procedure TWaveOutPlayer.Play;
var
  Res: MMRESULT;
begin
  if not FLoaded then
    Exit;
  Res := waveOutWrite(FDevHandle, PWaveHdr(@FWaveHdrBuf), SizeOf(TWaveHdr));
  if Res <> MMSYSERR_NOERROR then
    raise Exception.CreateFmt('waveOutWrite failed (error %d).', [Res]);
  FSubmitted := True;
  FPaused := False;
end;



procedure TWaveOutPlayer.Pause;
begin
  if FDevHandle = 0 then
    Exit;
  waveOutPause(FDevHandle);
  FPaused := True;
end;



procedure TWaveOutPlayer.Resume;
begin
  if FDevHandle = 0 then
    Exit;
  waveOutRestart(FDevHandle);
  FPaused := False;
end;



procedure TWaveOutPlayer.Stop;
begin
  CloseDevice;
  SetLength(FBuffer, 0);
  FTotalSamples := 0;
  FActualRate := 0;
end;



function TWaveOutPlayer.GetNormalizedPosition: Double;
var
  MMT: TMMTime;
begin
  Result := 0.0;
  if (FDevHandle = 0) or (FTotalSamples = 0) then
    Exit;
  FillChar(MMT, SizeOf(MMT), 0);
  MMT.wType := TIME_SAMPLES;
  waveOutGetPosition(FDevHandle, @MMT, SizeOf(TMMTime));
  Result := (FSeekOffset + MMT.sample) / FTotalSamples;
  if Result > 1.0 then
    Result := 1.0;
end;



function TWaveOutPlayer.IsPlaying: Boolean;
begin
  Result := FSubmitted and (not FPaused) and ((WavHdrFlags and WHDR_DONE) = 0);
end;



function TWaveOutPlayer.IsPaused: Boolean;
begin
  Result := FPaused;
end;



function TWaveOutPlayer.HasEnded: Boolean;
begin
  Result := FSubmitted and (not FPaused) and ((WavHdrFlags and WHDR_DONE) <> 0);
end;



procedure TWaveOutPlayer.SeekToNormalized(Pos: Double);
var
  H: PWaveHdr;
  Offset: Integer;
  WasActive: Boolean;
begin
  if (FDevHandle = 0) or not FLoaded then
    Exit;
  WasActive := IsPlaying or IsPaused;
  H := PWaveHdr(@FWaveHdrBuf);
  waveOutReset(FDevHandle);
  waveOutUnprepareHeader(FDevHandle, H, SizeOf(TWaveHdr));
  FSubmitted := False;
  FPaused := False;

  if Pos < 0.0 then Pos := 0.0;
  if Pos > 1.0 then Pos := 1.0;
  Offset := Round(Pos * FTotalSamples);
  if Offset >= FTotalSamples then
    Offset := FTotalSamples - 1;
  FSeekOffset := Offset;

  FillChar(H^, SizeOf(TWaveHdr), 0);
  H^.lpData := PAnsiChar(@FBuffer[Offset]);
  H^.dwBufferLength := DWORD((FTotalSamples - Offset) * SizeOf(SmallInt));
  waveOutPrepareHeader(FDevHandle, H, SizeOf(TWaveHdr));

  if WasActive then begin
    waveOutWrite(FDevHandle, H, SizeOf(TWaveHdr));
    FSubmitted := True;
  end;
end;



end.
