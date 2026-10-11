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
  object EdtBestN: TEdit
    Left = 228
    Top = 8
    Width = 44
    Height = 21
    NumbersOnly = True
    TabOrder = 1
    Text = '10'
    OnChange = FilterChange
  end
  object SpnBestN: TSpinButton
    Left = 272
    Top = 8
    Width = 16
    Height = 21
    FocusControl = EdtBestN
    TabOrder = 2
    OnDownClick = SpinDownClick
    OnUpClick = SpinUpClick
  end
  object ChkMinConfidence: TCheckBox
    Left = 8
    Top = 36
    Width = 214
    Height = 17
    Caption = 'Only sections above confidence (%)'
    TabOrder = 3
    OnClick = FilterChange
  end
  object EdtMinConfidence: TEdit
    Left = 228
    Top = 34
    Width = 44
    Height = 21
    NumbersOnly = True
    TabOrder = 4
    Text = '50'
    OnChange = FilterChange
  end
  object SpnMinConfidence: TSpinButton
    Left = 272
    Top = 34
    Width = 16
    Height = 21
    FocusControl = EdtMinConfidence
    TabOrder = 5
    OnDownClick = SpinDownClick
    OnUpClick = SpinUpClick
  end
  object EdtMargin: TEdit
    Left = 228
    Top = 62
    Width = 44
    Height = 21
    TabOrder = 6
    Text = '2.0'
    OnChange = FilterChange
  end
  object SpnMargin: TSpinButton
    Left = 272
    Top = 62
    Width = 16
    Height = 21
    FocusControl = EdtMargin
    TabOrder = 7
    OnDownClick = SpinDownClick
    OnUpClick = SpinUpClick
  end
  object ChkWriteCsv: TCheckBox
    Left = 8
    Top = 90
    Width = 280
    Height = 17
    Caption = 'Also save a results CSV file next to each clip'
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object BtnOk: TButton
    Left = 132
    Top = 138
    Width = 75
    Height = 26
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 9
  end
  object BtnCancel: TButton
    Left = 213
    Top = 138
    Width = 75
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 10
  end
end
