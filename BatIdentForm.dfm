object FormBatIdent: TFormBatIdent
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'BatIdent'
  ClientHeight = 583
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Padding.Left = 8
  Padding.Top = 8
  Padding.Right = 8
  Padding.Bottom = 8
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object LblScore: TLabel
    AlignWithMargins = True
    Left = 11
    Top = 311
    Width = 618
    Height = 22
    Align = alTop
    Caption = 'No results yet.'
    Layout = tlCenter
  end
  object GrpFolders: TGroupBox
    Left = 8
    Top = 8
    Width = 624
    Height = 76
    Align = alTop
    Caption = 'Folders'
    TabOrder = 0
    object LblWavFolder: TLabel
      Left = 8
      Top = 20
      Width = 58
      Height = 13
      Caption = 'WAV folder:'
    end
    object LblBattyFolder: TLabel
      Left = 8
      Top = 48
      Width = 98
      Height = 13
      Caption = 'BattyBirdNET folder:'
    end
    object EdtWavFolder: TEdit
      Left = 116
      Top = 16
      Width = 416
      Height = 21
      TabOrder = 0
    end
    object BtnBrowseWav: TButton
      Left = 534
      Top = 15
      Width = 80
      Height = 23
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = BtnBrowseWavClick
    end
    object EdtBattyFolder: TEdit
      Left = 116
      Top = 44
      Width = 416
      Height = 21
      TabOrder = 2
    end
    object BtnBrowseBatty: TButton
      Left = 534
      Top = 43
      Width = 80
      Height = 23
      Caption = 'Browse...'
      TabOrder = 3
      OnClick = BtnBrowseBattyClick
    end
  end
  object PanelParams: TPanel
    Left = 8
    Top = 84
    Width = 624
    Height = 164
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object GrpClassifier: TGroupBox
      Left = 0
      Top = 0
      Width = 208
      Height = 164
      Align = alLeft
      Caption = 'Classifier'
      TabOrder = 0
      DesignSize = (
        208
        164)
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
        Width = 192
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        Style = csDropDownList
        TabOrder = 0
      end
      object CbxKHz: TComboBox
        Left = 8
        Top = 82
        Width = 192
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        Style = csDropDownList
        TabOrder = 1
      end
    end
    object GrpSensitivity: TGroupBox
      Left = 208
      Top = 0
      Width = 208
      Height = 164
      Align = alLeft
      Caption = 'Detection sensitivity'
      TabOrder = 1
      DesignSize = (
        208
        164)
      object LblMinConf: TLabel
        Left = 8
        Top = 20
        Width = 100
        Height = 13
        Caption = 'Min confidence: 0.80'
      end
      object LblSfThresh: TLabel
        Left = 8
        Top = 66
        Width = 90
        Height = 13
        Caption = 'Species filter: 0.80'
      end
      object LblSensitivity: TLabel
        Left = 8
        Top = 112
        Width = 78
        Height = 13
        Caption = 'Sensitivity: 1.00'
      end
      object TrkMinConf: TTrackBar
        Left = 8
        Top = 36
        Width = 192
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Max = 99
        Min = 1
        Frequency = 10
        Position = 80
        TabOrder = 0
        TickStyle = tsNone
        OnChange = TrkMinConfChange
      end
      object TrkSfThresh: TTrackBar
        Left = 8
        Top = 82
        Width = 192
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Max = 99
        Min = 1
        Frequency = 10
        Position = 80
        TabOrder = 1
        TickStyle = tsNone
        OnChange = TrkSfThreshChange
      end
      object TrkSensitivity: TTrackBar
        Left = 8
        Top = 128
        Width = 192
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Max = 150
        Min = 50
        Frequency = 10
        Position = 100
        TabOrder = 2
        TickStyle = tsNone
        OnChange = TrkSensitivityChange
      end
    end
    object GrpPerformance: TGroupBox
      Left = 416
      Top = 0
      Width = 208
      Height = 164
      Align = alClient
      Caption = 'Performance'
      TabOrder = 2
      DesignSize = (
        208
        164)
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
        Width = 192
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        Style = csDropDownList
        TabOrder = 0
      end
    end
  end
  object PrgBar: TProgressBar
    AlignWithMargins = True
    Left = 8
    Top = 281
    Width = 624
    Height = 22
    Margins.Left = 0
    Margins.Top = 5
    Margins.Right = 0
    Margins.Bottom = 5
    Align = alTop
    BarColor = clDodgerblue
    TabOrder = 2
    ExplicitTop = 276
  end
  object MemoLog: TMemo
    Left = 8
    Top = 336
    Width = 624
    Height = 198
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitTop = 311
    ExplicitHeight = 220
  end
  object PanelButtons: TPanel
    Left = 8
    Top = 534
    Width = 624
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitTop = 531
    DesignSize = (
      624
      41)
    object BtnStart: TButton
      Left = 456
      Top = 8
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Start'
      Default = True
      TabOrder = 0
      OnClick = BtnStartClick
    end
    object BtnStop: TButton
      Left = 544
      Top = 8
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Stop'
      Enabled = False
      TabOrder = 1
      OnClick = BtnStopClick
    end
  end
  object Timer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerTimer
    Left = 16
    Top = 540
  end
end
