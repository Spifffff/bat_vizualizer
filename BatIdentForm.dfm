object FormBatIdent: TFormBatIdent
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'BatIdent'
  ClientHeight = 540
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object GrpFolders: TGroupBox
    Left = 8
    Top = 8
    Width = 624
    Height = 116
    Caption = 'Folders'
    TabOrder = 0
    object LblWavFolder: TLabel
      Left = 8
      Top = 24
      Width = 58
      Height = 13
      Caption = 'WAV folder:'
    end
    object LblOutputFolder: TLabel
      Left = 8
      Top = 52
      Width = 69
      Height = 13
      Caption = 'Output folder:'
    end
    object LblBattyFolder: TLabel
      Left = 8
      Top = 80
      Width = 98
      Height = 13
      Caption = 'BattyBirdNET folder:'
    end
    object EdtWavFolder: TEdit
      Left = 80
      Top = 20
      Width = 448
      Height = 21
      TabOrder = 0
    end
    object BtnBrowseWav: TButton
      Left = 534
      Top = 19
      Width = 80
      Height = 23
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = BtnBrowseWavClick
    end
    object EdtOutputFolder: TEdit
      Left = 80
      Top = 48
      Width = 448
      Height = 21
      TabOrder = 2
    end
    object BtnBrowseOutput: TButton
      Left = 534
      Top = 47
      Width = 80
      Height = 23
      Caption = 'Browse...'
      TabOrder = 3
      OnClick = BtnBrowseOutputClick
    end
    object EdtBattyFolder: TEdit
      Left = 124
      Top = 76
      Width = 404
      Height = 21
      TabOrder = 4
    end
    object BtnBrowseBatty: TButton
      Left = 534
      Top = 75
      Width = 80
      Height = 23
      Caption = 'Browse...'
      TabOrder = 5
      OnClick = BtnBrowseBattyClick
    end
  end
  object GrpParams: TGroupBox
    Left = 8
    Top = 130
    Width = 624
    Height = 100
    Caption = 'Parameters'
    TabOrder = 1
    object LblArea: TLabel
      Left = 8
      Top = 24
      Width = 27
      Height = 13
      Caption = 'Area:'
    end
    object LblKHz: TLabel
      Left = 160
      Top = 24
      Width = 21
      Height = 13
      Caption = 'kHz:'
    end
    object LblParallel: TLabel
      Left = 276
      Top = 24
      Width = 60
      Height = 13
      Caption = 'Parallel files:'
    end
    object LblMinConf: TLabel
      Left = 8
      Top = 58
      Width = 75
      Height = 13
      Caption = 'Min confidence:'
    end
    object LblSfThresh: TLabel
      Left = 154
      Top = 58
      Width = 50
      Height = 13
      Caption = 'sf_thresh:'
    end
    object LblSensitivity: TLabel
      Left = 278
      Top = 58
      Width = 53
      Height = 13
      Caption = 'Sensitivity:'
    end
    object CbxArea: TComboBox
      Left = 40
      Top = 21
      Width = 110
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
    object CbxKHz: TComboBox
      Left = 188
      Top = 21
      Width = 80
      Height = 21
      Style = csDropDownList
      TabOrder = 1
    end
    object CbxParallel: TComboBox
      Left = 352
      Top = 21
      Width = 60
      Height = 21
      Style = csDropDownList
      TabOrder = 2
    end
    object EdtMinConf: TEdit
      Left = 94
      Top = 55
      Width = 52
      Height = 21
      TabOrder = 3
      Text = '0.80'
    end
    object EdtSfThresh: TEdit
      Left = 206
      Top = 55
      Width = 52
      Height = 21
      TabOrder = 4
      Text = '0.80'
    end
    object EdtSensitivity: TEdit
      Left = 338
      Top = 55
      Width = 52
      Height = 21
      TabOrder = 5
      Text = '1.0'
    end
  end
  object PrgBar: TProgressBar
    Left = 8
    Top = 238
    Width = 624
    Height = 22
    BarColor = clDodgerblue
    TabOrder = 2
  end
  object MemoLog: TMemo
    Left = 8
    Top = 268
    Width = 624
    Height = 220
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object BtnStart: TButton
    Left = 464
    Top = 496
    Width = 80
    Height = 28
    Caption = 'Start'
    Default = True
    TabOrder = 4
    OnClick = BtnStartClick
  end
  object BtnStop: TButton
    Left = 552
    Top = 496
    Width = 80
    Height = 28
    Caption = 'Stop'
    Enabled = False
    TabOrder = 5
    OnClick = BtnStopClick
  end
  object Timer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerTimer
    Left = 16
    Top = 500
  end
end
