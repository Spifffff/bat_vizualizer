{ BatViz
  Copyright (C) 2026

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>. }



unit NightlyActivityForm;



interface



uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Themes;

type
  TNightlyActivityItem = record
    DateTime: TDateTime;
    SpeciesName: string;
  end;

  TFormNightlyActivity = class(TForm)
    PanelTop: TPanel;
    LblDay: TLabel;
    CbxDay: TComboBox;
    ChartBox: TPaintBox;
    procedure CbxDayChange(Sender: TObject);
    procedure ChartBoxPaint(Sender: TObject);
  private
    { Distinct "monitoring nights" (date-only, night runs noon-to-noon so an
      evening-into-dawn session is never split across two calendar dates),
      sorted ascending. }
    FNightDates: TArray<TDateTime>;
    FSpeciesNames: TArray<string>;
    FSpeciesColors: TArray<TColor>;
    FCountsAll: TArray<TArray<Integer>>;             // [hourSlot 0..23][speciesIdx]
    FCountsByNight: TArray<TArray<TArray<Integer>>>;  // [nightIdx][hourSlot][speciesIdx]
    function NightDateOf(ADateTime: TDateTime): TDateTime;
    function HourSlotOf(ADateTime: TDateTime): Integer;
    function HourLabelForSlot(ASlot: Integer): string;
    function ColorForFraction(AFraction: Double): TColor;
    function GetSelectedCounts: TArray<TArray<Integer>>;
  public
    procedure LoadItems(const AItems: TArray<TNightlyActivityItem>);
  end;

// Builds the form, loads AItems and shows it modally, centered on the screen.
procedure ShowNightlyActivity(AOwner: TComponent; const AItems: TArray<TNightlyActivityItem>);



implementation



{$R *.dfm}



// Blends from C1 towards C2 by fraction T (0 = C1, 1 = C2).
function BlendColors(C1, C2: TColor; T: Double): TColor;
var
  RGB1, RGB2: Longint;
begin
  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);
  Result := RGB(
    Round(GetRValue(RGB1) + (GetRValue(RGB2) - GetRValue(RGB1)) * T),
    Round(GetGValue(RGB1) + (GetGValue(RGB2) - GetGValue(RGB1)) * T),
    Round(GetBValue(RGB1) + (GetBValue(RGB2) - GetBValue(RGB1)) * T));
end;



// Standard HSL -> RGB conversion. H in degrees [0, 360), S and L in [0, 1].
function HSLToRGB(H, S, L: Double): TColor;
var
  Hp, Cc, Xx, Mm, R1, G1, B1: Double;
  R, G, B: Byte;
begin
  Hp := H / 60.0;
  while Hp >= 6.0 do
    Hp := Hp - 6.0;
  while Hp < 0.0 do
    Hp := Hp + 6.0;
  Cc := (1 - Abs(2 * L - 1)) * S;
  Xx := Cc * (1 - Abs((Hp - 2 * Trunc(Hp / 2)) - 1));
  Mm := L - Cc / 2;
  case Trunc(Hp) of
    0: begin R1 := Cc; G1 := Xx; B1 := 0; end;
    1: begin R1 := Xx; G1 := Cc; B1 := 0; end;
    2: begin R1 := 0; G1 := Cc; B1 := Xx; end;
    3: begin R1 := 0; G1 := Xx; B1 := Cc; end;
    4: begin R1 := Xx; G1 := 0; B1 := Cc; end;
  else
    begin R1 := Cc; G1 := 0; B1 := Xx; end;
  end;
  R := EnsureRange(Round((R1 + Mm) * 255), 0, 255);
  G := EnsureRange(Round((G1 + Mm) * 255), 0, 255);
  B := EnsureRange(Round((B1 + Mm) * 255), 0, 255);
  Result := RGB(R, G, B);
end;



procedure ShowNightlyActivity(AOwner: TComponent; const AItems: TArray<TNightlyActivityItem>);
var
  Form: TFormNightlyActivity;
begin
  Form := TFormNightlyActivity.Create(AOwner);
  try
    Form.LoadItems(AItems);
    Form.ShowModal();
  finally
    Form.Free();
  end;
end;



function TFormNightlyActivity.NightDateOf(ADateTime: TDateTime): TDateTime;
begin
  { Shifting back by 12 hours before truncating means both 23:00 and the
    following 01:00 fall on the same "night date" -- the calendar date the
    night started on. }
  Result := Trunc(ADateTime - 0.5);
end;



function TFormNightlyActivity.HourSlotOf(ADateTime: TDateTime): Integer;
begin
  Result := (HourOf(ADateTime) - 12 + 24) mod 24;
end;



function TFormNightlyActivity.HourLabelForSlot(ASlot: Integer): string;
begin
  Result := Format('%.2d', [(ASlot + 12) mod 24]);
end;



function TFormNightlyActivity.ColorForFraction(AFraction: Double): TColor;
const
  HUE = 212.0;
  SAT_MIN = 0.10;
  SAT_MAX = 0.55;
  LUM_MAX = 0.74;
  LUM_MIN = 0.28;
var
  S, L: Double;
begin
  S := SAT_MIN + AFraction * (SAT_MAX - SAT_MIN);
  L := LUM_MAX - AFraction * (LUM_MAX - LUM_MIN);
  Result := HSLToRGB(HUE, S, L);
end;



function TFormNightlyActivity.GetSelectedCounts: TArray<TArray<Integer>>;
begin
  if CbxDay.ItemIndex <= 0 then
    Result := FCountsAll
  else
    Result := FCountsByNight[CbxDay.ItemIndex - 1];
end;



procedure TFormNightlyActivity.LoadItems(const AItems: TArray<TNightlyActivityItem>);
var
  NightSet, SpeciesSet: TDictionary<string, Integer>;
  NightList: TList<TDateTime>;
  SpeciesList: TList<string>;
  I, NightIdx, SpeciesIdx, Slot, NSpecies: Integer;
  ND: TDateTime;
begin
  NightSet := TDictionary<string, Integer>.Create;
  SpeciesSet := TDictionary<string, Integer>.Create;
  NightList := TList<TDateTime>.Create;
  SpeciesList := TList<string>.Create;
  try
    for I := 0 to High(AItems) do begin
      ND := NightDateOf(AItems[I].DateTime);
      if not NightSet.ContainsKey(FormatDateTime('yyyymmdd', ND)) then begin
        NightSet.Add(FormatDateTime('yyyymmdd', ND), NightList.Count);
        NightList.Add(ND);
      end;
      if not SpeciesSet.ContainsKey(AItems[I].SpeciesName) then begin
        SpeciesSet.Add(AItems[I].SpeciesName, SpeciesList.Count);
        SpeciesList.Add(AItems[I].SpeciesName);
      end;
    end;

    NightList.Sort;
    SpeciesList.Sort(TComparer<string>.Construct(
      function(const A, B: string): Integer
      begin
        Result := CompareText(A, B);
      end));

    NightSet.Clear;
    for I := 0 to NightList.Count - 1 do
      NightSet.Add(FormatDateTime('yyyymmdd', NightList[I]), I);
    SpeciesSet.Clear;
    for I := 0 to SpeciesList.Count - 1 do
      SpeciesSet.Add(SpeciesList[I], I);

    FNightDates := NightList.ToArray;
    FSpeciesNames := SpeciesList.ToArray;
    NSpecies := Length(FSpeciesNames);

    SetLength(FSpeciesColors, NSpecies);
    for I := 0 to NSpecies - 1 do
      if NSpecies <= 1 then
        FSpeciesColors[I] := ColorForFraction(0.5)
      else
        FSpeciesColors[I] := ColorForFraction(I / (NSpecies - 1));

    SetLength(FCountsAll, 24, NSpecies);
    SetLength(FCountsByNight, Length(FNightDates), 24, NSpecies);

    for I := 0 to High(AItems) do begin
      NightIdx := NightSet[FormatDateTime('yyyymmdd', NightDateOf(AItems[I].DateTime))];
      SpeciesIdx := SpeciesSet[AItems[I].SpeciesName];
      Slot := HourSlotOf(AItems[I].DateTime);
      Inc(FCountsAll[Slot][SpeciesIdx]);
      Inc(FCountsByNight[NightIdx][Slot][SpeciesIdx]);
    end;
  finally
    NightSet.Free;
    SpeciesSet.Free;
    NightList.Free;
    SpeciesList.Free;
  end;

  CbxDay.Items.BeginUpdate;
  try
    CbxDay.Items.Clear;
    CbxDay.Items.Add('All days');
    for I := 0 to High(FNightDates) do
      CbxDay.Items.Add(FormatDateTime('d mmm yyyy', FNightDates[I]));
  finally
    CbxDay.Items.EndUpdate;
  end;
  CbxDay.ItemIndex := 0;
  ChartBox.Invalidate;
end;



procedure TFormNightlyActivity.CbxDayChange(Sender: TObject);
begin
  ChartBox.Invalidate;
end;



procedure TFormNightlyActivity.ChartBoxPaint(Sender: TObject);
const
  LEGEND_SWATCH = 10;
  LEGEND_ROW_H = 18;
  LEFT_AXIS_MARGIN = 42;
  BOTTOM_AXIS_MARGIN = 22;
  TOP_PAD = 8;
  SIDE_PAD = 12;
  HOUR_GROUP_GAP = 4;
  BAR_GAP = 1;
var
  C: TCanvas;
  W, H: Integer;
  LegendX, LegendY, LegendHeight, LineW: Integer;
  ChartR: TRect;
  Counts: TArray<TArray<Integer>>;
  NSpecies, MaxCount, Slot, SIdx: Integer;
  GroupW, BarW, GX: Double;
  XLeft, XRight, BarTop, BarH: Integer;
  Step, GridVal, GridY: Integer;
  S: string;
  TxtW: Integer;
  BgColor, AxisColor, GridColor, TextColor: TColor;
begin
  C := ChartBox.Canvas;
  W := ChartBox.ClientWidth;
  H := ChartBox.ClientHeight;

  BgColor := StyleServices.GetSystemColor(clWindow);
  AxisColor := StyleServices.GetSystemColor(clWindowText);
  GridColor := BlendColors(BgColor, AxisColor, 0.3);
  TextColor := AxisColor;

  C.Brush.Style := bsSolid;
  C.Brush.Color := BgColor;
  C.FillRect(Rect(0, 0, W, H));

  NSpecies := Length(FSpeciesNames);
  if NSpecies = 0 then begin
    C.Brush.Style := bsClear;
    C.Font.Color := TextColor;
    S := 'No detections to summarize.';
    C.TextOut((W - C.TextWidth(S)) div 2, (H - C.TextHeight(S)) div 2, S);
    Exit();
  end;

  { Legend, wrapped onto as many lines as needed. }
  C.Font.Size := 8;
  LegendX := SIDE_PAD;
  LegendY := 6;
  for SIdx := 0 to NSpecies - 1 do begin
    S := FSpeciesNames[SIdx];
    TxtW := C.TextWidth(S);
    LineW := LEGEND_SWATCH + 4 + TxtW + 14;
    if (LegendX + LineW > W - SIDE_PAD) and (LegendX > SIDE_PAD) then begin
      LegendX := SIDE_PAD;
      Inc(LegendY, LEGEND_ROW_H);
    end;
    C.Brush.Style := bsSolid;
    C.Brush.Color := FSpeciesColors[SIdx];
    C.Pen.Color := AxisColor;
    C.Rectangle(LegendX, LegendY + 3, LegendX + LEGEND_SWATCH, LegendY + 3 + LEGEND_SWATCH);
    C.Brush.Style := bsClear;
    C.Font.Color := TextColor;
    C.TextOut(LegendX + LEGEND_SWATCH + 4, LegendY, S);
    Inc(LegendX, LineW);
  end;
  LegendHeight := LegendY + LEGEND_ROW_H;

  ChartR := Rect(LEFT_AXIS_MARGIN, LegendHeight + TOP_PAD, W - SIDE_PAD, H - BOTTOM_AXIS_MARGIN);
  if (ChartR.Right <= ChartR.Left) or (ChartR.Bottom <= ChartR.Top) then
    Exit();

  Counts := GetSelectedCounts();
  MaxCount := 1;
  for Slot := 0 to 23 do
    for SIdx := 0 to NSpecies - 1 do
      if Counts[Slot][SIdx] > MaxCount then
        MaxCount := Counts[Slot][SIdx];

  { Gridlines and y-axis labels at a step that yields roughly 4-5 lines. }
  Step := Max(1, Ceil(MaxCount / 4));
  C.Font.Size := 7;
  GridVal := 0;
  while GridVal <= MaxCount do begin
    GridY := ChartR.Bottom - Round(GridVal / MaxCount * (ChartR.Bottom - ChartR.Top));
    C.Pen.Color := GridColor;
    C.MoveTo(ChartR.Left, GridY);
    C.LineTo(ChartR.Right, GridY);
    C.Brush.Style := bsClear;
    C.Font.Color := TextColor;
    S := IntToStr(GridVal);
    TxtW := C.TextWidth(S);
    C.TextOut(ChartR.Left - TxtW - 6, GridY - C.TextHeight(S) div 2, S);
    Inc(GridVal, Step);
  end;

  C.Pen.Color := AxisColor;
  C.MoveTo(ChartR.Left, ChartR.Top);
  C.LineTo(ChartR.Left, ChartR.Bottom);
  C.LineTo(ChartR.Right, ChartR.Bottom);

  GroupW := (ChartR.Right - ChartR.Left) / 24;
  BarW := (GroupW - HOUR_GROUP_GAP) / NSpecies;
  if BarW < 0.5 then
    BarW := 0.5;

  C.Font.Size := 7;
  C.Brush.Style := bsSolid;
  for Slot := 0 to 23 do begin
    GX := ChartR.Left + Slot * GroupW + HOUR_GROUP_GAP / 2;
    for SIdx := 0 to NSpecies - 1 do begin
      BarH := Round(Counts[Slot][SIdx] / MaxCount * (ChartR.Bottom - ChartR.Top));
      if BarH > 0 then begin
        XLeft := Round(GX + SIdx * BarW);
        XRight := Round(GX + (SIdx + 1) * BarW) - BAR_GAP;
        if XRight <= XLeft then
          XRight := XLeft + 1;
        BarTop := ChartR.Bottom - BarH;
        C.Brush.Color := FSpeciesColors[SIdx];
        C.FillRect(Rect(XLeft, BarTop, XRight, ChartR.Bottom));
      end;
    end;
    S := HourLabelForSlot(Slot);
    TxtW := C.TextWidth(S);
    C.Brush.Style := bsClear;
    C.Font.Color := TextColor;
    C.TextOut(Round(ChartR.Left + Slot * GroupW + GroupW / 2 - TxtW / 2), ChartR.Bottom + 4, S);
    C.Brush.Style := bsSolid;
  end;
end;



end.
