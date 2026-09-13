unit WavReader;



interface



uses
  System.SysUtils;

type
  TWavInfo = record
    AudioFormat: Word; // 1 = PCM, 3 = IEEE float
    Channels: Word;
    SampleRate: Cardinal;
    BitsPerSample: Word;
    NumSamples: Integer;
    DurationSec: Double;
  end;



  TWavFile = class
  private
    FInfo: TWavInfo;
    FSamples: TArray<Single>;
    procedure LoadWavFromFile(const FileName: string; const AOnTick: TProc);
    procedure LoadMp3FromFile(const FileName: string; const AOnTick: TProc);
  public
    { AOnTick, when assigned, is called periodically while the file streams
      in so a caller can show progress for a slow (large-file) load; it is
      not called at a fixed rate, just once per internally-buffered chunk. }
    procedure LoadFromFile(const FileName: string; const AOnTick: TProc = nil);
    property Info: TWavInfo read FInfo;
    property Samples: TArray<Single> read FSamples;
  end;

function GetWavDurationSec(const FileName: string): Double;



implementation



uses
  Classes, System.Math, Winapi.Windows;

{ =========================================================================
  Minimal Windows Media Foundation declarations — avoids Winapi.MediaFoundation
  dependency and matches the self-contained style of WaveOutPlayer.pas.
  ========================================================================= }

const
  MFV          = DWORD($00020070); // MF_SDK_VERSION=2, MF_API_VERSION=$70 (Win7+)
  AUDIO_STRM   = DWORD($FFFFFFFD); // MF_SOURCE_READER_FIRST_AUDIO_STREAM
  ALL_STRMS    = DWORD($FFFFFFFE); // MF_SOURCE_READER_ALL_STREAMS
  ENDOFSTREAM  = DWORD($00000004); // MF_SOURCE_READERF_ENDOFSTREAM
  READERF_ERR  = DWORD($00000001); // MF_SOURCE_READERF_ERROR

type
  { IMFAttributes — 30 methods after IUnknown; only the ones we call are typed. }
  IMFAttributes = interface(IUnknown)
    ['{2CD2D921-C447-44A7-A13C-4ADABFC247E3}']
    function _A01: HResult; stdcall; { GetItem }
    function _A02: HResult; stdcall; { GetItemType }
    function _A03: HResult; stdcall; { CompareItem }
    function _A04: HResult; stdcall; { Compare }
    function GetUINT32(const guidKey: TGUID; out punValue: Cardinal): HResult; stdcall;
    function _A06: HResult; stdcall; { GetUINT64 }
    function _A07: HResult; stdcall; { GetDouble }
    function GetGUID(const guidKey: TGUID; out pguidValue: TGUID): HResult; stdcall;
    function _A09: HResult; stdcall; { GetStringLength }
    function _A10: HResult; stdcall; { GetString }
    function _A11: HResult; stdcall; { GetAllocatedString }
    function _A12: HResult; stdcall; { GetBlobSize }
    function _A13: HResult; stdcall; { GetBlob }
    function _A14: HResult; stdcall; { GetAllocatedBlob }
    function _A15: HResult; stdcall; { GetUnknown }
    function _A16: HResult; stdcall; { SetItem }
    function _A17: HResult; stdcall; { DeleteItem }
    function _A18: HResult; stdcall; { DeleteAllItems }
    function SetUINT32(const guidKey: TGUID; unValue: Cardinal): HResult; stdcall;
    function _A20: HResult; stdcall; { SetUINT64 }
    function _A21: HResult; stdcall; { SetDouble }
    function SetGUID(const guidKey: TGUID; const guidValue: TGUID): HResult; stdcall;
    function _A23: HResult; stdcall; { SetString }
    function _A24: HResult; stdcall; { SetBlob }
    function _A25: HResult; stdcall; { SetUnknown }
    function _A26: HResult; stdcall; { LockStore }
    function _A27: HResult; stdcall; { UnlockStore }
    function _A28: HResult; stdcall; { GetCount }
    function _A29: HResult; stdcall; { GetItemByIndex }
    function _A30: HResult; stdcall; { CopyAllItems }
  end;

  { IMFMediaType extends IMFAttributes with 5 more methods (unused). }
  IMFMediaType = interface(IMFAttributes)
    ['{44AE0FA8-EA31-4109-8D2E-4CAE4997C555}']
    function _M1: HResult; stdcall;
    function _M2: HResult; stdcall;
    function _M3: HResult; stdcall;
    function _M4: HResult; stdcall;
    function _M5: HResult; stdcall;
  end;

  IMFMediaBuffer = interface(IUnknown)
    ['{045FA593-8799-42B8-BC8D-8968C6453507}']
    function Lock(out ppbBuffer: PByte; pcbMaxLength: PDWORD; pcbCurrentLength: PDWORD): HResult; stdcall;
    function Unlock: HResult; stdcall;
    function GetCurrentLength(out pcbCurrentLength: DWORD): HResult; stdcall;
    function SetCurrentLength(cbCurrentLength: DWORD): HResult; stdcall;
    function GetMaxLength(out pcbMaxLength: DWORD): HResult; stdcall;
  end;

  { IMFSample extends IMFAttributes; ConvertToContiguousBuffer is the 9th
    IMFSample-specific method. }
  IMFSample = interface(IMFAttributes)
    ['{C40A00F2-B93A-4D80-AE8C-5A1C634F58E4}']
    function _S1: HResult; stdcall; { GetSampleFlags }
    function _S2: HResult; stdcall; { SetSampleFlags }
    function _S3: HResult; stdcall; { GetSampleTime }
    function _S4: HResult; stdcall; { SetSampleTime }
    function _S5: HResult; stdcall; { GetSampleDuration }
    function _S6: HResult; stdcall; { SetSampleDuration }
    function _S7: HResult; stdcall; { GetBufferCount }
    function _S8: HResult; stdcall; { GetBufferByIndex }
    function ConvertToContiguousBuffer(out ppBuffer: IMFMediaBuffer): HResult; stdcall;
  end;

  { IMFSourceReader — GetCurrentMediaType is 4th, SetCurrentMediaType 5th,
    ReadSample 7th. }
  IMFSourceReader = interface(IUnknown)
    ['{70AE66F2-C809-4E4F-8915-BDCB406B7993}']
    function _R1: HResult; stdcall; { GetStreamSelection }
    function SetStreamSelection(dwStreamIndex: DWORD; fSelected: BOOL): HResult; stdcall;
    function _R3: HResult; stdcall; { GetNativeMediaType }
    function GetCurrentMediaType(dwStreamIndex: DWORD; out ppMediaType: IMFMediaType): HResult; stdcall;
    function SetCurrentMediaType(dwStreamIndex: DWORD; pdwReserved: PDWORD; pMediaType: IMFMediaType): HResult; stdcall;
    function _R6: HResult; stdcall; { SetCurrentPosition }
    function ReadSample(dwStreamIndex: DWORD; dwControlFlags: DWORD;
      pdwActualStreamIndex: PDWORD; pdwStreamFlags: PDWORD;
      pllTimestamp: PInt64; out ppSample: IMFSample): HResult; stdcall;
  end;

var
  MFMediaType_Audio:              TGUID = '{73647561-0000-0010-8000-00AA00389B71}';
  MFAudioFormat_PCM:              TGUID = '{00000001-0000-0010-8000-00AA00389B71}';
  MF_MT_MAJOR_TYPE:               TGUID = '{48EBA18E-F8C9-4687-BF11-0A74C9F96A8F}';
  MF_MT_SUBTYPE:                  TGUID = '{F7E34C9A-42E8-4714-B74B-CB29D72C35E5}';
  MF_MT_AUDIO_SAMPLES_PER_SECOND: TGUID = '{5FAEEAE7-0290-4C31-9E8A-C534F68D9EDA}';
  MF_MT_AUDIO_NUM_CHANNELS:       TGUID = '{37E48BF5-645E-4C5B-89DE-ADA9E29B696A}';
  MF_MT_AUDIO_BITS_PER_SAMPLE:    TGUID = '{F2DEB57F-40FA-4764-AA33-ED4F2D1FF669}';

function MFStartup(Version: DWORD; dwFlags: DWORD): HResult; stdcall;
  external 'Mfplat.dll';
function MFShutdown: HResult; stdcall;
  external 'Mfplat.dll';
function MFCreateMediaType(out ppMFType: IMFMediaType): HResult; stdcall;
  external 'Mfplat.dll';
function MFCreateSourceReaderFromURL(pwszURL: PWideChar; pAttributes: IUnknown;
  out ppSourceReader: IMFSourceReader): HResult; stdcall;
  external 'Mfreadwrite.dll';

{ =========================================================================
  TWavFile
  ========================================================================= }

procedure TWavFile.LoadFromFile(const FileName: string; const AOnTick: TProc);
begin
  FillChar(FInfo, SizeOf(FInfo), 0);
  SetLength(FSamples, 0);
  if SameText(ExtractFileExt(FileName), '.mp3') then
    LoadMp3FromFile(FileName, AOnTick)
  else
    LoadWavFromFile(FileName, AOnTick);
end;



procedure TWavFile.LoadWavFromFile(const FileName: string; const AOnTick: TProc);
const
  STREAM_BUF_BYTES = 1 shl 20; // 1 MB read buffer
var
  F: TFileStream;
  Tag: array [0 .. 3] of AnsiChar;
  ChunkSize, DataSize, FmtSize: Cardinal;
  Buf: TBytes;
  BytesPerSample, FrameBytes, FramesPerBuf, BufFrames, BufBytes: Integer;
  TotalSamples, Remaining, OutIdx, I, Ch, Idx: Integer;
  Sum: Double;
  S8: ShortInt;
  S16: SmallInt;
  S24, S32: Integer;
  SF: Single;
begin
  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    F.ReadBuffer(Tag, 4);
    if (Tag[0] <> 'R') or (Tag[1] <> 'I') or (Tag[2] <> 'F') or (Tag[3] <> 'F') then
      raise Exception.Create('Not a RIFF file');
    F.ReadBuffer(ChunkSize, 4);
    F.ReadBuffer(Tag, 4);
    if (Tag[0] <> 'W') or (Tag[1] <> 'A') or (Tag[2] <> 'V') or (Tag[3] <> 'E') then
      raise Exception.Create('Not a WAVE file');

    DataSize := 0;

    while F.Position + 8 <= F.Size do begin
      if F.Read(Tag, 4) < 4 then
        Break;
      F.ReadBuffer(ChunkSize, 4);

      if (Tag[0] = 'f') and (Tag[1] = 'm') and (Tag[2] = 't') and (Tag[3] = ' ') then begin
        FmtSize := ChunkSize;
        F.ReadBuffer(FInfo.AudioFormat, 2);
        F.ReadBuffer(FInfo.Channels, 2);
        F.ReadBuffer(FInfo.SampleRate, 4);
        F.Seek(4, soFromCurrent); // ByteRate
        F.Seek(2, soFromCurrent); // BlockAlign
        F.ReadBuffer(FInfo.BitsPerSample, 2);
        if FmtSize > 16 then
          F.Seek(FmtSize - 16, soFromCurrent);
      end else if (Tag[0] = 'd') and (Tag[1] = 'a') and (Tag[2] = 't') and (Tag[3] = 'a') then begin
        DataSize := ChunkSize;
        Break;
      end
      else
        F.Seek(ChunkSize, soFromCurrent);
    end;

    if DataSize = 0 then
      raise Exception.Create('No data chunk found');
    if FInfo.Channels = 0 then
      raise Exception.Create('Invalid WAV format chunk');

    BytesPerSample := FInfo.BitsPerSample div 8;
    FrameBytes := BytesPerSample * FInfo.Channels;
    if FrameBytes = 0 then
      raise Exception.Create('Invalid WAV format chunk');
    TotalSamples := Integer(DataSize) div FrameBytes;

    FInfo.NumSamples := TotalSamples;
    FInfo.DurationSec := TotalSamples / FInfo.SampleRate;

    SetLength(FSamples, TotalSamples);

    { Stream the data chunk through a fixed-size buffer instead of loading
      the whole chunk into memory at once -- for a long, high-sample-rate
      recording that raw-bytes copy used to roughly double the peak memory
      needed (raw bytes + decoded float samples), which is what triggered
      out-of-memory on large files. }
    FramesPerBuf := Max(1, STREAM_BUF_BYTES div FrameBytes);
    SetLength(Buf, FramesPerBuf * FrameBytes);
    OutIdx := 0;
    Remaining := TotalSamples;

    while Remaining > 0 do begin
      BufFrames := Min(FramesPerBuf, Remaining);
      BufBytes := BufFrames * FrameBytes;
      F.ReadBuffer(Buf[0], BufBytes);

      Idx := 0;
      for I := 0 to BufFrames - 1 do begin
        Sum := 0.0;
        for Ch := 0 to FInfo.Channels - 1 do begin
          case FInfo.BitsPerSample of
            8: begin
                S8 := ShortInt(Integer(Buf[Idx]) - 128);
                Sum := Sum + S8 / 128.0;
                Inc(Idx, 1);
              end;
            16: begin
                S16 := SmallInt(Word(Buf[Idx]) or (Word(Buf[Idx + 1]) shl 8));
                Sum := Sum + S16 / 32768.0;
                Inc(Idx, 2);
              end;
            24: begin
                S24 := Integer(Cardinal(Buf[Idx]) or (Cardinal(Buf[Idx + 1]) shl 8) or (Cardinal(Buf[Idx + 2]) shl 16));
                if S24 > $7FFFFF then
                  S24 := S24 - $1000000;
                Sum := Sum + S24 / 8388608.0;
                Inc(Idx, 3);
              end;
            32: begin
                if FInfo.AudioFormat = 3 then begin
                  Move(Buf[Idx], SF, 4);
                  Sum := Sum + SF;
                end else begin
                  S32 := Integer(Cardinal(Buf[Idx]) or (Cardinal(Buf[Idx + 1]) shl 8) or (Cardinal(Buf[Idx + 2]) shl 16) or (Cardinal(Buf[Idx + 3]) shl 24));
                  Sum := Sum + S32 / 2147483648.0;
                end;
                Inc(Idx, 4);
              end;
          end;
        end;
        FSamples[OutIdx] := Single(Sum / FInfo.Channels);
        Inc(OutIdx);
      end;

      Dec(Remaining, BufFrames);
      if Assigned(AOnTick) then
        AOnTick();
    end;

  finally
    F.Free();
  end;
end;



function GetWavDurationSec(const FileName: string): Double;
var
  F: TFileStream;
  Tag: array [0 .. 3] of AnsiChar;
  ChunkSize, DataSize: Cardinal;
  SampleRate: Cardinal;
  Channels, BitsPerSample: Word;
  BytesPerSample, TotalSamples: Integer;
begin
  Result := 0;
  SampleRate := 0;
  Channels := 0;
  BitsPerSample := 0;
  DataSize := 0;
  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    F.ReadBuffer(Tag, 4);
    if (Tag[0] <> 'R') or (Tag[1] <> 'I') or (Tag[2] <> 'F') or (Tag[3] <> 'F') then
      Exit;
    F.ReadBuffer(ChunkSize, 4);
    F.ReadBuffer(Tag, 4);
    if (Tag[0] <> 'W') or (Tag[1] <> 'A') or (Tag[2] <> 'V') or (Tag[3] <> 'E') then
      Exit;
    while F.Position + 8 <= F.Size do begin
      if F.Read(Tag, 4) < 4 then
        Break;
      F.ReadBuffer(ChunkSize, 4);
      if (Tag[0] = 'f') and (Tag[1] = 'm') and (Tag[2] = 't') and (Tag[3] = ' ') then begin
        F.Seek(2, soFromCurrent); // AudioFormat
        F.ReadBuffer(Channels, 2);
        F.ReadBuffer(SampleRate, 4);
        F.Seek(4, soFromCurrent); // ByteRate
        F.Seek(2, soFromCurrent); // BlockAlign
        F.ReadBuffer(BitsPerSample, 2);
        if ChunkSize > 16 then
          F.Seek(ChunkSize - 16, soFromCurrent);
      end else if (Tag[0] = 'd') and (Tag[1] = 'a') and (Tag[2] = 't') and (Tag[3] = 'a') then begin
        DataSize := ChunkSize;
        Break;
      end else
        F.Seek(ChunkSize, soFromCurrent);
    end;
    if (SampleRate = 0) or (Channels = 0) or (BitsPerSample = 0) then
      Exit;
    BytesPerSample := BitsPerSample div 8;
    if BytesPerSample = 0 then
      Exit;
    TotalSamples := Integer(DataSize) div (BytesPerSample * Channels);
    Result := TotalSamples / SampleRate;
  finally
    F.Free();
  end;
end;



procedure TWavFile.LoadMp3FromFile(const FileName: string; const AOnTick: TProc);
var
  HR: HResult;
  Reader: IMFSourceReader;
  OutType, ActType: IMFMediaType;
  Channels, Rate: Cardinal;
  Flags: DWORD;
  Timestamp: Int64;
  Sample: IMFSample;
  MBuf: IMFMediaBuffer;
  Data: PByte;
  MaxLen, CurLen: DWORD;
  Buf: TArray<Single>;
  Count, FrameN, I, Ch: Integer;
  Sum: Double;
begin
  if Failed(MFStartup(MFV, 0)) then
    raise Exception.Create('Windows Media Foundation failed to initialise');
  try
    HR := MFCreateSourceReaderFromURL(PChar(FileName), nil, Reader);
    if Failed(HR) then
      raise Exception.CreateFmt('Cannot open "%s" (HRESULT 0x%x)', [ExtractFileName(FileName), HR]);

    // Deselect all streams, then select only the first audio stream so that
    // ReadSample never stalls on un-consumed video packets.
    Reader.SetStreamSelection(ALL_STRMS, False);
    Reader.SetStreamSelection(AUDIO_STRM, True);

    if Failed(MFCreateMediaType(OutType)) then
      raise Exception.Create('MFCreateMediaType failed');
    OutType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
    OutType.SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
    OutType.SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);

    HR := Reader.SetCurrentMediaType(AUDIO_STRM, nil, OutType);
    if Failed(HR) then
      raise Exception.CreateFmt('Cannot decode audio in "%s" (HRESULT 0x%x)', [ExtractFileName(FileName), HR]);

    Channels := 1;
    Rate     := 44100;
    if not Failed(Reader.GetCurrentMediaType(AUDIO_STRM, ActType)) then begin
      ActType.GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, Channels);
      ActType.GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, Rate);
    end;
    if Channels = 0 then
      Channels := 1;

    FInfo.AudioFormat   := 1;
    FInfo.Channels      := Channels;
    FInfo.SampleRate    := Rate;
    FInfo.BitsPerSample := 16;

    Count := 0;
    SetLength(Buf, Max(65536, Integer(Rate) * 10)); // pre-alloc ~10 s

    var NilRun := 0;
    var TickCounter := 0;
    while True do begin
      Sample := nil;
      HR := Reader.ReadSample(AUDIO_STRM, 0, nil, @Flags, @Timestamp, Sample);
      if Failed(HR) or ((Flags and (ENDOFSTREAM or READERF_ERR)) <> 0) then
        Break;
      if Sample = nil then begin
        Inc(NilRun);
        if NilRun > 500 then Break; // stream stalled
        Continue;
      end;
      NilRun := 0;
      MBuf := nil;
      if Failed(Sample.ConvertToContiguousBuffer(MBuf)) then
        Continue;
      Data := nil;
      MaxLen := 0;
      CurLen := 0;
      if Failed(MBuf.Lock(Data, @MaxLen, @CurLen)) then
        Continue;
      try
        FrameN := Integer(CurLen) div (2 * Integer(Channels));
        if Count + FrameN > Length(Buf) then
          SetLength(Buf, Max(Count + FrameN, Length(Buf) * 2));
        for I := 0 to FrameN - 1 do begin
          Sum := 0;
          for Ch := 0 to Integer(Channels) - 1 do
            Sum := Sum + PSmallInt(Data + (I * Integer(Channels) + Ch) * 2)^ / 32768.0;
          Buf[Count + I] := Single(Sum / Channels);
        end;
        Inc(Count, FrameN);
      finally
        MBuf.Unlock();
      end;
      Inc(TickCounter);
      if Assigned(AOnTick) and (TickCounter mod 16 = 0) then
        AOnTick();
    end;

    SetLength(FSamples, Count);
    if Count > 0 then
      Move(Buf[0], FSamples[0], Count * SizeOf(Single));
    FInfo.NumSamples  := Count;
    FInfo.DurationSec := Count / Rate;
  finally
    MFShutdown();
  end;
end;



end.
