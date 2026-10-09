object FormBusy: TFormBusy
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Please wait'
  ClientHeight = 66
  ClientWidth = 260
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object LblMessage: TLabel
    Left = 12
    Top = 10
    Width = 66
    Height = 13
    Caption = 'Please wait...'
  end
  object PrgBar: TProgressBar
    Left = 12
    Top = 30
    Width = 236
    Height = 20
    Style = pbstMarquee
    MarqueeInterval = 30
    TabOrder = 0
  end
  object BtnCancel: TButton
    Left = 173
    Top = 62
    Width = 75
    Height = 24
    Caption = 'Cancel'
    TabOrder = 1
    Visible = False
    OnClick = BtnCancelClick
  end
end
