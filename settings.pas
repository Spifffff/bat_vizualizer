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



{$WARN SYMBOL_PLATFORM OFF}

unit settings;



interface



uses
  Classes, Forms, IniFiles;

type
  TStoreTarget = (stIniFile, stRegistry);



  TSettingsIniFile = class(TInifile)
    function ReadString(const Section, Ident, Default: string): string; override;
  end;



  TSettings = class(TComponent)
  private
    _FStoredProps: TStrings;
    _FSection: string;
    _FRegKey: string;
    _FIniFile: string;
    _FStoreTarget: TStoreTarget;
    _FRaiseExceptions: boolean;
    procedure setStoredProps(const value: TStrings);
  public
    constructor Create(Aowner: TComponent); override;
    destructor Destroy; override;
    procedure loadSettings;
    procedure saveSettings;
    function ReadString(name: string; Default: string = ''): string;
    procedure writeString(name: string; value: string);
    function readInteger(name: string; Default: integer = 0): integer;
    procedure writeInteger(name: string; value: integer);
    function readFloat(name: string; Default: double = 0.0): double;
    procedure writeFloat(name: string; value: double);
    function readBoolean(name: string; Default: boolean = false): boolean;
    procedure writeBoolean(name: string; value: boolean);
    procedure writeFormPositions(const sourceForm: TForm);
    procedure readFormPositions(const targetForm: TForm);

    procedure deleteKey(name: string); overload;
    procedure deleteKey(Section, name: string); overload;
    function keyExists(name: string): boolean;
  published
    property storedProps: TStrings read _FStoredProps write setStoredProps;
    property regKey: string read _FRegKey write _FRegKey;
    property iniFile: string read _FIniFile write _FIniFile;
    property storeTarget: TStoreTarget read _FStoreTarget write _FStoreTarget;
    property raiseExceptions: boolean read _FRaiseExceptions write _FRaiseExceptions;
    property Section: string read _FSection write _FSection;
  end;



implementation



uses
  Dialogs, SysUtils, TypInfo, Registry, winapi.windows;


{ TSettings }



{ :@desc Constructor. Sets some initial values.
}
constructor TSettings.Create(Aowner: TComponent);
begin
  inherited Create(Aowner);
  _FStoreTarget := stIniFile;
  _FIniFile := ChangeFileExt(Application.ExeName, '.ini');
  _FRegKey := 'Software\' + ChangeFileExt(extractFileName(Application.ExeName), '');
  _FStoredProps := TStringList.Create();
  _FRaiseExceptions := true;

  if assigned(owner) then
    _FSection := owner.name
  else
    _FSection := 'common';
end;



{ :@desc Destructor.
}
procedure TSettings.deleteKey(Section, name: string);
var
  reg: TRegistry;
  ini: TSettingsIniFile;
begin

  if _FStoreTarget = stRegistry then begin

    reg := TRegistry.Create;
    reg.openKey(_FRegKey + '\' + Section, true);
    reg.deleteKey(name);
    reg.closeKey();
    reg.free();

  end else begin

    ini := TSettingsIniFile.Create(_FIniFile);
    ini.deleteKey(Section, name);
    ini.free();

  end;

end;



destructor TSettings.Destroy;
begin
  _FStoredProps.free();
  inherited Destroy;
end;



{ :@desc Used to write the property storedProps.
}
procedure TSettings.setStoredProps(const value: TStrings);
begin
  _FStoredProps.Assign(value);
end;



{ :@desc Load all stored properties.
}
procedure TSettings.loadSettings;
var
  i, j: integer;
  str: string;
  comp: TComponent;
  compName, propName, propValue: string;
  reg: TRegistry;
  ini: TSettingsIniFile;
  strList: TStringList;

  PropInfo: PPropInfo;
begin

  if _FStoredProps.count = 0 then
    exit;

  reg := TRegistry.Create();
  ini := TSettingsIniFile.Create(_FIniFile);
  strList := TStringList.Create();

  if _FStoreTarget = stRegistry then begin
    reg.openKey(_FRegKey + '\' + _FSection, true);
    reg.getValueNames(strList);
  end else begin
    ini.readSection(_FSection, strList);
  end;

  for i := 0 to strList.count - 1 do begin
    str := strList[i];
    if str <> '' then begin
      j := pos('.', str);
      compName := copy(str, 1, j - 1);

      if compName = '' then
        comp := owner
      else
        comp := owner.FindComponent(compName);

      if assigned(comp) then begin
        try
          propName := copy(str, j + 1, length(str));

          if _FStoreTarget = stRegistry then
            propValue := reg.ReadString(str)
          else
            propValue := ini.ReadString(_FSection, str, '');

          PropInfo := GetPropInfo(comp, propName);

          if assigned(PropInfo) and (propValue <> '') then begin
            if PropInfo.propType^^.kind = tkFloat then begin
              // setPropValue accepts variants, but with the windows decimal separator set to ',', this may go incorrect for floats.
              // Force floats to use variants in float format instead.
              setPropValue(comp, propName, strToFloat(propValue));
            end else begin
              setPropValue(comp, propName, propValue);
            end;
          end;

        except
          // Hide Exception
        end;
      end else if _FRaiseExceptions then // or (DebugHook <> 0) then
        raise Exception.Create('The component ' + compName + ' does not exist!');
    end;
  end;

  reg.closeKey();
  reg.free();
  ini.free();
  strList.free();

end;



{ :@desc Write all properties with active values.
}
procedure TSettings.saveSettings;
var
  i, j: integer;
  str: string;
  comp: TComponent;
  compName, propName, propValue: string;
  reg: TRegistry;
  ini: TSettingsIniFile;
  strList: TStringList;

begin

  if _FStoredProps.count = 0 then
    exit;

  reg := TRegistry.Create();
  ini := TSettingsIniFile.Create(_FIniFile);

  if _FStoreTarget = stRegistry then begin
    reg.openKey(_FRegKey + '\' + _FSection, true);
    strList := TStringList.Create;
    reg.getValueNames(strList);

    for i := 0 to strList.count - 1 do
      reg.DeleteValue(strList[i]);

    strList.free();

  end else begin
    ini.eraseSection(_FSection);
  end;

  for i := 0 to _FStoredProps.count - 1 do begin
    str := trim(_FStoredProps[i]);
    if str <> '' then begin
      j := pos('.', str);
      compName := copy(str, 1, j - 1);
      if compName = '' then
        comp := owner
      else
        comp := owner.FindComponent(compName);

      if assigned(comp) then begin
        try

          if compName <> '' then
            compName := compName + '.';

          propName := copy(str, j + 1, length(str));
          propValue := getPropValue(comp, propName);

          if _FStoreTarget = stRegistry then
            reg.writeString(compName + propName, propValue)
          else
            ini.writeString(_FSection, compName + propName, propValue);

        except
          // Hide Exception
        end;
      end else if _FRaiseExceptions or (DebugHook <> 0) then
        raise Exception.Create('The component ' + compName + ' does not exist');
    end;
  end;

  reg.closeKey();
  reg.free();
  ini.free();

end;



{ :@desc Reads a string from the ini file / registry.
  @param name Identifier.
}
function TSettings.ReadString(name: string; Default: string = ''): string;
var
  reg: TRegistry;
  ini: TSettingsIniFile;

begin

  if _FStoreTarget = stRegistry then begin

    reg := TRegistry.Create;
    if reg.keyExists(_FRegKey + '\common') then begin
      reg.openKey(_FRegKey + '\common', false);
      if reg.ValueExists(name) then
        Result := reg.ReadString(name)
      else
        Result := default;
    end
    else
      Result := default;

    reg.closeKey();
    reg.free();

  end else begin

    ini := TSettingsIniFile.Create(_FIniFile);
    Result := ini.ReadString('common', name, default);
    ini.free();

  end;

end;



{ :@desc Writes a string to the ini file / registry.
  @param name Identifier.
}
procedure TSettings.writeString(name, value: string);
var
  reg: TRegistry;
  ini: TSettingsIniFile;

begin

  if _FStoreTarget = stRegistry then begin

    reg := TRegistry.Create;
    reg.openKey(_FRegKey + '\common', true);
    reg.writeString(name, value);
    reg.closeKey();
    reg.free();

  end else begin

    ini := TSettingsIniFile.Create(_FIniFile);
    ini.writeString('common', name, value);
    ini.free();

  end;
end;



{ :@desc Reads a float from the ini file / registry.
  @param name Identifier.
}
function TSettings.readFloat(name: string; Default: double = 0.0): double;
begin
  Result := strToFloatDef(ReadString(name), default);
end;



{ :@desc Reads an integer from the ini file / registry.
  @param name Identifier.
}
function TSettings.readInteger(name: string; Default: integer = 0): integer;
begin
  Result := strToIntDef(ReadString(name), default);
end;



{ :@desc Reads a boolean from the ini file / registry.
  @param name Identifier.
}
function TSettings.readBoolean(name: string; Default: boolean = false): boolean;
begin
  if lowercase(ReadString(name)) = 'true' then
    Result := true
  else if lowercase(ReadString(name)) = 'false' then
    Result := false
  else
    Result := default;
end;



{ :@desc Writes a float to the ini file / registry.
  @param name Identifier.
}
procedure TSettings.writeFloat(name: string; value: double);
begin
  writeString(name, floatToStr(value));
end;



{ :@desc Writes an integer to the ini file / registry.
  @param name Identifier.
}
procedure TSettings.writeInteger(name: string; value: integer);
begin
  writeString(name, intToStr(value));
end;



{ :@desc Writes a boolean to the ini file / registry.
  @param name Identifier.
}
procedure TSettings.writeBoolean(name: string; value: boolean);
begin
  if value then
    writeString(name, 'true')
  else
    writeString(name, 'false');
end;



{ :@desc Deletes a key from the ini file / registry.
  @param name Key to delete.
}
procedure TSettings.deleteKey(name: string);
begin
  deleteKey('common', name);
end;



{ :@desc Returns whether or not the key exists
}
function TSettings.keyExists(name: string): boolean;
begin
  Result := false;
end;



procedure TSettings.readFormPositions(const targetForm: TForm);
var
  settingPrefix: string;
  windowStateInt, formTop, formLeft, formWidth, formHeight: integer;

begin
  settingPrefix := targetForm.name + '_';
  windowStateInt := readInteger(settingPrefix + 'windowState', integer(targetForm.WindowState));

  // when window is normal (not maxi, not minized)
  // save and load the positions
  if (windowStateInt = integer(wsNormal)) then begin
    formLeft := readInteger(settingPrefix + 'left', targetForm.Left);
    formTop := readInteger(settingPrefix + 'top', targetForm.Top);
    formWidth := readInteger(settingPrefix + 'width', targetForm.Width);
    formHeight := readInteger(settingPrefix + 'height', targetForm.Height);
    targetForm.WindowState := wsNormal;
    targetForm.Position := poDesigned;
    targetForm.SetBounds(formLeft, formTop, formWidth, formHeight);
  end else begin
    targetForm.WindowState := wsMaximized;
  end;
end;



procedure TSettings.writeFormPositions(const sourceForm: TForm);
var
  settingPrefix: string;
begin
  settingPrefix := sourceForm.name + '_';

  // window State
  writeInteger(settingPrefix + 'windowState', integer(sourceForm.WindowState));

  // when window is normal (not maxi, not minized)
  // save and load the positions
  if (sourceForm.WindowState = wsNormal) then begin
    writeInteger(settingPrefix + 'left', sourceForm.Left);
    writeInteger(settingPrefix + 'top', sourceForm.Top);
    writeInteger(settingPrefix + 'width', sourceForm.Width);
    writeInteger(settingPrefix + 'height', sourceForm.Height);
  end;
end;


{ TSettingsIniFile }



function TSettingsIniFile.ReadString(const Section, Ident, Default: string): string;
var
  Buffer: array [0 .. 1024 * 128] of Char;
begin
  SetString(Result, Buffer, GetPrivateProfileString(MarshaledString(Section), MarshaledString(Ident), MarshaledString(Default), Buffer, length(Buffer),
    MarshaledString(FileName)));
end;



end.
