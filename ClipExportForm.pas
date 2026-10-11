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
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Spin;

type
  TClipFilter = record
    UseBestN: Boolean;
    BestN: Integer;
    UseMinConfidence: Boolean;
    MinConfidence: Double; // 0..1, same scale as the detections
    MarginSec: Double;
    WriteCsv: Boolean;
  end;



  TClipCountFunc = reference to function(const AFilter: TClipFilter): Integer;



  TFormClipExport = class(TForm)
    ChkBestN: TCheckBox;
    EdtBestN: TEdit;
    SpnBestN: TSpinButton;
    ChkMinConfidence: TCheckBox;
    EdtMinConfidence: TEdit;
    SpnMinConfidence: TSpinButton;
    LblMargin: TLabel;
    EdtMargin: TEdit;
    SpnMargin: TSpinButton;
    ChkWriteCsv: TCheckBox;
    LblCount: TLabel;
    BtnOk: TButton;
    BtnCancel: TButton;
    procedure FilterChange(Sender: TObject);
    procedure SpinUpClick(Sender: TObject);
    procedure SpinDownClick(Sender: TObject);
  private
    FCountFunc: TClipCountFunc;
    procedure StepValue(ASpin: TObject; ADirection: Integer);
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
  Result.WriteCsv := True;
end;



function TFormClipExport.TryGetFilter(out AFilter: TClipFilter): Boolean;
var
  Confidence: Integer;
begin
  AFilter.UseBestN := ChkBestN.Checked;
  AFilter.UseMinConfidence := ChkMinConfidence.Checked;
  AFilter.WriteCsv := ChkWriteCsv.Checked;
  Result := TryStrToInt(Trim(EdtBestN.Text), AFilter.BestN) and (AFilter.BestN >= 1) and (AFilter.BestN <= 9999) and
    TryStrToInt(Trim(EdtMinConfidence.Text), Confidence) and (Confidence >= 0) and (Confidence <= 100) and
    TryStrToFloat(Trim(EdtMargin.Text), AFilter.MarginSec) and (AFilter.MarginSec >= 0.0) and (AFilter.MarginSec <= 3600.0);
  if Result then begin
    AFilter.MinConfidence := Confidence / 100.0;
    AFilter.MarginSec := Round(AFilter.MarginSec * 10) / 10.0;
  end;
end;



procedure TFormClipExport.UpdateState;
var
  Filter: TClipFilter;
  Count: Integer;
begin
  if not Assigned(FCountFunc) then
    Exit();
  EdtBestN.Enabled := ChkBestN.Checked;
  SpnBestN.Enabled := ChkBestN.Checked;
  EdtMinConfidence.Enabled := ChkMinConfidence.Checked;
  SpnMinConfidence.Enabled := ChkMinConfidence.Checked;
  if not TryGetFilter(Filter) then begin
    LblCount.Caption := 'Enter valid numbers (margin 0 s or more).';
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



procedure TFormClipExport.StepValue(ASpin: TObject; ADirection: Integer);
var
  Margin: Double;
begin
  if ASpin = SpnBestN then
    EdtBestN.Text := IntToStr(EnsureRange(StrToIntDef(Trim(EdtBestN.Text), 10) + ADirection, 1, 9999))
  else if ASpin = SpnMinConfidence then
    EdtMinConfidence.Text := IntToStr(EnsureRange(StrToIntDef(Trim(EdtMinConfidence.Text), 50) + ADirection, 0, 100))
  else if ASpin = SpnMargin then begin
    if not TryStrToFloat(Trim(EdtMargin.Text), Margin) then
      Margin := 2.0;
    { In tenths of a second, so repeated clicks never pick up rounding errors. }
    EdtMargin.Text := FormatFloat('0.0', EnsureRange(Round(Margin * 10) + ADirection, 0, 600) / 10.0);
  end;
end;



procedure TFormClipExport.SpinUpClick(Sender: TObject);
begin
  StepValue(Sender, 1);
end;



procedure TFormClipExport.SpinDownClick(Sender: TObject);
begin
  StepValue(Sender, -1);
end;



function TFormClipExport.Execute(var AFilter: TClipFilter; const ACountFunc: TClipCountFunc): Boolean;
begin
  FCountFunc := nil;
  ChkBestN.Checked := AFilter.UseBestN;
  EdtBestN.Text := IntToStr(AFilter.BestN);
  ChkMinConfidence.Checked := AFilter.UseMinConfidence;
  EdtMinConfidence.Text := IntToStr(Round(AFilter.MinConfidence * 100.0));
  EdtMargin.Text := FormatFloat('0.0', AFilter.MarginSec);
  ChkWriteCsv.Checked := AFilter.WriteCsv;
  FCountFunc := ACountFunc;
  UpdateState();
  Result := ShowModal() = mrOk;
  if Result then
    TryGetFilter(AFilter);
end;



end.
