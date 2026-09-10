$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourceDirectory = Join-Path $PWD 'Sprites/monsters/generated/chapter3'
$destinationDirectory = Join-Path $PWD 'Sprites/monsters/generated/chapter3_margin_20'
New-Item -ItemType Directory -Force $destinationDirectory | Out-Null
$report = foreach ($asset in Get-ChildItem -LiteralPath $sourceDirectory -Filter '*.png') {
    $sourceImage = [Drawing.Bitmap]::new($asset.FullName)
    $resultImage = [Drawing.Bitmap]::new($sourceImage.Width, $sourceImage.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($resultImage)
    try {
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $scaledWidth = [single]($sourceImage.Width * 0.8)
        $scaledHeight = [single]($sourceImage.Height * 0.8)
        $targetRectangle = [Drawing.RectangleF]::new([single](($sourceImage.Width-$scaledWidth)/2), [single](($sourceImage.Height-$scaledHeight)/2), $scaledWidth, $scaledHeight)
        $graphics.DrawImage($sourceImage, $targetRectangle, [Drawing.RectangleF]::new(0,0,$sourceImage.Width,$sourceImage.Height), [Drawing.GraphicsUnit]::Pixel)
        $targetFile = Join-Path $destinationDirectory $asset.Name
        $resultImage.Save($targetFile, [Drawing.Imaging.ImageFormat]::Png)
        $edgePixels = 0
        for ($x=0; $x -lt $resultImage.Width; $x++) {
            if ($resultImage.GetPixel($x,0).A -ne 0 -or $resultImage.GetPixel($x,$resultImage.Height-1).A -ne 0) { $edgePixels++ }
        }
        for ($y=0; $y -lt $resultImage.Height; $y++) {
            if ($resultImage.GetPixel(0,$y).A -ne 0 -or $resultImage.GetPixel($resultImage.Width-1,$y).A -ne 0) { $edgePixels++ }
        }
        if ($edgePixels -ne 0) { throw "Non-transparent border: $($asset.Name)" }
        [PSCustomObject]@{file=$asset.Name;width=$resultImage.Width;height=$resultImage.Height;scale=0.8;offset_x=$targetRectangle.X;offset_y=$targetRectangle.Y;opaque_border_pixels=$edgePixels;source_sha256=(Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256).Hash}
    } finally {
        $graphics.Dispose(); $resultImage.Dispose(); $sourceImage.Dispose()
    }
}
if (@($report).Count -ne 9) { throw 'Expected nine monster images' }
$report | ConvertTo-Json | Set-Content (Join-Path $destinationDirectory 'resize_report.json')
@'
ภาพมอนทั้ง 9 ตัวหันซ้าย ย่อขนาดเนื้อภาพเป็น 80% ของต้นฉบับ
คงผืนภาพ 1254 x 1254 px และพื้นหลังโปร่งใส RGBA
จัดภาพกึ่งกลาง เพิ่มระยะขอบประมาณ 125.4 px ต่อด้านจากการย่อทั้งผืนภาพเดิม
ใช้ HighQualityBicubic สำหรับการย่อ ไม่มีการวาดใหม่
'@ | Set-Content (Join-Path $destinationDirectory 'README.txt')
$report | Format-Table file,width,height,scale,opaque_border_pixels
Compress-Archive -LiteralPath $destinationDirectory -DestinationPath (Join-Path $PWD 'output/chapter3_monsters/chapter3_margin_20.zip') -Force
