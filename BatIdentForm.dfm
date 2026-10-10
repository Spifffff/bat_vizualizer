object FormBatIdent: TFormBatIdent
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Bat identifyer'
  ClientHeight = 501
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
    Top = 239
    Width = 618
    Height = 13
    Align = alTop
    Caption = 'No results yet.'
    Layout = tlCenter
    ExplicitTop = 283
    ExplicitWidth = 71
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
      OnChange = ModelSettingChange
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
    Height = 120
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object GrpClassifier: TGroupBox
      Left = 0
      Top = 0
      Width = 208
      Height = 120
      Align = alLeft
      Caption = 'Classifier'
      TabOrder = 0
      ExplicitHeight = 164
      DesignSize = (
        208
        120)
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
      object ImgArea: TImage
        Left = 182
        Top = 38
        Width = 16
        Height = 16
        Center = True
        Picture.Data = {
          0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
          001008060000001FF3FF61000001674944415478DA6364A010306213FCFFFF3F
          DB83070F0CFFFDFB670856C4C8784E5151F10290FE85D700A046A6BB77EFB603
          99B940CC8926F71548F5AAAAAAD6633500AA793E901947C0D593555454F2300C
          B873E74E0B90AA46B3752DD0D93640A6388AAD8C8C05CACACA13E106BC7EFD9A
          F7E3C78F2F804C2E34038C818A6B80CC403457BC001A200394FB0B36E0DEBD7B
          21C0005B4D62045803BD720C6CC0EDDBB72B80A6B5A3AB60666636FCFBF76F1D
          1617805C970D0CD06930038A8006F4624411236303D065408AB11E8B01454003
          FA19A101E809A4B66151D4083508C300262626372525A5DD60031E3F7ECCF9E3
          C78F974085BC68EA5A8162D780062D4533F82DD0FF52A084058F46A0371AB0D8
          048A99CD409C8A265E0A34A0071E8D505319815E59043424065FD003D54D076A
          CE06AAFB8F62005412941ABB80CC6C20E64093FB0CA4FA7126656400F40E3B90
          3202DA620AA47F82321330C04099E937464C3150080050EF9611386E69950000
          00106465424737383645303642303741413732393745381EAA95000000004945
          4E44AE426082}
        OnClick = ImgInfoClick
      end
      object ImgKHz: TImage
        Left = 182
        Top = 84
        Width = 16
        Height = 16
        Center = True
        Picture.Data = {
          0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
          001008060000001FF3FF61000001674944415478DA6364A010306213FCFFFF3F
          DB83070F0CFFFDFB670856C4C8784E5151F10290FE85D700A046A6BB77EFB603
          99B940CC8926F71548F5AAAAAAD6633500AA793E901947C0D593555454F2300C
          B873E74E0B90AA46B3752DD0D93640A6388AAD8C8C05CACACA13E106BC7EFD9A
          F7E3C78F2F804C2E34038C818A6B80CC403457BC001A200394FB0B36E0DEBD7B
          21C0005B4D62045803BD720C6CC0EDDBB72B80A6B5A3AB60666636FCFBF76F1D
          1617805C970D0CD06930038A8006F4624411236303D065408AB11E8B01454003
          FA19A101E809A4B66151D4083508C300262626372525A5DD60031E3F7ECCF9E3
          C78F974085BC68EA5A8162D780062D4533F82DD0FF52A084058F46A0371AB0D8
          048A99CD409C8A265E0A34A0071E8D505319815E59043424065FD003D54D076A
          CE06AAFB8F62005412941ABB80CC6C20E64093FB0CA4FA7126656400F40E3B90
          3202DA620AA47F82321330C04099E937464C3150080050EF9611386E69950000
          00106465424737383645303642303741413732393745381EAA95000000004945
          4E44AE426082}
        OnClick = ImgInfoClick
      end
      object LblModelHint: TLabel
        Left = 8
        Top = 110
        Width = 192
        Height = 48
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
      object CbxArea: TComboBox
        Left = 8
        Top = 36
        Width = 169
        Height = 21
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        OnChange = ModelSettingChange
      end
      object CbxKHz: TComboBox
        Left = 8
        Top = 82
        Width = 169
        Height = 21
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 1
        OnChange = ModelSettingChange
      end
    end
    object GrpSensitivity: TGroupBox
      Left = 208
      Top = 0
      Width = 208
      Height = 120
      Align = alLeft
      Caption = 'Detection sensitivity'
      TabOrder = 1
      ExplicitHeight = 164
      DesignSize = (
        208
        120)
      object LblMinConf: TLabel
        Left = 8
        Top = 20
        Width = 100
        Height = 13
        Caption = 'Min confidence: 0.80'
      end
      object LblSensitivity: TLabel
        Left = 8
        Top = 66
        Width = 78
        Height = 13
        Caption = 'Sensitivity: 1.00'
      end
      object ImgMinConf: TImage
        Left = 182
        Top = 38
        Width = 16
        Height = 16
        Center = True
        Picture.Data = {
          0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
          001008060000001FF3FF61000001674944415478DA6364A010306213FCFFFF3F
          DB83070F0CFFFDFB670856C4C8784E5151F10290FE85D700A046A6BB77EFB603
          99B940CC8926F71548F5AAAAAAD6633500AA793E901947C0D593555454F2300C
          B873E74E0B90AA46B3752DD0D93640A6388AAD8C8C05CACACA13E106BC7EFD9A
          F7E3C78F2F804C2E34038C818A6B80CC403457BC001A200394FB0B36E0DEBD7B
          21C0005B4D62045803BD720C6CC0EDDBB72B80A6B5A3AB60666636FCFBF76F1D
          1617805C970D0CD06930038A8006F4624411236303D065408AB11E8B01454003
          FA19A101E809A4B66151D4083508C300262626372525A5DD60031E3F7ECCF9E3
          C78F974085BC68EA5A8162D780062D4533F82DD0FF52A084058F46A0371AB0D8
          048A99CD409C8A265E0A34A0071E8D505319815E59043424065FD003D54D076A
          CE06AAFB8F62005412941ABB80CC6C20E64093FB0CA4FA7126656400F40E3B90
          3202DA620AA47F82321330C04099E937464C3150080050EF9611386E69950000
          00106465424737383645303642303741413732393745381EAA95000000004945
          4E44AE426082}
        OnClick = ImgInfoClick
      end
      object ImgSensitivity: TImage
        Left = 182
        Top = 84
        Width = 16
        Height = 16
        Center = True
        Picture.Data = {
          0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
          001008060000001FF3FF61000001674944415478DA6364A010306213FCFFFF3F
          DB83070F0CFFFDFB670856C4C8784E5151F10290FE85D700A046A6BB77EFB603
          99B940CC8926F71548F5AAAAAAD6633500AA793E901947C0D593555454F2300C
          B873E74E0B90AA46B3752DD0D93640A6388AAD8C8C05CACACA13E106BC7EFD9A
          F7E3C78F2F804C2E34038C818A6B80CC403457BC001A200394FB0B36E0DEBD7B
          21C0005B4D62045803BD720C6CC0EDDBB72B80A6B5A3AB60666636FCFBF76F1D
          1617805C970D0CD06930038A8006F4624411236303D065408AB11E8B01454003
          FA19A101E809A4B66151D4083508C300262626372525A5DD60031E3F7ECCF9E3
          C78F974085BC68EA5A8162D780062D4533F82DD0FF52A084058F46A0371AB0D8
          048A99CD409C8A265E0A34A0071E8D505319815E59043424065FD003D54D076A
          CE06AAFB8F62005412941ABB80CC6C20E64093FB0CA4FA7126656400F40E3B90
          3202DA620AA47F82321330C04099E937464C3150080050EF9611386E69950000
          00106465424737383645303642303741413732393745381EAA95000000004945
          4E44AE426082}
        OnClick = ImgInfoClick
      end
      object TrkMinConf: TTrackBar
        Left = 8
        Top = 36
        Width = 175
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
      object TrkSensitivity: TTrackBar
        Left = 8
        Top = 82
        Width = 175
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Max = 150
        Min = 50
        Frequency = 10
        Position = 100
        TabOrder = 1
        TickStyle = tsNone
        OnChange = TrkSensitivityChange
      end
    end
    object GrpPerformance: TGroupBox
      Left = 416
      Top = 0
      Width = 208
      Height = 120
      Align = alClient
      Caption = 'Performance'
      TabOrder = 2
      ExplicitHeight = 164
      DesignSize = (
        208
        120)
      object LblParallel: TLabel
        Left = 8
        Top = 20
        Width = 60
        Height = 13
        Caption = 'Parallel files:'
      end
      object ImgParallel: TImage
        Left = 182
        Top = 38
        Width = 16
        Height = 16
        Center = True
        Picture.Data = {
          0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000
          001008060000001FF3FF61000001674944415478DA6364A010306213FCFFFF3F
          DB83070F0CFFFDFB670856C4C8784E5151F10290FE85D700A046A6BB77EFB603
          99B940CC8926F71548F5AAAAAAD6633500AA793E901947C0D593555454F2300C
          B873E74E0B90AA46B3752DD0D93640A6388AAD8C8C05CACACA13E106BC7EFD9A
          F7E3C78F2F804C2E34038C818A6B80CC403457BC001A200394FB0B36E0DEBD7B
          21C0005B4D62045803BD720C6CC0EDDBB72B80A6B5A3AB60666636FCFBF76F1D
          1617805C970D0CD06930038A8006F4624411236303D065408AB11E8B01454003
          FA19A101E809A4B66151D4083508C300262626372525A5DD60031E3F7ECCF9E3
          C78F974085BC68EA5A8162D780062D4533F82DD0FF52A084058F46A0371AB0D8
          048A99CD409C8A265E0A34A0071E8D505319815E59043424065FD003D54D076A
          CE06AAFB8F62005412941ABB80CC6C20E64093FB0CA4FA7126656400F40E3B90
          3202DA620AA47F82321330C04099E937464C3150080050EF9611386E69950000
          00106465424737383645303642303741413732393745381EAA95000000004945
          4E44AE426082}
        OnClick = ImgInfoClick
      end
      object CbxParallel: TComboBox
        Left = 8
        Top = 36
        Width = 169
        Height = 21
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
    end
  end
  object PrgBar: TProgressBar
    AlignWithMargins = True
    Left = 8
    Top = 209
    Width = 624
    Height = 22
    Margins.Left = 0
    Margins.Top = 5
    Margins.Right = 0
    Margins.Bottom = 5
    Align = alTop
    BarColor = clDodgerblue
    TabOrder = 2
    ExplicitTop = 253
  end
  object MemoLog: TMemo
    Left = 8
    Top = 255
    Width = 624
    Height = 197
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitTop = 299
    ExplicitHeight = 235
  end
  object PanelButtons: TPanel
    Left = 8
    Top = 452
    Width = 624
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitTop = 534
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
