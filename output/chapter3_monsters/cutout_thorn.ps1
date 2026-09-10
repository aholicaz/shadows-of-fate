Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ThornCutout {
 public static void Run(string input, string output) {
  using(var original = new Bitmap(input))
  using(var bmp = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb)) {
   using(var g = Graphics.FromImage(bmp)) g.DrawImageUnscaled(original,0,0);
   int w=bmp.Width,h=bmp.Height,n=w*h;
   var bits=bmp.LockBits(new Rectangle(0,0,w,h),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
   byte[] pixels=new byte[bits.Stride*h]; Marshal.Copy(bits.Scan0,pixels,0,pixels.Length);
   bool[] candidate=new bool[n],seen=new bool[n],remove=new bool[n];
   for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
    int p=y*bits.Stride+x*4; int b=pixels[p],g=pixels[p+1],r=pixels[p+2];
    int hi=Math.Max(r,Math.Max(g,b)),lo=Math.Min(r,Math.Min(g,b));
    candidate[y*w+x]=hi-lo<=26 && lo>=100;
   }
   int[] queue=new int[n]; int removed=0;
   for(int start=0;start<n;start++) {
    if(seen[start] || !candidate[start]) continue;
    int head=0,tail=1; queue[0]=start; seen[start]=true; bool border=false;
    while(head<tail) {
     int a=queue[head++],x=a%w,y=a/w;
     border|=x==0||x==w-1||y==0||y==h-1;
     for(int k=0;k<4;k++) {
      int nx=x+(k==0?-1:k==1?1:0),ny=y+(k==2?-1:k==3?1:0);
      if(nx<0||nx>=w||ny<0||ny>=h)continue;
      int b=ny*w+nx;
      if(!seen[b]&&candidate[b]){seen[b]=true;queue[tail++]=b;}
     }
    }
    // Background has large connected neutral checks; preserve small pale flower highlights.
    if(border || tail>=4) for(int j=0;j<tail;j++){remove[queue[j]]=true;removed++;}
   }
   // Restore enclosed neutral highlights inside the ivory flower, never exterior background.
   Array.Clear(seen,0,n);
   for(int start=0;start<n;start++) {
    if(seen[start] || !remove[start])continue;
    int head=0,tail=1;queue[0]=start;seen[start]=true;bool flower=true;
    while(head<tail) {
     int a=queue[head++],x=a%w,y=a/w;
     flower &= x>=670 && x<=870 && y>=90 && y<=275;
     for(int k=0;k<4;k++) {
      int nx=x+(k==0?-1:k==1?1:0),ny=y+(k==2?-1:k==3?1:0);
      if(nx<0||nx>=w||ny<0||ny>=h)continue;
      int b=ny*w+nx;if(!seen[b]&&remove[b]){seen[b]=true;queue[tail++]=b;}
     }
    }
    if(flower && tail<=100)for(int j=0;j<tail;j++)remove[queue[j]]=false;
   }
   for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
    int i=y*w+x,p=y*bits.Stride+x*4;
    if(remove[i]) {pixels[p]=pixels[p+1]=pixels[p+2]=pixels[p+3]=0;continue;}
    int nearby=0;
    for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++) {
     int xx=x+dx,yy=y+dy;if(xx>=0&&xx<w&&yy>=0&&yy<h&&remove[yy*w+xx])nearby++;
    }
    if(nearby>0) {
     int hi=Math.Max(pixels[p],Math.Max(pixels[p+1],pixels[p+2]));
     int lo=Math.Min(pixels[p],Math.Min(pixels[p+1],pixels[p+2]));
     if(hi-lo<36 && lo>110) pixels[p+3]=(byte)Math.Max(32,255-nearby*28);
    }
   }
   Marshal.Copy(pixels,0,bits.Scan0,pixels.Length);bmp.UnlockBits(bits);
   bmp.Save(output,ImageFormat.Png);Console.WriteLine("Transparent pixels: "+removed+" / "+n);
  }
 }
}
'@ -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Runtime.InteropServices,System.Private.Windows.GdiPlus,System.Private.Windows.Core,System.Console
[ThornCutout]::Run((Join-Path $PWD 'output/chapter3_monsters/thorn_matriarch_pending_alpha.png'), (Join-Path $PWD 'Sprites/monsters/generated/chapter3/thorn_matriarch.png'))
