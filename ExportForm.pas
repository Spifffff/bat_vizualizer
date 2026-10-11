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



unit ExportForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls;

type
  TExportKind = (ekImage, ekWav, ekMp3);



  TExportOptions = record
    Kind: TExportKind;
    ImageTarget: Integer; // 0 = waveform, 1 = spectrogram, 2 = both, as in PngExport
  end;



  TExportTextFunc = reference to function(AKind: TExportKind): string;



  TFormExport = class(TForm)
    LblType: TLabel;
    RbImage: TRadioButton;
    RbWav: TRadioButton;
    RbMp3: TRadioButton;
    LblImage: TLabel;
    CbxImageContent: TComboBox;
    LblSummary: TLabel;
    BtnOk: TButton;
    BtnCancel: TButton;
    procedure KindChange(Sender: TObject);
  private
    FSummaryFunc: TExportTextFunc;
    function GetKind: TExportKind;
    procedure UpdateState;
  public
    function Execute(var AOptions: TExportOptions; const ASummaryFunc: TExportTextFunc): Boolean;
  end;



function DefaultExportOptions: TExportOptions;
function ExportExtension(AKind: TExportKind): string;



implementation



{$R *.dfm}



function DefaultExportOptions: TExportOptions;
begin
  Result.Kind := ekImage;
  Result.ImageTarget := 2;
end;



function ExportExtension(AKind: TExportKind): string;
begin
  case AKind of
    ekImage:
      Result := '.png';
    ekWav:
      Result := '.wav';
  else
    Result := '.mp3';
  end;
end;



function TFormExport.GetKind: TExportKind;
begin
  if RbWav.Checked then
    Result := ekWav
  else if RbMp3.Checked then
    Result := ekMp3
  else
    Result := ekImage;
end;



procedure TFormExport.UpdateState;
begin
  if not Assigned(FSummaryFunc) then
    Exit();
  LblImage.Enabled := GetKind() = ekImage;
  CbxImageContent.Enabled := GetKind() = ekImage;
  LblSummary.Caption := FSummaryFunc(GetKind());
end;



procedure TFormExport.KindChange(Sender: TObject);
begin
  UpdateState();
end;



function TFormExport.Execute(var AOptions: TExportOptions; const ASummaryFunc: TExportTextFunc): Boolean;
begin
  FSummaryFunc := nil;
  case AOptions.Kind of
    ekImage:
      RbImage.Checked := True;
    ekWav:
      RbWav.Checked := True;
  else
    RbMp3.Checked := True;
  end;
  CbxImageContent.ItemIndex := EnsureRange(2 - AOptions.ImageTarget, 0, 2);
  FSummaryFunc := ASummaryFunc;
  UpdateState();
  Result := ShowModal() = mrOk;
  if Result then begin
    AOptions.Kind := GetKind();
    AOptions.ImageTarget := 2 - CbxImageContent.ItemIndex;
  end;
end;



end.
