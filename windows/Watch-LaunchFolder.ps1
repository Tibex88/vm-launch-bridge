param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "config.ps1")

if (-not (Test-Path $SharedFolder)) {
  throw "Shared folder not found: $SharedFolder"
}

if (-not (Test-Path $ProcessedFolder)) {
  New-Item -ItemType Directory -Path $ProcessedFolder | Out-Null
}

Write-Host "Watching launch folder: $SharedFolder"
Write-Host "Game command: $GameCommand"

while ($true) {
  $files = Get-ChildItem -Path $SharedFolder -Filter "launch-*.json" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime

  foreach ($file in $files) {
    try {
      $raw = Get-Content -Path $file.FullName -Raw
      $payload = $raw | ConvertFrom-Json

      if ($payload.action -ne "launch") {
        Write-Warning "Skipping unknown action in $($file.Name)"
      }
      else {
        Write-Host "Launching game for command file: $($file.Name)"
        if ([string]::IsNullOrWhiteSpace($GameArgs)) {
          Start-Process -FilePath $GameCommand
        }
        else {
          Start-Process -FilePath $GameCommand -ArgumentList $GameArgs
        }
      }
    }
    catch {
      Write-Error "Failed processing $($file.FullName): $_"
    }
    finally {
      $target = Join-Path $ProcessedFolder $file.Name
      Move-Item -Path $file.FullName -Destination $target -Force
    }
  }

  Start-Sleep -Seconds $PollIntervalSeconds
}
