unit PngExport;



interface



uses Vcl.Graphics;

// Combines WavBmp and SpectBmp according to Target (0=wave, 1=spect, 2=combined)
// and saves as PNG to FileName.
procedure SavePng(WavBmp, SpectBmp: TBitmap; Target: Integer; const FileName: string);



implementation



uses System.Math, Vcl.Imaging.PngImage, System.SysUtils;



procedure SavePng(WavBmp, SpectBmp: TBitmap; Target: Integer; const FileName: string);
var
  Png: TPngImage;
  Bmp: TBitmap;
begin
  Png := TPngImage.Create();
  try
    case Target of
      0: Png.Assign(WavBmp);
      1: Png.Assign(SpectBmp);
    else
      Bmp := TBitmap.Create();
      try
        Bmp.PixelFormat := pf24bit;
        Bmp.Width := Max(WavBmp.Width, SpectBmp.Width);
        Bmp.Height := WavBmp.Height + SpectBmp.Height;
        Bmp.Canvas.Draw(0, 0, WavBmp);
        Bmp.Canvas.Draw(0, WavBmp.Height, SpectBmp);
        Png.Assign(Bmp);
      finally
        Bmp.Free();
      end;
    end;
    Png.SaveToFile(FileName);
  finally
    Png.Free();
  end;
end;



end.
