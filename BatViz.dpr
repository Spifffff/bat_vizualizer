program BatViz;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  MainForm      in 'MainForm.pas'      {FormMain},
  FFT           in 'FFT.pas',
  WavReader     in 'WavReader.pas',
  Spectrogram   in 'Spectrogram.pas',
  WaveOutPlayer in 'WaveOutPlayer.pas';

{$R *.res}

begin
  Application.Initialize;
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
