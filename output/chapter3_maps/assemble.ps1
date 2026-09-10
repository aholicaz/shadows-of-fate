param([string]$Only='',[switch]$Partial)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$specs=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'specs.json') -Raw | ConvertFrom-Json
$registration=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'registration.json') -Raw | ConvertFrom-Json -AsHashtable
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ChapterMapJoin {
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
     next[x]=cost+prev[best]+0.03*Math.Abs(x-overlap/2); back[y*overlap+x]=best;
    }
    var swap=prev;prev=next;next=swap;
   }
   int end=24; for(int x=25;x<overlap-24;x++)if(prev[x]<prev[end])end=x;
   for(int y=src.Height-1;y>=0;y--) {seam[y]=end;end=back[y*overlap+end];}
  }
  for(int y=0;y<src.Height;y++)for(int x=0;x<src.Width;x++) {
   double alpha=overlap==0?1:Math.Clamp((x-seam[y]+24)/48.0,0,1);alpha=alpha*alpha*(3-2*alpha);
   int d=y*a.Stride+(start+x)*4,s=y*b.Stride+x*4;
   for(int c=0;c<3;c++) da[d+c]=(byte)Math.Round(da[d+c]*(1-alpha)+sb[s+c]*alpha);
   da[d+3]=255;
  }
  Marshal.Copy(da,0,a.Scan0,da.Length);dst.UnlockBits(a);src.UnlockBits(b);
 }
}
'@
function Region($g,$src,$sy,$sh,$dy,$dh,$dw) {
 $g.DrawImage($src,[Drawing.Rectangle]::new(0,$dy,$dw,$dh),[Drawing.Rectangle]::new(0,$sy,$src.Width,$sh),[Drawing.GraphicsUnit]::Pixel)
}
foreach($s in $specs) {
 if($Only -and $Only -ne $s.id){continue}
 $final=[Drawing.Bitmap]::new([int]$s.w,[int]$s.h)
 $previousEnd=0
 for($i=0;$i -lt $s.n;$i++) {
  if($Partial -and $i -ge $registration[$s.id].Count){break}
  $src=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot "sources/$($s.id)_$i.png"))
  $start=[int][Math]::Round($s.step*$i)
  $end=[int][Math]::Round($s.step*$i+$s.tileW)
  if($i -eq $s.n-1){$end=[int]$s.w}
  $tw=$end-$start
  $tile=[Drawing.Bitmap]::new($tw,[int]$s.h)
  $g=[Drawing.Graphics]::FromImage($tile)
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $back=[int]$registration[$s.id][$i][0]; $lip=[int]$registration[$s.id][$i][1]
  $targetLip=[int][Math]::Round($s.floor+$s.lip_offset)
  $targetBack=$targetLip-[int]$s.walk_depth
  Region $g $src 0 $back 0 $targetBack $tw
  Region $g $src $back ($lip-$back) $targetBack ($targetLip-$targetBack) $tw
  Region $g $src $lip ($src.Height-$lip) $targetLip ($s.h-$targetLip) $tw
  $g.Dispose()
  $tile.Save((Join-Path $PSScriptRoot "sources/$($s.id)_registered_$i.png"),[Drawing.Imaging.ImageFormat]::Png)
  [ChapterMapJoin]::Paste($final,$tile,$start,([Math]::Max(0,$previousEnd-$start)))
  $previousEnd=$end
  $tile.Dispose(); $src.Dispose()
 }
 if($s.id -eq 'nidavellir_town') {
  # Separate native-detail floor avoids enlarging a 30px generated walkway into a blurry band.
  $floorSource=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot 'sources/nidavellir_floor.png'))
  $floorTop=[int][Math]::Round($s.floor+$s.lip_offset-$s.walk_depth)
  $bandHeight=[int]$s.h-$floorTop
  $band=[Drawing.Bitmap]::new([int]$s.w,$bandHeight)
  $floorTile=[Drawing.Bitmap]::new(1200,$bandHeight)
  $fg=[Drawing.Graphics]::FromImage($floorTile)
  $fg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  Region $fg $floorSource 0 370 0 110 1200
  Region $fg $floorSource 370 ($floorSource.Height-370) 110 ($bandHeight-110) 1200
  $fg.Dispose()
  for($x=0;$x -lt $s.w;$x+=1080) {
   $part=$floorTile.Clone([Drawing.Rectangle]::new(0,0,[Math]::Min(1200,$s.w-$x),$bandHeight),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
   [ChapterMapJoin]::Paste($band,$part,$x,$(if($x -eq 0){0}else{120}))
   $part.Dispose()
  }
  $fg=[Drawing.Graphics]::FromImage($final);$fg.DrawImageUnscaled($band,0,$floorTop);$fg.Dispose()
  $floorSource.Dispose();$floorTile.Dispose();$band.Dispose()
 }
 $destination=Join-Path $projectRoot "Sprites/map/generated/$($s.id)_bg_final.png"
 if(-not $Partial){$final.Save($destination,[Drawing.Imaging.ImageFormat]::Png)}
 $visible=$final.Clone([Drawing.Rectangle]::new(0,0,$previousEnd,[int]$s.h),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $preview=[Drawing.Bitmap]::new($visible,1800,[int][Math]::Round(1800*$s.h/$previousEnd))
 $preview.Save((Join-Path $PSScriptRoot "$($s.id)_preview.png"),[Drawing.Imaging.ImageFormat]::Png)
 $preview.Dispose();$visible.Dispose();$final.Dispose()
 Write-Output "$($s.id): $($s.w)x$($s.h), walk plane depth $($s.walk_depth), feet $($s.lip_offset)px inside front lip"
}
