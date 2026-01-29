# Run A.U.R.A. Flutter in Chrome (same experience as the Lovable app).
# Uses dart_defines from dart_defines.local if present (AURA_BACKEND_URL, etc.).

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
Set-Location $PSScriptRoot
Write-Host "Running A.U.R.A. in Chrome (Flutter Web)..."
if ($defineArgs) { flutter run -d chrome $defineArgs } else { flutter run -d chrome }
