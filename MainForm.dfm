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
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 180
    Height = 727
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object LblWindow: TLabel
      Left = 8
      Top = 82
      Width = 61
      Height = 13
      Caption = 'Window fn:'
    end
    object LblFFTSize: TLabel
      Left = 8
      Top = 128
      Width = 43
      Height = 13
      Caption = 'FFT size:'
    end
    object LblGainCaption: TLabel
      Left = 8
      Top = 174
      Width = 27
      Height = 13
      Caption = 'Gain:'
    end
    object LblGainVal: TLabel
      Left = 50
      Top = 174
      Width = 22
      Height = 13
      Caption = '0 dB'
    end
    object LblColorScheme: TLabel
      Left = 8
      Top = 256
      Width = 72
      Height = 13
      Caption = 'Color scheme:'
    end
    object LblFloor: TLabel
      Left = 8
      Top = 308
      Width = 71
      Height = 13
      Caption = 'Floor: -100 dB'
    end
    object LblCeiling: TLabel
      Left = 8
      Top = 358
      Width = 64
      Height = 13
      Caption = 'Ceiling: 0 dB'
    end
    object BtnOpen: TButton
      Left = 8
      Top = 10
      Width = 164
      Height = 28
      Caption = 'Open WAV'
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
    object CbxWindow: TComboBox
      Left = 8
      Top = 98
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 1
      TabOrder = 4
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
      Top = 144
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 3
      TabOrder = 5
      Text = '4096'
      OnChange = CbxFFTSizeChange
      Items.Strings = (
        '512'
        '1024'
        '2048'
        '4096'
        '8192'
        '16384')
    end
    object TrkGain: TTrackBar
      Left = 4
      Top = 190
      Width = 172
      Height = 26
      Max = 80
      Frequency = 10
      TabOrder = 6
      TickStyle = tsNone
      OnChange = TrkGainChange
    end
    object ChkBGSub: TCheckBox
      Left = 8
      Top = 224
      Width = 164
      Height = 17
      Caption = 'Subtract background'
      TabOrder = 7
      OnClick = ChkBGSubChange
    end
    object CbxColorScheme: TComboBox
      Left = 8
      Top = 272
      Width = 164
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 8
      Text = 'Viridis'
      OnChange = CbxColorSchemeChange
      Items.Strings = (
        'Viridis'
        'Inferno'
        'Magma'
        'Grayscale'
        'Plasma'
        'Cividis'
        'Mako'
        'Rocket'
        'Spectral')
    end
    object TrkFloor: TTrackBar
      Left = 4
      Top = 324
      Width = 172
      Height = 26
      Max = -20
      Min = -120
      Frequency = 10
      Position = -100
      TabOrder = 9
      TickStyle = tsNone
      OnChange = TrkFloorChange
    end
    object TrkCeiling: TTrackBar
      Left = 4
      Top = 374
      Width = 172
      Height = 26
      Max = 40
      Min = -60
      Frequency = 10
      TabOrder = 10
      TickStyle = tsNone
      OnChange = TrkCeilingChange
    end
    object LblMaxFreq: TLabel
      Left = 8
      Top = 408
      Width = 63
      Height = 13
      Caption = 'Max: 96 kHz'
    end
    object TrkMaxFreq: TTrackBar
      Left = 4
      Top = 424
      Width = 172
      Height = 26
      Max = 96
      Min = 1
      Frequency = 10
      Position = 96
      TabOrder = 11
      TickStyle = tsNone
      OnChange = TrkMaxFreqChange
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
  object PanelMain: TPanel
    Left = 180
    Top = 0
    Width = 1020
    Height = 727
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object WaveformBox: TPaintBox
      Left = 0
      Top = 0
      Width = 1020
      Height = 120
      Align = alTop
      OnMouseDown = WaveformBoxMouseDown
      OnMouseMove = WaveformBoxMouseMove
      OnMouseUp = WaveformBoxMouseUp
      OnMouseWheel = ZoomMouseWheel
      OnPaint = WaveformBoxPaint
    end
    object Splitter1: TSplitter
      Left = 0
      Top = 120
      Width = 1020
      Height = 4
      Cursor = crVSplit
      Align = alTop
      MinSize = 40
      ResizeStyle = rsUpdate
    end
    object PaintBox: TPaintBox
      Left = 0
      Top = 124
      Width = 1020
      Height = 583
      Align = alClient
      OnMouseDown = PaintBoxMouseDown
      OnMouseMove = PaintBoxMouseMove
      OnMouseUp = PaintBoxMouseUp
      OnMouseWheel = ZoomMouseWheel
      OnPaint = PaintBoxPaint
    end
    object ZoomBar: TScrollBar
      Left = 0
      Top = 707
      Width = 1020
      Height = 20
      Align = alBottom
      Max = 1000
      PageSize = 0
      TabOrder = 0
      OnChange = ZoomBarChange
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'WAV files|*.wav|All files|*.*'
    Left = 1080
    Top = 8
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
