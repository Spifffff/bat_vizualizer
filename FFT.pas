{ Bat vizualizer
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



unit FFT;



interface



type
  TWindowType = (wtRectangular, wtHann, wtHamming, wtBlackman, wtFlatTop);



  TComplex = record
    Re, Im: Double;
  end;



procedure ComputeWindowedFFT(const Samples: TArray<Single>; Offset, Size: Integer; Window: TWindowType; out Magnitudes: TArray<Double>);



implementation



uses Math;



procedure ApplyWindow(var Buf: TArray<Double>; N: Integer; Window: TWindowType);
var
  I: Integer;
  W, TwoPi: Double;
begin
  if Window = wtRectangular then
    Exit();
  TwoPi := 2.0 * Pi / (N - 1);
  for I := 0 to N - 1 do begin
    case Window of
      wtHann:
        W := 0.5 * (1.0 - Cos(TwoPi * I));
      wtHamming:
        W := 0.54 - 0.46 * Cos(TwoPi * I);
      wtBlackman:
        W := 0.42 - 0.5 * Cos(TwoPi * I) + 0.08 * Cos(2.0 * TwoPi * I);
      wtFlatTop:
        W := 0.21557895 - 0.41663158 * Cos(TwoPi * I) + 0.27726316 * Cos(2.0 * TwoPi * I) - 0.08357895 * Cos(3.0 * TwoPi * I) + 0.00694737 *
          Cos(4.0 * TwoPi * I);
    else
      W := 1.0;
    end;
    Buf[I] := Buf[I] * W;
  end;
end;



procedure BitReverse(var A: TArray<TComplex>; N: Integer);
var
  I, J, K: Integer;
  Tmp: TComplex;
begin
  J := 0;
  for I := 1 to N - 1 do begin
    K := N shr 1;
    while (J and K) <> 0 do begin
      J := J xor K;
      K := K shr 1;
    end;
    J := J xor K;
    if I < J then begin
      Tmp := A[I];
      A[I] := A[J];
      A[J] := Tmp;
    end;
  end;
end;



procedure FFTInPlace(var A: TArray<TComplex>; N: Integer);
var
  Len, I, J, Half: Integer;
  Ang, WnRe, WnIm, WRe, WIm, NewWRe, URe, UIm, VRe, VIm: Double;
begin
  BitReverse(A, N);
  Len := 2;
  while Len <= N do begin
    Half := Len shr 1;
    Ang := -2.0 * Pi / Len;
    WnRe := Cos(Ang);
    WnIm := Sin(Ang);
    I := 0;
    while I < N do begin
      WRe := 1.0;
      WIm := 0.0;
      for J := 0 to Half - 1 do begin
        URe := A[I + J].Re;
        UIm := A[I + J].Im;
        VRe := WRe * A[I + J + Half].Re - WIm * A[I + J + Half].Im;
        VIm := WRe * A[I + J + Half].Im + WIm * A[I + J + Half].Re;
        A[I + J].Re := URe + VRe;
        A[I + J].Im := UIm + VIm;
        A[I + J + Half].Re := URe - VRe;
        A[I + J + Half].Im := UIm - VIm;
        NewWRe := WRe * WnRe - WIm * WnIm;
        WIm := WRe * WnIm + WIm * WnRe;
        WRe := NewWRe;
      end;
      Inc(I, Len);
    end;
    Len := Len shl 1;
  end;
end;



procedure ComputeWindowedFFT(const Samples: TArray<Single>; Offset, Size: Integer; Window: TWindowType; out Magnitudes: TArray<Double>);
var
  I: Integer;
  Buf: TArray<Double>;
  A: TArray<TComplex>;
begin
  SetLength(Buf, Size);
  for I := 0 to Size - 1 do begin
    var
    Idx := Offset + I;
    if (Idx >= 0) and (Idx < Length(Samples)) then
      Buf[I] := Samples[Idx]
    else
      Buf[I] := 0.0;
  end;

  ApplyWindow(Buf, Size, Window);

  SetLength(A, Size);
  for I := 0 to Size - 1 do begin
    A[I].Re := Buf[I];
    A[I].Im := 0.0;
  end;

  FFTInPlace(A, Size);

  SetLength(Magnitudes, Size shr 1);
  for I := 0 to (Size shr 1) - 1 do
    Magnitudes[I] := Sqrt(A[I].Re * A[I].Re + A[I].Im * A[I].Im);
end;



end.
