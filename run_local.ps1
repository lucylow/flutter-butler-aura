# Run Aura Flutter with local env keys from dart_defines.local (gitignored).
# Create dart_defines.local from dart_defines.local.example and add your TUYA_ACCESS_ID, TUYA_AUTH_KEY, etc.

$localFile = Join-Path $PSScriptRoot "dart_defines.local"
$defines = @()

if (Test-Path $localFile) {
    Get-Content $localFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $eq = $line.IndexOf("=")
            if ($eq -gt 0) {
                $key = $line.Substring(0, $eq).Trim()
                $val = $line.Substring($eq + 1).Trim()
                if ($key -and $val) { $defines += "--dart-define=$key=$val" }
            }
        }
    }
}

$defineArgs = $defines -join " "
Write-Host "Running with dart-defines from dart_defines.local (if present)..."
Set-Location $PSScriptRoot
if ($defineArgs) { Invoke-Expression "flutter run $defineArgs" } else { flutter run }
