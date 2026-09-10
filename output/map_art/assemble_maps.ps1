param([switch]$Refined)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class MapPixels {
    public static int FloorLip(Bitmap src) {
        var b=src.LockBits(new Rectangle(0,0,src.Width,src.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
        var data=new byte[b.Stride*src.Height]; Marshal.Copy(b.Scan0,data,0,data.Length);
        var rows=new double[src.Height];
        for(int y=0;y<src.Height;y++) for(int x=0;x<src.Width;x++) {
            int p=y*b.Stride+x*4; rows[y]+=(data[p]+data[p+1]+data[p+2])/(3.0*src.Width);
        }
        src.UnlockBits(b);
        int best=(int)(src.Height*0.7857); double score=double.MinValue;
        for(int y=(int)(src.Height*0.77);y<(int)(src.Height*0.801);y++) {
            double drop=0; for(int j=1;j<=4;j++) drop+=rows[y-j]-rows[y+j];
            if(drop>score) {score=drop;best=y;}
        }
        return best;
    }
    public static void Blend(Bitmap dst, Bitmap src, int x, int fadeLeft, int fadeRight) {
        var a=dst.LockBits(new Rectangle(0,0,dst.Width,dst.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
        var b=src.LockBits(new Rectangle(0,0,src.Width,src.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
        var da=new byte[a.Stride*dst.Height]; var sb=new byte[b.Stride*src.Height];
        Marshal.Copy(a.Scan0,da,0,da.Length); Marshal.Copy(b.Scan0,sb,0,sb.Length);
        for(int col=0;col<src.Width;col++) {
            double alpha=1;
            if(fadeLeft>0) alpha=Math.Min(alpha,(double)col/fadeLeft);
            if(fadeRight>0) alpha=Math.Min(alpha,(double)(src.Width-1-col)/fadeRight);
            alpha=alpha*alpha*(3-2*alpha);
            for(int row=0;row<src.Height;row++) {
                int d=row*a.Stride+(x+col)*4, s=row*b.Stride+col*4;
                for(int c=0;c<3;c++) da[d+c]=(byte)Math.Round(da[d+c]*(1-alpha)+sb[s+c]*alpha);
                da[d+3]=255;
            }
        }
        Marshal.Copy(da,0,a.Scan0,da.Length); dst.UnlockBits(a); src.UnlockBits(b);
    }
}
'@
$assetRoot = Join-Path $PSScriptRoot 'sources'
New-Item -ItemType Directory -Force $assetRoot | Out-Null

function Save-ScaledRegion($source, $dest, $sourceRect, $destRect) {
    $g = [Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($source, $destRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
}

function Align-Half($path, $width, $lip) {
    $source = [Drawing.Image]::FromFile($path)
    $dest = New-Object Drawing.Bitmap($width, 1400)
    Save-ScaledRegion $source $dest ([Drawing.Rectangle]::new(0,0,$source.Width,$lip)) ([Drawing.Rectangle]::new(0,0,$width,1100))
    Save-ScaledRegion $source $dest ([Drawing.Rectangle]::new(0,$lip,$source.Width,$source.Height-$lip)) ([Drawing.Rectangle]::new(0,1100,$width,300))
    $source.Dispose()
    return $dest
}

function Blend-Image($dest, $source, $x, $fadeLeft, $fadeRight) {
    [MapPixels]::Blend($dest,$source,$x,$fadeLeft,$fadeRight)
}

$specs = @(
    @{name='ember_mine'; width=5200; half=2800; lip=598; starts=@(0,1232,2464,3696); tile=1504},
    @{name='hall_of_silence'; width=4800; half=2560; lip=688; starts=@(0,1131,2262,3392); tile=1408}
)
foreach($spec in $specs) {
    $name = $spec.name
    if (-not $Refined) {
        $left = Align-Half (Join-Path $assetRoot ($name+'_left.png')) $spec.half $spec.lip
        $right = Align-Half (Join-Path $assetRoot ($name+'_right.png')) $spec.half $spec.lip
        $master = New-Object Drawing.Bitmap($spec.width,1400)
        $g = [Drawing.Graphics]::FromImage($master)
        $g.DrawImageUnscaled($left,0,0)
        $g.Dispose()
        $overlap = 2*$spec.half-$spec.width
        Blend-Image $master $right ($spec.width-$spec.half) $overlap 0
        $left.Dispose()
        $right.Dispose()
        $master.Save((Join-Path $PSScriptRoot ($name+'_layout.png')),[Drawing.Imaging.ImageFormat]::Png)
        for($i=0;$i -lt 4;$i++) {
            $tile = $master.Clone([Drawing.Rectangle]::new($spec.starts[$i],0,$spec.tile,1400),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $tile.Save((Join-Path $PSScriptRoot ($name+'_guide_'+$i+'.png')),[Drawing.Imaging.ImageFormat]::Png)
            $tile.Dispose()
        }
    } else {
        $master = New-Object Drawing.Bitmap((Join-Path $PSScriptRoot ($name+'_layout.png')))
        for($i=0;$i -lt 4;$i++) {
            $sourcePath = Join-Path $assetRoot ($name+'_detail_'+$i+'.png')
            $source = [Drawing.Bitmap]::FromFile($sourcePath)
            $lip = [MapPixels]::FloorLip($source)
            Write-Output ($name+' tile '+$i+' floor lip '+$lip+'/'+$source.Height+' -> 1100/1400')
            $tile = Align-Half $sourcePath $spec.tile $lip
            $fadeL = if($i -eq 0){0}else{$spec.starts[$i-1]+$spec.tile-$spec.starts[$i]}
            $fadeR = 0
            Blend-Image $master $tile $spec.starts[$i] $fadeL $fadeR
            $source.Dispose()
            $tile.Dispose()
        }
        $final = Join-Path $PSScriptRoot ('../../Sprites/map/generated/'+$name+'_bg_final.png')
        $master.Save($final,[Drawing.Imaging.ImageFormat]::Png)
    }
    $preview = New-Object Drawing.Bitmap(1600,([int](1400*1600/$spec.width)))
    Save-ScaledRegion $master $preview ([Drawing.Rectangle]::new(0,0,$master.Width,$master.Height)) ([Drawing.Rectangle]::new(0,0,$preview.Width,$preview.Height))
    $preview.Save((Join-Path $PSScriptRoot ($name+'_preview.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
    $preview.Dispose()
    $master.Dispose()
    Write-Output ($name+' assembled: '+$spec.width+'x1400; floor lip Y=1100')
}
