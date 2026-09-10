Add-Type -AssemblyName System.Drawing
$reports = foreach ($asset in Get-ChildItem 'Sprites/monsters/generated/chapter3' -Filter '*.png') {
    $bitmap = [Drawing.Bitmap]::new($asset.FullName)
    $zero = 0; $partial = 0; $opaque = 0
    for ($y = 0; $y -lt $bitmap.Height; $y += 4) {
        for ($x = 0; $x -lt $bitmap.Width; $x += 4) {
            $alpha = $bitmap.GetPixel($x, $y).A
            if ($alpha -eq 0) { $zero++ } elseif ($alpha -eq 255) { $opaque++ } else { $partial++ }
        }
    }
    [PSCustomObject]@{file=$asset.Name;width=$bitmap.Width;height=$bitmap.Height;format=$bitmap.PixelFormat.ToString();transparent_samples=$zero;partial_samples=$partial;opaque_samples=$opaque;corner_alpha=$bitmap.GetPixel(0,0).A}
    $bitmap.Dispose()
}
$reports | ConvertTo-Json | Set-Content 'output/chapter3_monsters/alpha_report.json'
$reports | Format-Table -AutoSize
if (@($reports | Where-Object { $_.transparent_samples -eq 0 -or $_.opaque_samples -eq 0 -or $_.corner_alpha -ne 0 }).Count -gt 0) { throw 'Alpha verification failed' }
