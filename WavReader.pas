unit WavReader;



interface



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
  public
    procedure LoadFromFile(const FileName: string);
    property Info: TWavInfo read FInfo;
    property Samples: TArray<Single> read FSamples;
  end;



implementation



uses SysUtils, Classes;



procedure TWavFile.LoadFromFile(const FileName: string);
var
  F: TFileStream;
  Tag: array [0 .. 3] of AnsiChar;
  ChunkSize, DataSize, FmtSize: Cardinal;
  Raw: TBytes;
  BytesPerSample, TotalSamples, I, Ch, Idx: Integer;
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

    FillChar(FInfo, SizeOf(FInfo), 0);
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
        SetLength(Raw, DataSize);
        F.ReadBuffer(Raw[0], DataSize);
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
    TotalSamples := Integer(DataSize) div (BytesPerSample * FInfo.Channels);

    FInfo.NumSamples := TotalSamples;
    FInfo.DurationSec := TotalSamples / FInfo.SampleRate;

    SetLength(FSamples, TotalSamples);
    Idx := 0;

    for I := 0 to TotalSamples - 1 do begin
      Sum := 0.0;
      for Ch := 0 to FInfo.Channels - 1 do begin
        case FInfo.BitsPerSample of
          8: begin
              S8 := ShortInt(Integer(Raw[Idx]) - 128);
              Sum := Sum + S8 / 128.0;
              Inc(Idx, 1);
            end;
          16: begin
              S16 := SmallInt(Word(Raw[Idx]) or (Word(Raw[Idx + 1]) shl 8));
              Sum := Sum + S16 / 32768.0;
              Inc(Idx, 2);
            end;
          24: begin
              S24 := Integer(Cardinal(Raw[Idx]) or (Cardinal(Raw[Idx + 1]) shl 8) or (Cardinal(Raw[Idx + 2]) shl 16));
              if S24 > $7FFFFF then
                S24 := S24 - $1000000;
              Sum := Sum + S24 / 8388608.0;
              Inc(Idx, 3);
            end;
          32: begin
              if FInfo.AudioFormat = 3 then begin
                Move(Raw[Idx], SF, 4);
                Sum := Sum + SF;
              end else begin
                S32 := Integer(Cardinal(Raw[Idx]) or (Cardinal(Raw[Idx + 1]) shl 8) or (Cardinal(Raw[Idx + 2]) shl 16) or (Cardinal(Raw[Idx + 3]) shl 24));
                Sum := Sum + S32 / 2147483648.0;
              end;
              Inc(Idx, 4);
            end;
        end;
      end;
      FSamples[I] := Single(Sum / FInfo.Channels);
    end;

  finally
    F.Free;
  end;
end;



end.
