object FormClipExport: TFormClipExport
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Export clips'
  ClientHeight = 172
  ClientWidth = 296
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object LblMargin: TLabel
    Left = 8
    Top = 66
    Width = 202
    Height = 13
    Caption = 'Margin before and after each section (s)'
  end
  object LblCount: TLabel
    Left = 8
    Top = 116
    Width = 280
    Height = 13
    AutoSize = False
    Caption = 'LblCount'
  end
  object ChkBestN: TCheckBox
    Left = 8
    Top = 10
    Width = 214
    Height = 17
    Caption = 'Best N sections per species'
    TabOrder = 0
    OnClick = FilterChange
  end
  object EdtBestN: TSpinEdit
    Left = 228
    Top = 8
    Width = 60
    Height = 22
    MaxValue = 9999
    MinValue = 1
    TabOrder = 1
    Value = 10
    OnChange = FilterChange
  end
  object ChkMinConfidence: TCheckBox
    Left = 8
    Top = 36
    Width = 214
    Height = 17
    Caption = 'Only sections above confidence (%)'
    TabOrder = 2
    OnClick = FilterChange
  end
  object EdtMinConfidence: TSpinEdit
    Left = 228
    Top = 34
    Width = 60
    Height = 22
    MaxValue = 100
    MinValue = 0
    TabOrder = 3
    Value = 50
    OnChange = FilterChange
  end
  object EdtMargin: TEdit
    Left = 228
    Top = 62
    Width = 60
    Height = 21
    TabOrder = 4
    Text = '2'
    OnChange = FilterChange
  end
  object ChkWriteCsv: TCheckBox
    Left = 8
    Top = 90
    Width = 280
    Height = 17
    Caption = 'Also save a results CSV file next to each clip'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object BtnOk: TButton
    Left = 132
    Top = 138
    Width = 75
    Height = 26
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object BtnCancel: TButton
    Left = 213
    Top = 138
    Width = 75
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
end
