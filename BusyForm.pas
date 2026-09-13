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
  end;

implementation

{$R *.dfm}

end.
