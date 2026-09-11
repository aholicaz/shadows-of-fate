$ErrorActionPreference = 'Stop'
$swordRoot = Split-Path -Parent $PSScriptRoot
$swordSetup = @(
    @('aesir_warblade','Sprites/items/placeholder/aesir_warblade.png',200,56,1.5,62),
    @('bastard_sword','_to_delete/originals_icons/bastard_sword.png',300,963,0.28,242),
    @('claymore','Sprites/equip/claymore_hand.png',1020,230,0.32,63),
    @('ember_of_gullveig','Sprites/items/placeholder/ember_of_gullveig.png',204,57,1.5,63),
    @('falchion','_to_delete/originals_icons/items/falchion.png',413,89,0.68,59),
    @('flame_sword','_to_delete/originals_icons/flame_sword.png',1012,240,0.28,62),
    @('forge_saber','_to_delete/originals_icons/forge_saber.png',990,265,0.26,61),
    @('katana','_to_delete/originals_icons/items/Katana.png',410,93,0.72,62),
    @('marsh_cutter','Sprites/items/placeholder/marsh_cutter.png',65,184,1.3,241),
    @('novice_sword','_to_delete/originals_icons/items/blade.png',180,397,0.7,260),
    @('rapier','_to_delete/originals_icons/rapier.png',229,960,0.27,240),
    @('root_sword','Sprites/items/placeholder/root_sword.png',62,201,1.25,243),
    @('runic_blade','_to_delete/originals_icons/runic_blade.png',990,233,0.28,63),
    @('sentinel_blade','Sprites/items/placeholder/sentinel_blade.png',201,51,1.4,64),
    @('short_sword','_to_delete/originals_icons/short_sword.png',320,930,0.21,242),
    @('wooden_sword','_to_delete/originals_icons/wooden_sword.png',350,880,0.21,242)
)
foreach ($entry in $swordSetup) {
    $swordId = $entry[0]
    $sourcePath = Join-Path $swordRoot $entry[1]
    $destination = Join-Path $swordRoot "Sprites/equip/${swordId}_hand.png"
    if ($sourcePath -ne $destination) {
        if (!(Test-Path -LiteralPath $destination) -or (Get-FileHash -LiteralPath $sourcePath).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
            Copy-Item -LiteralPath $sourcePath -Destination $destination
        }
    }
    $resourcePath = Join-Path $swordRoot "data/items/$swordId.tres"
    $resourceText = [IO.File]::ReadAllText($resourcePath)
    $resourceText = [regex]::Replace($resourceText, ' load_steps=\d+', '')
    $resourceText = [regex]::Replace($resourceText, '(?m)^\[ext_resource[^\r\n]*id="(?:hand_texture|bare_combo)"\]\r?\n', '')
    $resourceText = [regex]::Replace($resourceText, '(?m)^equip_(?:sprite_frames|texture|follow_idle_hand|grip|hand_scale|hand_rotation_degrees|attack_body_frames|z_index) =[^\r\n]*\r?\n', '')
    $refs = "[ext_resource type=`"Texture2D`" path=`"res://Sprites/equip/${swordId}_hand.png`" id=`"hand_texture`"]`n"
    $refs += "[ext_resource type=`"SpriteFrames`" path=`"res://data/sprites/attack_blade_bare_hands.tres`" id=`"bare_combo`"]`n`n"
    $insertAt = $resourceText.IndexOf('[sub_resource', [StringComparison]::Ordinal)
    if ($insertAt -lt 0) { $insertAt = $resourceText.IndexOf('[resource]', [StringComparison]::Ordinal) }
    $resourceText = $resourceText.Insert($insertAt, $refs)
    if ($resourceText -notmatch '(?m)^icon =') { $resourceText += "`nicon = ExtResource(`"hand_texture`")`n" }
    $scaleValue = ([double]$entry[4]).ToString([Globalization.CultureInfo]::InvariantCulture)
    $resourceText += "`nequip_texture = ExtResource(`"hand_texture`")`nequip_follow_idle_hand = true`nequip_grip = Vector2($($entry[2]), $($entry[3]))`nequip_hand_scale = $scaleValue`nequip_hand_rotation_degrees = $($entry[5]).0`nequip_attack_body_frames = ExtResource(`"bare_combo`")`nequip_z_index = -1`n"
    [IO.File]::WriteAllText($resourcePath, $resourceText)
    Write-Output "Configured $swordId"
}
