# Original short impact: low punch, crisp crack and a small metallic tail.
Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class CriticalImpactAudio {
 public static void Save(string path) {
  const int sr=44100;
  int count=(int)(sr*0.30);
  double[] samples=new double[count];
  Random rng=new Random(41127);
  double low=0, peak=0;
  for(int i=0;i<count;i++) {
   double t=(double)i/sr;
   double noise=rng.NextDouble()*2-1;
   low=low*0.82+noise*0.18;
   double phase=2*Math.PI*(62*t+72*0.025*(1-Math.Exp(-t/0.025)));
   double bass=0.85*Math.Sin(phase)*Math.Exp(-t*24);
   double body=0.30*Math.Sin(2*Math.PI*177*t)*Math.Exp(-t*35);
   double crack=0.65*(noise-low)*Math.Exp(-t*120);
   double grit=0.34*low*Math.Exp(-t*27);
   double metal=0.12*Math.Sin(2*Math.PI*1327*t)*Math.Exp(-t*44)+0.07*Math.Sin(2*Math.PI*2191*t)*Math.Exp(-t*58);
   double env=Math.Min(1,t/0.0008)*Math.Min(1,(0.30-t)/0.035);
   samples[i]=Math.Tanh((bass+body+crack+grit+metal)*1.3)*env;
   peak=Math.Max(peak,Math.Abs(samples[i]));
  }
  using(BinaryWriter w=new BinaryWriter(File.Create(path))) {
   w.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); w.Write(36+count*2);
   w.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16);
   w.Write((short)1);w.Write((short)1);w.Write(sr);w.Write(sr*2);w.Write((short)2);w.Write((short)16);
   w.Write(System.Text.Encoding.ASCII.GetBytes("data"));w.Write(count*2);
   foreach(double sample in samples)w.Write((short)Math.Round(sample/peak*0.82*32767));
  }
 }
}
'@
[CriticalImpactAudio]::Save((Join-Path $PSScriptRoot '../Sprites/sfx/critical_impact.wav'))
