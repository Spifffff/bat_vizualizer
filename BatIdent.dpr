program BatIdent;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  BatIdentForm in 'BatIdentForm.pas' {FormBatIdent};

{$R *.res}

begin
  Application.Initialize();
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormBatIdent, FormBatIdent);
  Application.Run();
end.
