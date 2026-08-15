program BatViz;

uses
  Vcl.Forms,
  MainForm      in 'MainForm.pas'      {FormMain},
  FFT           in 'FFT.pas',
  WavReader     in 'WavReader.pas',
  LibVLC        in 'LibVLC.pas',
  Spectrogram   in 'Spectrogram.pas',
  WaveOutPlayer in 'WaveOutPlayer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
