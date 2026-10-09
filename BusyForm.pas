{ BatViz
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



unit BusyForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls;

type
  TFormBusy = class(TForm)
    LblMessage: TLabel;
    PrgBar: TProgressBar;
    BtnCancel: TButton;
    procedure BtnCancelClick(Sender: TObject);
  private
    FCancelled: Boolean;
  public
    procedure SetProgress(APosition, AMax: Integer);
    procedure SetMarquee;
    procedure ShowCancel(AVisible: Boolean);
    property Cancelled: Boolean read FCancelled;
  end;



implementation



{$R *.dfm}



const
  HEIGHT_WITHOUT_CANCEL = 66;
  HEIGHT_WITH_CANCEL = 96;



procedure TFormBusy.BtnCancelClick(Sender: TObject);
begin
  FCancelled := True;
  BtnCancel.Enabled := False;
  LblMessage.Caption := 'Cancelling...';
end;



procedure TFormBusy.SetProgress(APosition, AMax: Integer);
begin
  PrgBar.Style := pbstNormal;
  PrgBar.Max := AMax;
  PrgBar.Position := APosition;
end;



procedure TFormBusy.SetMarquee;
begin
  PrgBar.Style := pbstMarquee;
end;



procedure TFormBusy.ShowCancel(AVisible: Boolean);
begin
  FCancelled := False;
  BtnCancel.Enabled := True;
  BtnCancel.Visible := AVisible;
  if AVisible then
    ClientHeight := HEIGHT_WITH_CANCEL
  else
    ClientHeight := HEIGHT_WITHOUT_CANCEL;
end;



end.
