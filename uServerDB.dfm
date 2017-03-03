object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = #1057#1077#1088#1074#1077#1088' '#1041#1044
  ClientHeight = 198
  ClientWidth = 327
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Visible = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object chkAutoStart: TCheckBox
    Left = 24
    Top = 165
    Width = 209
    Height = 17
    Caption = #1047#1072#1087#1091#1089#1082#1072#1090#1100' '#1074#1084#1077#1089#1090#1077' '#1089' '#1054#1057
    Enabled = False
    TabOrder = 0
    OnMouseUp = chkAutoStartMouseUp
  end
  object btnExit: TButton
    Left = 266
    Top = 161
    Width = 49
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 1
    OnClick = btnExitClick
  end
  object lbeIPHost: TLabeledEdit
    Left = 24
    Top = 23
    Width = 281
    Height = 24
    EditLabel.Width = 75
    EditLabel.Height = 16
    EditLabel.Caption = #1048#1084#1103' '#1089#1077#1088#1074#1077#1088#1072
    TabOrder = 2
  end
  object lbeIPPort: TLabeledEdit
    Left = 24
    Top = 72
    Width = 281
    Height = 24
    EditLabel.Width = 75
    EditLabel.Height = 16
    EditLabel.Caption = #1057#1074#1086#1081' IP '#1087#1086#1088#1090
    TabOrder = 3
    Text = '888'
  end
  object lbeDBName: TLabeledEdit
    Left = 24
    Top = 121
    Width = 241
    Height = 24
    EditLabel.Width = 107
    EditLabel.Height = 16
    EditLabel.Caption = #1056#1072#1089#1087#1086#1083#1086#1078#1077#1085#1080#1077' '#1041#1044
    TabOrder = 4
  end
  object btnDir: TButton
    Left = 271
    Top = 121
    Width = 34
    Height = 25
    Caption = '...'
    Enabled = False
    TabOrder = 5
    OnClick = btnDirClick
  end
end
