unit LibVLC;

{ Dynamic binding for libvlc.dll (VLC 3.x).
  Call LoadVLC before using any function pointer.
  Call UnloadVLC on application shutdown. }

interface

uses Winapi.Windows;

type
  Plibvlc_instance_t     = Pointer;
  Plibvlc_media_t        = Pointer;
  Plibvlc_media_player_t = Pointer;

var
  VLCHandle: HMODULE = 0;

  libvlc_new:
    function(argc: Integer; argv: PPAnsiChar): Plibvlc_instance_t; cdecl;
  libvlc_release:
    procedure(p_instance: Plibvlc_instance_t); cdecl;

  libvlc_media_new_path:
    function(p_instance: Plibvlc_instance_t;
      path: PAnsiChar): Plibvlc_media_t; cdecl;
  libvlc_media_release:
    procedure(p_md: Plibvlc_media_t); cdecl;

  libvlc_media_player_new_from_media:
    function(p_md: Plibvlc_media_t): Plibvlc_media_player_t; cdecl;
  libvlc_media_player_release:
    procedure(p_mi: Plibvlc_media_player_t); cdecl;
  libvlc_media_player_play:
    function(p_mi: Plibvlc_media_player_t): Integer; cdecl;
  libvlc_media_player_pause:
    procedure(p_mi: Plibvlc_media_player_t); cdecl;
  libvlc_media_player_stop:
    procedure(p_mi: Plibvlc_media_player_t); cdecl;
  libvlc_media_player_set_rate:
    procedure(p_mi: Plibvlc_media_player_t; rate: Single); cdecl;
  libvlc_media_player_get_time:
    function(p_mi: Plibvlc_media_player_t): Int64; cdecl;
  libvlc_media_player_get_length:
    function(p_mi: Plibvlc_media_player_t): Int64; cdecl;
  libvlc_media_player_is_playing:
    function(p_mi: Plibvlc_media_player_t): Integer; cdecl;

function  LoadVLC(out ErrorMsg: string): Boolean;
procedure UnloadVLC;

implementation

uses SysUtils;

{ Search the standard VLC installation paths. }
function FindVLCDir: string;
const
  Candidates: array[0..5] of string = (
    'C:\Program Files\VideoLAN\VLC',
    'C:\Program Files (x86)\VideoLAN\VLC',
    'D:\Program Files\VideoLAN\VLC',
    'D:\Program Files (x86)\VideoLAN\VLC',
    'E:\Program Files\VideoLAN\VLC',
    'E:\Program Files (x86)\VideoLAN\VLC'
  );
var
  I: Integer;
begin
  Result := '';
  for I := Low(Candidates) to High(Candidates) do
    if FileExists(Candidates[I] + '\libvlc.dll') then
    begin
      Result := Candidates[I];
      Exit;
    end;
end;

{ Import a proc address; returns True if found. }
function Bind(Lib: HMODULE; const Name: AnsiString; var Ptr): Boolean;
begin
  Pointer(Ptr) := GetProcAddress(Lib, PAnsiChar(Name));
  Result := Pointer(Ptr) <> nil;
end;

function LoadVLC(out ErrorMsg: string): Boolean;
var
  VLCDir, OldDir: string;
begin
  Result := False;
  ErrorMsg := '';

  if VLCHandle <> 0 then begin Result := True; Exit; end;

  VLCDir := FindVLCDir;
  if VLCDir = '' then
  begin
    ErrorMsg := 'VLC not found. Please install VLC media player.';
    Exit;
  end;

  { Change to the VLC directory so Windows finds libvlccore.dll and plugins. }
  OldDir := GetCurrentDir;
  try
    SetCurrentDir(VLCDir);
    VLCHandle := LoadLibrary(PChar(VLCDir + '\libvlc.dll'));
  finally
    SetCurrentDir(OldDir);
  end;

  if VLCHandle = 0 then
  begin
    ErrorMsg := Format('Could not load libvlc.dll from "%s" (error %d)',
                       [VLCDir, GetLastError]);
    Exit;
  end;

  if not (
    Bind(VLCHandle, 'libvlc_new',                         @libvlc_new)                         and
    Bind(VLCHandle, 'libvlc_release',                     @libvlc_release)                     and
    Bind(VLCHandle, 'libvlc_media_new_path',              @libvlc_media_new_path)              and
    Bind(VLCHandle, 'libvlc_media_release',               @libvlc_media_release)               and
    Bind(VLCHandle, 'libvlc_media_player_new_from_media', @libvlc_media_player_new_from_media) and
    Bind(VLCHandle, 'libvlc_media_player_release',        @libvlc_media_player_release)        and
    Bind(VLCHandle, 'libvlc_media_player_play',           @libvlc_media_player_play)           and
    Bind(VLCHandle, 'libvlc_media_player_pause',          @libvlc_media_player_pause)          and
    Bind(VLCHandle, 'libvlc_media_player_stop',           @libvlc_media_player_stop)           and
    Bind(VLCHandle, 'libvlc_media_player_set_rate',       @libvlc_media_player_set_rate)       and
    Bind(VLCHandle, 'libvlc_media_player_get_time',       @libvlc_media_player_get_time)       and
    Bind(VLCHandle, 'libvlc_media_player_get_length',     @libvlc_media_player_get_length)     and
    Bind(VLCHandle, 'libvlc_media_player_is_playing',     @libvlc_media_player_is_playing)
  ) then
  begin
    FreeLibrary(VLCHandle);
    VLCHandle := 0;
    ErrorMsg := 'libvlc.dll is missing required exports (wrong VLC version?).';
    Exit;
  end;

  Result := True;
end;

procedure UnloadVLC;
begin
  if VLCHandle <> 0 then
  begin
    FreeLibrary(VLCHandle);
    VLCHandle := 0;
  end;
end;

end.
