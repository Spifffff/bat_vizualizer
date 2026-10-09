object FormClipExport: TFormClipExport
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Export clips'
  ClientHeight = 170
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object LblMargin: TLabel
    Left = 16
    Top = 79
    Width = 202
    Height = 13
    Caption = 'Margin before and after each section (s)'
  end
  object LblCount: TLabel
    Left = 16
    Top = 112
    Width = 308
    Height = 13
    AutoSize = False
    Caption = 'LblCount'
  end
  object ChkBestN: TCheckBox
    Left = 16
    Top = 16
    Width = 228
    Height = 17
    Caption = 'Best N sections per species'
    TabOrder = 0
    OnClick = FilterChange
  end
  object EdtBestN: TSpinEdit
    Left = 254
    Top = 13
    Width = 70
    Height = 22
    MaxValue = 9999
    MinValue = 1
    TabOrder = 1
    Value = 10
    OnChange = FilterChange
  end
  object ChkMinConfidence: TCheckBox
    Left = 16
    Top = 46
    Width = 228
    Height = 17
    Caption = 'Only sections with confidence above (%)'
    TabOrder = 2
    OnClick = FilterChange
  end
  object EdtMinConfidence: TSpinEdit
    Left = 254
    Top = 43
    Width = 70
    Height = 22
    MaxValue = 100
    MinValue = 0
    TabOrder = 3
    Value = 50
    OnChange = FilterChange
  end
  object EdtMargin: TEdit
    Left = 254
    Top = 76
    Width = 70
    Height = 21
    TabOrder = 4
    Text = '2'
    OnChange = FilterChange
  end
  object BtnOk: TButton
    Left = 168
    Top = 135
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object BtnCancel: TButton
    Left = 249
    Top = 135
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
