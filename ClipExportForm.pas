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



unit ClipExportForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Spin;

type
  TClipFilter = record
    UseBestN: Boolean;
    BestN: Integer;
    UseMinConfidence: Boolean;
    MinConfidence: Double; // 0..1, same scale as the detections
    MarginSec: Double;
  end;



  TClipCountFunc = reference to function(const AFilter: TClipFilter): Integer;



  TFormClipExport = class(TForm)
    ChkBestN: TCheckBox;
    EdtBestN: TSpinEdit;
    ChkMinConfidence: TCheckBox;
    EdtMinConfidence: TSpinEdit;
    LblMargin: TLabel;
    EdtMargin: TEdit;
    LblCount: TLabel;
    BtnOk: TButton;
    BtnCancel: TButton;
    procedure FilterChange(Sender: TObject);
  private
    FCountFunc: TClipCountFunc;
    function TryGetFilter(out AFilter: TClipFilter): Boolean;
    procedure UpdateState;
  public
    function Execute(var AFilter: TClipFilter; const ACountFunc: TClipCountFunc): Boolean;
  end;



function DefaultClipFilter: TClipFilter;



implementation



{$R *.dfm}



function DefaultClipFilter: TClipFilter;
begin
  Result.UseBestN := False;
  Result.BestN := 10;
  Result.UseMinConfidence := False;
  Result.MinConfidence := 0.5;
  Result.MarginSec := 2.0;
end;



function TFormClipExport.TryGetFilter(out AFilter: TClipFilter): Boolean;
begin
  AFilter.UseBestN := ChkBestN.Checked;
  AFilter.BestN := EdtBestN.Value;
  AFilter.UseMinConfidence := ChkMinConfidence.Checked;
  AFilter.MinConfidence := EdtMinConfidence.Value / 100.0;
  Result := TryStrToFloat(Trim(EdtMargin.Text), AFilter.MarginSec) and (AFilter.MarginSec >= 0.0) and (AFilter.MarginSec <= 3600.0);
end;



procedure TFormClipExport.UpdateState;
var
  Filter: TClipFilter;
  Count: Integer;
begin
  if not Assigned(FCountFunc) then
    Exit();
  EdtBestN.Enabled := ChkBestN.Checked;
  EdtMinConfidence.Enabled := ChkMinConfidence.Checked;
  if not TryGetFilter(Filter) then begin
    LblCount.Caption := 'Enter a margin of 0 seconds or more.';
    BtnOk.Enabled := False;
    Exit();
  end;
  Count := FCountFunc(Filter);
  LblCount.Caption := Format('%d section(s) will be exported.', [Count]);
  BtnOk.Enabled := Count > 0;
end;



procedure TFormClipExport.FilterChange(Sender: TObject);
begin
  UpdateState();
end;



function TFormClipExport.Execute(var AFilter: TClipFilter; const ACountFunc: TClipCountFunc): Boolean;
begin
  FCountFunc := nil;
  ChkBestN.Checked := AFilter.UseBestN;
  EdtBestN.Value := AFilter.BestN;
  ChkMinConfidence.Checked := AFilter.UseMinConfidence;
  EdtMinConfidence.Value := Round(AFilter.MinConfidence * 100.0);
  EdtMargin.Text := FloatToStr(AFilter.MarginSec);
  FCountFunc := ACountFunc;
  UpdateState();
  Result := ShowModal() = mrOk;
  if Result then
    TryGetFilter(AFilter);
end;



end.
