object FormMain: TFormMain
  Left = 100
  Top = 80
  Caption = 'Bat Visualizer'
  ClientHeight = 750
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object SplitterRight: TSplitter
    Left = 878
    Top = 0
    Width = 4
    Height = 727
    Align = alRight
    MinSize = 118
    ResizeStyle = rsUpdate
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 180
    Height = 727
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object LblSpeed: TLabel
      Left = 8
      Top = 74
      Width = 35
      Height = 13
      Caption = 'Speed:'
    end
    object LblWindow: TLabel
      Left = 8
      Top = 122
      Width = 61
      Height = 13
      Caption = 'Window fn:'
    end
    object LblFFTSize: TLabel
      Left = 8
      Top = 168
      Width = 43
      Height = 13
      Caption = 'FFT size:'
    end
    object LblGainCaption: TLabel
      Left = 8
      Top = 214
      Width = 27
      Height = 13
      Caption = 'Gain:'
    end
    object LblGainVal: TLabel
      Left = 50
      Top = 214
      Width = 22
      Height = 13
      Caption = '0 dB'
    end
    object LblColorScheme: TLabel
      Left = 8
      Top = 316
      Width = 72
      Height = 13
      Caption = 'Color scheme:'
    end
    object LblFloor: TLabel
      Left = 8
      Top = 368
      Width = 71
      Height = 13
      Caption = 'Floor: -100 dB'
    end
    object LblCeiling: TLabel
      Left = 8
      Top = 418
      Width = 64
      Height = 13
      Caption = 'Ceiling: 0 dB'
    end
    object LblMaxFreq: TLabel
      Left = 8
      Top = 468
      Width = 61
      Height = 13
      Caption = 'Max: 96 kHz'
    end
    object LblSave: TLabel
      Left = 8
      Top = 554
      Width = 65
      Height = 13
      Caption = 'Save as PNG:'
    end
    object BtnOpen: TButton
      Left = 8
      Top = 10
      Width = 164
      Height = 28
      Caption = 'Open audio'
      TabOrder = 0
      OnClick = BtnOpenClick
    end
    object BtnPlay: TButton
      Left = 8
      Top = 44
      Width = 50
      Height = 26
      Caption = 'Play'
      Enabled = False
      TabOrder = 1
      OnClick = BtnPlayClick
    end
    object BtnPause: TButton
      Left = 63
      Top = 44
      Width = 50
      Height = 26
      Caption = 'Pause'
      Enabled = False
      TabOrder = 2
      OnClick = BtnPauseClick
    end
    object BtnStop: TButton
      Left = 118
      Top = 44
      Width = 54
      Height = 26
      Caption = 'Stop'
      Enabled = False
      TabOrder = 3
      OnClick = BtnStopClick
    end
    object CbxSpeed: TComboBox
      Left = 8
      Top = 90
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 1
      TabOrder = 4
      Text = '10%'
      Items.Strings = (
        '5%'
        '10%'
        '12.5%'
        '20%'
        '25%'
        '50%'
        '100%')
    end
    object CbxWindow: TComboBox
      Left = 8
      Top = 138
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 1
      TabOrder = 5
      Text = 'Hann'
      OnChange = CbxWindowChange
      Items.Strings = (
        'Rectangular'
        'Hann'
        'Hamming'
        'Blackman'
        'Flat-Top')
    end
    object CbxFFTSize: TComboBox
      Left = 8
      Top = 184
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 5
      TabOrder = 6
      Text = '2048'
      OnChange = CbxFFTSizeChange
      Items.Strings = (
        '64'
        '128'
        '256'
        '512'
        '1024'
        '2048'
        '4096'
        '8192'
        '16384')
    end
    object TrkGain: TTrackBar
      Left = 4
      Top = 230
      Width = 172
      Height = 26
      Max = 80
      Frequency = 10
      TabOrder = 7
      TickStyle = tsNone
      OnChange = TrkGainChange
    end
    object ChkBGSub: TCheckBox
      Left = 8
      Top = 264
      Width = 164
      Height = 17
      Caption = 'Reduce noise'
      Checked = True
      State = cbChecked
      TabOrder = 8
      OnClick = ChkBGSubChange
    end
    object ChkFilter: TCheckBox
      Left = 8
      Top = 284
      Width = 164
      Height = 17
      Caption = 'High-pass + gate'
      Checked = True
      State = cbChecked
      TabOrder = 13
      OnClick = ChkFilterChange
    end
    object CbxColorScheme: TComboBox
      Left = 8
      Top = 332
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 2
      TabOrder = 9
      Text = 'Magma'
      OnChange = CbxColorSchemeChange
      Items.Strings = (
        'Viridis'
        'Inferno'
        'Magma'
        'Grayscale'
        'Grayscale (inv)'
        'Plasma'
        'Cividis'
        'Mako'
        'Rocket'
        'Spectral')
    end
    object TrkFloor: TTrackBar
      Left = 4
      Top = 384
      Width = 172
      Height = 26
      Max = 0
      Min = -100
      Frequency = 10
      Position = -100
      TabOrder = 10
      TickStyle = tsNone
      OnChange = TrkFloorChange
    end
    object TrkCeiling: TTrackBar
      Left = 4
      Top = 434
      Width = 172
      Height = 26
      Max = 60
      Min = -40
      Frequency = 10
      TabOrder = 11
      TickStyle = tsNone
      OnChange = TrkCeilingChange
    end
    object TrkMaxFreq: TTrackBar
      Left = 4
      Top = 484
      Width = 172
      Height = 26
      Max = 96
      Min = 1
      Frequency = 10
      Position = 96
      TabOrder = 12
      TickStyle = tsNone
      OnChange = TrkMaxFreqChange
    end
    object BtnAutoLevels: TButton
      Left = 8
      Top = 514
      Width = 164
      Height = 26
      Caption = 'Auto floor / ceiling / freq'
      Enabled = False
      TabOrder = 17
      OnClick = BtnAutoLevelsClick
    end
    object CbxSaveTarget: TComboBox
      Left = 8
      Top = 570
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 2
      TabOrder = 14
      Text = 'Combined'
      Items.Strings = (
        'Waveform'
        'Spectrogram'
        'Combined')
    end
    object BtnSavePNG: TButton
      Left = 8
      Top = 596
      Width = 164
      Height = 26
      Caption = 'Save PNG...'
      Enabled = False
      TabOrder = 15
      OnClick = BtnSavePNGClick
    end
    object BtnSaveMp3: TButton
      Left = 8
      Top = 626
      Width = 164
      Height = 26
      Caption = 'Save MP3...'
      Enabled = False
      TabOrder = 16
      OnClick = BtnSaveMp3Click
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 727
    Width = 1200
    Height = 23
    Panels = <
      item
        Text = 'No file loaded'
        Width = 500
      end
      item
        Width = 250
      end
      item
        Width = 200
      end>
  end
  object PanelRight: TPanel
    Left = 882
    Top = 0
    Width = 318
    Height = 727
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 2
    object PanelToggle: TPanel
      Left = 0
      Top = 0
      Width = 18
      Height = 727
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object BtnTogglePanel: TButton
        Left = 0
        Top = 0
        Width = 18
        Height = 727
        Align = alClient
        Caption = '<'
        TabOrder = 0
        OnClick = BtnTogglePanelClick
      end
    end
    object PanelFileContent: TPanel
      Left = 18
      Top = 0
      Width = 300
      Height = 727
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object BtnSelectFolder: TButton
        Left = 0
        Top = 0
        Width = 300
        Height = 28
        Align = alTop
        Caption = 'Select folder...'
        TabOrder = 0
        OnClick = BtnSelectFolderClick
      end
      object FileListView: TListView
        Left = 0
        Top = 28
        Width = 300
        Height = 699
        Align = alClient
        Columns = <
          item
            Caption = 'Timestamp'
            Width = 225
          end
          item
            Caption = 'Confidence'
            Width = 80
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
        OnClick = FileListViewClick
        OnColumnClick = FileListViewColumnClick
        OnResize = FileListViewResize
      end
    end
  end
  object PanelMain: TPanel
    Left = 180
    Top = 0
    Width = 698
    Height = 727
    Align = alClient
    BevelOuter = bvNone
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 1
    object WaveformBox: TPaintBox
      Left = 0
      Top = 0
      Width = 698
      Height = 120
      Align = alTop
      OnMouseDown = WaveformBoxMouseDown
      OnMouseMove = WaveformBoxMouseMove
      OnMouseUp = WaveformBoxMouseUp
      OnPaint = WaveformBoxPaint
      ExplicitWidth = 1020
    end
    object Splitter1: TSplitter
      Left = 0
      Top = 120
      Width = 698
      Height = 4
      Cursor = crVSplit
      Align = alTop
      MinSize = 40
      ResizeStyle = rsUpdate
      ExplicitWidth = 1020
    end
    object PaintBox: TPaintBox
      Left = 0
      Top = 124
      Width = 698
      Height = 583
      Align = alClient
      OnMouseDown = PaintBoxMouseDown
      OnMouseMove = PaintBoxMouseMove
      OnMouseUp = PaintBoxMouseUp
      OnPaint = PaintBoxPaint
      ExplicitWidth = 1020
    end
    object ZoomBar: TScrollBar
      Left = 0
      Top = 707
      Width = 698
      Height = 20
      Align = alBottom
      Max = 1000
      PageSize = 0
      TabOrder = 0
      OnChange = ZoomBarChange
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 
      'Audio files|*.wav;*.mp3|WAV files|*.wav|MP3 files|*.mp3|All file' +
      's|*.*'
    Left = 1080
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'png'
    Filter = 'PNG image|*.png'
    Options = [ofOverwritePrompt, ofPathMustExist]
    Left = 1080
    Top = 40
  end
  object SaveDialogMp3: TSaveDialog
    DefaultExt = 'mp3'
    Filter = 'MP3 audio|*.mp3'
    Options = [ofOverwritePrompt, ofPathMustExist]
    Left = 1080
    Top = 72
  end
  object Timer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = TimerTick
    Left = 1130
    Top = 8
  end
  object RenderTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = RenderTimerTick
    Left = 1130
    Top = 40
  end
end
