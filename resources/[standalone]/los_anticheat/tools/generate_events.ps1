# Genereert data/events.generated.lua opnieuw uit de huidige codebase.
#
# Draaien vanuit de server root:
#   powershell -ExecutionPolicy Bypass -File "resources\[standalone]\los_anticheat\tools\generate_events.ps1"
#
# Draai dit opnieuw nadat je resources hebt toegevoegd, verwijderd of hernoemd.
# De lijst bepaalt welke events onder monitoring staan; wat er niet in staat wordt
# niet geteld.

$ErrorActionPreference = 'Stop'

$resourceRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$destination  = Join-Path $PSScriptRoot '..\data\events.generated.lua'

Write-Host "Scannen: $resourceRoot"

$files = Get-ChildItem -LiteralPath $resourceRoot -Recurse -File -Filter *.lua -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(web|node_modules|cache|_external)\\' } |
    Where-Object { $_.FullName -notmatch '\\\[cfx-default\]\\' } |
    Where-Object { $_.FullName -match '\\server\\|\\sv_|server\.lua$|\\bridge\\.*server' }

$map = @{}

foreach ($file in $files) {
    $raw = Get-Content -LiteralPath $file.FullName -Raw
    if ([string]::IsNullOrEmpty($raw)) { continue }

    $relative = $file.FullName.Substring($resourceRoot.Path.Length + 1)
    $resource = ($relative -split '\\')[1]

    foreach ($match in [regex]::Matches($raw, "RegisterNetEvent\(\s*['""]([^'""]+)['""]")) {
        $name = $match.Groups[1].Value
        if (-not $map.ContainsKey($name)) { $map[$name] = $resource }
    }
}

$out = New-Object System.Text.StringBuilder
[void]$out.AppendLine("---GEGENEREERD BESTAND - niet met de hand bijwerken.")
[void]$out.AppendLine("---Opnieuw genereren: zie tools/generate_events.ps1 in deze resource.")
[void]$out.AppendLine("---")
[void]$out.AppendLine("---Elk server-side RegisterNetEvent dat een client kan triggeren, met de")
[void]$out.AppendLine("---resource waar het vandaan komt. Dit is de aanvalsoppervlakte van de server.")
[void]$out.AppendLine("---Gegenereerd op $(Get-Date -Format 'yyyy-MM-dd') uit $($files.Count) server-side bestanden.")
[void]$out.AppendLine("")
[void]$out.AppendLine("KnownServerEvents = {")

foreach ($key in ($map.Keys | Sort-Object)) {
    [void]$out.AppendLine(("    ['{0}'] = '{1}'," -f ($key -replace "'", "\'"), $map[$key]))
}

[void]$out.AppendLine("}")
[void]$out.AppendLine("")
[void]$out.AppendLine("return KnownServerEvents")

[System.IO.File]::WriteAllText($destination, $out.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-Host "Geschreven: $($map.Count) events naar $destination"
