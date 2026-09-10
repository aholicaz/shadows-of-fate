param([switch]$Final)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
function Draw-Region($g,$src,$sx,$sy,$sw,$sh,$dx,$dy,$dw,$dh) {
    $g.DrawImage($src,[Drawing.Rectangle]::new($dx,$dy,$dw,$dh),[Drawing.Rectangle]::new($sx,$sy,$sw,$sh),[Drawing.GraphicsUnit]::Pixel)
}
function Graphics-For($bmp) {
    $g=[Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}
function Save-Preview($bmp,$name) {
    $thumb=[Drawing.Bitmap]::new(1600,[int]($bmp.Height*1600/$bmp.Width))
    $g=Graphics-For $thumb
    Draw-Region $g $bmp 0 0 $bmp.Width $bmp.Height 0 0 $thumb.Width $thumb.Height
    $g.Dispose()
    $thumb.Save((Join-Path $PSScriptRoot ($name+'_preview.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
    $thumb.Dispose()
}
$floor=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot 'sources/hall_floor.png'))
if (-not $Final) {
    # Generated floor is registered to scene coordinates. Upper Hall architecture remains original.
    $hall=[Drawing.Bitmap]::new((Join-Path $projectRoot 'Sprites/map/generated/hall_of_silence_bg_final.png'))
    $g=Graphics-For $hall
    for($i=0;$i -lt 3;$i++) {
        Draw-Region $g $floor 0 0 $floor.Width 450 ($i*1600) 1030 1600 190
        Draw-Region $g $floor 0 450 $floor.Width ($floor.Height-450) ($i*1600) 1220 1600 180
    }
    $g.Dispose()
    $hall.Save((Join-Path $PSScriptRoot 'sources/hall_wide_unused.png'),[Drawing.Imaging.ImageFormat]::Png)
    Save-Preview $hall 'hall_of_silence_wide'
    $hall.Dispose()
    $layout=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot 'sources/cold_layout.png'))
    $cold=[Drawing.Bitmap]::new(3200,1300)
    $g=Graphics-For $cold
    Draw-Region $g $layout 0 0 $layout.Width 535 0 0 3200 980
    for($i=0;$i -lt 2;$i++) {
        Draw-Region $g $floor 0 0 $floor.Width 450 ($i*1600) 980 1600 210
        Draw-Region $g $floor 0 450 $floor.Width ($floor.Height-450) ($i*1600) 1190 1600 110
    }
    $g.Dispose()
    $cold.Save((Join-Path $PSScriptRoot 'cold_layout_registered.png'),[Drawing.Imaging.ImageFormat]::Png)
    for($i=0;$i -lt 3;$i++) {
        $tile=$cold.Clone([Drawing.Rectangle]::new(($i*960),0,1280,1300),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $tile.Save((Join-Path $PSScriptRoot ('cold_guide_'+$i+'.png')),[Drawing.Imaging.ImageFormat]::Png)
        $tile.Dispose()
    }
    $cold.Dispose(); $layout.Dispose()
} else {
    Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class NextMapJoin {
 public static void Paste(Bitmap dst, Bitmap src, int start, int overlap) {
  var a=dst.LockBits(new Rectangle(0,0,dst.Width,dst.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var b=src.LockBits(new Rectangle(0,0,src.Width,src.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  var da=new byte[a.Stride*dst.Height]; var sb=new byte[b.Stride*src.Height];
  Marshal.Copy(a.Scan0,da,0,da.Length); Marshal.Copy(b.Scan0,sb,0,sb.Length);
  var seam=new int[src.Height];
  if(overlap>0) {
   var prev=new double[overlap]; var next=new double[overlap]; var back=new int[src.Height*overlap];
   for(int y=0;y<src.Height;y++) {
    for(int x=0;x<overlap;x++) {
     if(x<24 || x>=overlap-24) {next[x]=1e20;continue;}
     int d=y*a.Stride+(start+x)*4,s=y*b.Stride+x*4;
     double cost=0; for(int c=0;c<3;c++) cost+=Math.Abs(da[d+c]-sb[s+c]);
     int best=x; if(x>0&&prev[x-1]<prev[best])best=x-1; if(x<overlap-1&&prev[x+1]<prev[best])best=x+1;
     next[x]=cost+prev[best]+0.02*Math.Abs(x-overlap/2); back[y*overlap+x]=best;
    }
    var swap=prev;prev=next;next=swap;
   }
   int end=24; for(int x=25;x<overlap-24;x++)if(prev[x]<prev[end])end=x;
   for(int y=src.Height-1;y>=0;y--) {seam[y]=end;end=back[y*overlap+end];}
  }
  for(int y=0;y<src.Height;y++)for(int x=0;x<src.Width;x++) {
   double alpha=overlap==0?1:Math.Clamp((x-seam[y]+16)/32.0,0,1);alpha=alpha*alpha*(3-2*alpha);
   int d=y*a.Stride+(start+x)*4,s=y*b.Stride+x*4;
   for(int c=0;c<3;c++) da[d+c]=(byte)Math.Round(da[d+c]*(1-alpha)+sb[s+c]*alpha);
   da[d+3]=255;
  }
  Marshal.Copy(da,0,a.Scan0,da.Length);dst.UnlockBits(a);src.UnlockBits(b);
 }
}
'@
    $cold=[Drawing.Bitmap]::new(3200,1300)
    $backs=@(960,945,956)
    $lips=@(1245,1274,1160)
    for($i=0;$i -lt 3;$i++) {
        $src=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot ('sources/cold_detail_'+$i+'.png')))
        $tile=[Drawing.Bitmap]::new(1280,1300)
        $g=Graphics-For $tile
        Draw-Region $g $src 0 0 $src.Width $backs[$i] 0 0 1280 980
        # Final user preference: restore the original shallow walkway proportions.
        Draw-Region $g $src 0 $backs[$i] $src.Width ($lips[$i]-$backs[$i]) 0 980 1280 100
        Draw-Region $g $src 0 $lips[$i] $src.Width ($src.Height-$lips[$i]) 0 1080 1280 220
        $g.Dispose()
        [NextMapJoin]::Paste($cold,$tile,($i*960),$(if($i -eq 0){0}else{320}))
        $tile.Dispose(); $src.Dispose()
    }
    $cold.Save((Join-Path $projectRoot 'Sprites/map/generated/cold_forge_bg_final.png'),[Drawing.Imaging.ImageFormat]::Png)
    Save-Preview $cold 'cold_forge'
    $cold.Dispose()
}
$floor.Dispose()
