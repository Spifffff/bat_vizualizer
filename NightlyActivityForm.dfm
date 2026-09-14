object FormNightlyActivity: TFormNightlyActivity
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeable
  Caption = 'Nightly activity'
  ClientHeight = 600
  ClientWidth = 960
  Color = clBtnFace
  Constraints.MinHeight = 420
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 960
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object LblDay: TLabel
      Left = 8
      Top = 11
      Width = 24
      Height = 13
      Caption = 'Day:'
    end
    object CbxDay: TComboBox
      Left = 38
      Top = 8
      Width = 240
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = CbxDayChange
    end
  end
  object ChartBox: TPaintBox
    Left = 0
    Top = 36
    Width = 960
    Height = 564
    Align = alClient
    OnPaint = ChartBoxPaint
  end
end
