program BatViz;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  MainForm in 'MainForm.pas' {FormMain},
  BatIdentForm in 'BatIdentForm.pas' {FormBatIdent},
  BusyForm in 'BusyForm.pas' {FormBusy},
  FFT in 'FFT.pas',
  WavReader in 'WavReader.pas',
  Spectrogram in 'Spectrogram.pas',
  WaveOutPlayer in 'WaveOutPlayer.pas',
  settings in 'settings.pas';

{$R *.res}



begin
  Application.Initialize;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;



end.
