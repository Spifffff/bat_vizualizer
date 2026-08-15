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
  PixelsPerInch = 96
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object BtnOpen: TButton
      Left = 8
      Top = 10
      Width = 90
      Height = 30
      Caption = 'Open WAV'
      TabOrder = 0
      OnClick = BtnOpenClick
    end
    object BtnPlay: TButton
      Left = 106
      Top = 10
      Width = 70
      Height = 30
      Caption = 'Play'
      Enabled = False
      TabOrder = 1
      OnClick = BtnPlayClick
    end
    object BtnPause: TButton
      Left = 182
      Top = 10
      Width = 70
      Height = 30
      Caption = 'Pause'
      Enabled = False
      TabOrder = 2
      OnClick = BtnPauseClick
    end
    object BtnStop: TButton
      Left = 258
      Top = 10
      Width = 70
      Height = 30
      Caption = 'Stop'
      Enabled = False
      TabOrder = 3
      OnClick = BtnStopClick
    end
    object LblWindow: TLabel
      Left = 346
      Top = 18
      Width = 59
      Height = 13
      Caption = 'Window fn:'
    end
    object CbxWindow: TComboBox
      Left = 410
      Top = 14
      Width = 110
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
    object LblFFTSize: TLabel
      Left = 534
      Top = 18
      Width = 44
      Height = 13
      Caption = 'FFT size:'
    end
    object CbxFFTSize: TComboBox
      Left = 582
      Top = 14
      Width = 80
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
    object LblSpeed: TLabel
      Left = 676
      Top = 18
      Width = 70
      Height = 13
      Caption = 'Speed: 10%'
    end
    object LblPlayMode: TLabel
      Left = 762
      Top = 18
      Width = 52
      Height = 13
      Caption = 'Play mode:'
    end
    object CbxPlayMode: TComboBox
      Left = 818
      Top = 14
      Width = 165
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 6
      Text = 'VLC'
      OnChange = CbxPlayModeChange
      Items.Strings = (
        'VLC'
        'Native (correct pitch)')
    end
    object LblGainCaption: TLabel
      Left = 8
      Top = 61
      Width = 27
      Height = 13
      Caption = 'Gain:'
    end
    object TrkGain: TTrackBar
      Left = 42
      Top = 52
      Width = 140
      Height = 26
      Max = 80
      Frequency = 10
      Position = 0
      TickStyle = tsNone
      TabOrder = 7
      OnChange = TrkGainChange
    end
    object LblGainVal: TLabel
      Left = 188
      Top = 61
      Width = 45
      Height = 13
      Caption = '0 dB'
    end
    object ChkBGSub: TCheckBox
      Left = 252
      Top = 57
      Width = 110
      Height = 17
      Caption = 'BG Subtract'
      TabOrder = 8
      OnClick = ChkBGSubChange
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
  object ZoomBar: TScrollBar
    Left = 0
    Top = 707
    Width = 1200
    Height = 20
    Align = alBottom
    Kind = sbHorizontal
    Max = 1000
    TabOrder = 1
    OnChange = ZoomBarChange
  end
  object PaintBox: TPaintBox
    Left = 0
    Top = 80
    Width = 1200
    Height = 627
    Align = alClient
    OnMouseDown = PaintBoxMouseDown
    OnMouseMove = PaintBoxMouseMove
    OnMouseUp = PaintBoxMouseUp
    OnPaint = PaintBoxPaint
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
end
