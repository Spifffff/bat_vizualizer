object FormExport: TFormExport
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Export current view'
  ClientHeight = 132
  ClientWidth = 346
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object LblType: TLabel
    Left = 8
    Top = 12
    Width = 27
    Height = 13
    Caption = 'Type:'
  end
  object LblImage: TLabel
    Left = 8
    Top = 40
    Width = 34
    Height = 13
    Caption = 'Image:'
  end
  object LblSummary: TLabel
    Left = 8
    Top = 68
    Width = 330
    Height = 26
    AutoSize = False
    Caption = 'LblSummary'
    WordWrap = True
  end
  object RbImage: TRadioButton
    Left = 68
    Top = 10
    Width = 86
    Height = 17
    Caption = 'Image (PNG)'
    Checked = True
    TabOrder = 0
    TabStop = True
    OnClick = KindChange
  end
  object RbWav: TRadioButton
    Left = 158
    Top = 10
    Width = 90
    Height = 17
    Caption = 'Audio (WAV)'
    TabOrder = 1
    OnClick = KindChange
  end
  object RbMp3: TRadioButton
    Left = 252
    Top = 10
    Width = 86
    Height = 17
    Caption = 'Audio (MP3)'
    TabOrder = 2
    OnClick = KindChange
  end
  object CbxImageContent: TComboBox
    Left = 68
    Top = 36
    Width = 270
    Height = 21
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 3
    Text = 'Waveform and spectrogram'
    Items.Strings = (
      'Waveform and spectrogram'
      'Spectrogram only'
      'Waveform only')
  end
  object BtnOk: TButton
    Left = 182
    Top = 98
    Width = 75
    Height = 26
    Caption = 'Save as...'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object BtnCancel: TButton
    Left = 263
    Top = 98
    Width = 75
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
