object FormBatIdent: TFormBatIdent
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'BatIdent'
  ClientHeight = 553
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
  object GrpClassifier: TGroupBox
    Left = 8
    Top = 130
    Width = 180
    Height = 113
    Caption = 'Classifier'
    TabOrder = 1
    object LblArea: TLabel
      Left = 8
      Top = 20
      Width = 27
      Height = 13
      Caption = 'Area:'
    end
    object LblKHz: TLabel
      Left = 8
      Top = 66
      Width = 21
      Height = 13
      Caption = 'kHz:'
    end
    object CbxArea: TComboBox
      Left = 8
      Top = 36
      Width = 164
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
    object CbxKHz: TComboBox
      Left = 8
      Top = 82
      Width = 164
      Height = 21
      Style = csDropDownList
      TabOrder = 1
    end
  end
  object GrpSensitivity: TGroupBox
    Left = 196
    Top = 130
    Width = 296
    Height = 113
    Caption = 'Detection sensitivity'
    TabOrder = 2
    object LblMinConf: TLabel
      Left = 8
      Top = 20
      Width = 75
      Height = 13
      Caption = 'Min confidence:'
    end
    object LblSfThresh: TLabel
      Left = 104
      Top = 20
      Width = 68
      Height = 13
      Caption = 'Species filter:'
    end
    object LblSensitivity: TLabel
      Left = 200
      Top = 20
      Width = 53
      Height = 13
      Caption = 'Sensitivity:'
    end
    object EdtMinConf: TEdit
      Left = 8
      Top = 36
      Width = 88
      Height = 21
      TabOrder = 0
      Text = '0.80'
    end
    object EdtSfThresh: TEdit
      Left = 104
      Top = 36
      Width = 88
      Height = 21
      TabOrder = 1
      Text = '0.80'
    end
    object EdtSensitivity: TEdit
      Left = 200
      Top = 36
      Width = 88
      Height = 21
      TabOrder = 2
      Text = '1.0'
    end
  end
  object GrpPerformance: TGroupBox
    Left = 500
    Top = 130
    Width = 132
    Height = 113
    Caption = 'Performance'
    TabOrder = 3
    object LblParallel: TLabel
      Left = 8
      Top = 20
      Width = 60
      Height = 13
      Caption = 'Parallel files:'
    end
    object CbxParallel: TComboBox
      Left = 8
      Top = 36
      Width = 116
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
  end
  object PrgBar: TProgressBar
    Left = 8
    Top = 251
    Width = 624
    Height = 22
    BarColor = clDodgerblue
    TabOrder = 4
  end
  object MemoLog: TMemo
    Left = 8
    Top = 281
    Width = 624
    Height = 220
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object BtnStart: TButton
    Left = 464
    Top = 509
    Width = 80
    Height = 28
    Caption = 'Start'
    Default = True
    TabOrder = 6
    OnClick = BtnStartClick
  end
  object BtnStop: TButton
    Left = 552
    Top = 509
    Width = 80
    Height = 28
    Caption = 'Stop'
    Enabled = False
    TabOrder = 7
    OnClick = BtnStopClick
  end
  object Timer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerTimer
    Left = 16
    Top = 513
  end
end
