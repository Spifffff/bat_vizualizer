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
  settings in 'settings.pas',
  ClipExportForm in 'ClipExportForm.pas' {FormClipExport},
  ExportForm in 'ExportForm.pas' {FormExport};

{$R *.res}



begin
  Application.Initialize;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;



end.
