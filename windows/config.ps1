$SharedFolder = "Z:\"
$ProcessedFolder = Join-Path $SharedFolder "processed"

# Set this to the launcher or game executable inside the VM.
$GameCommand = "C:\Users\vboxuser\Downloads\SophiaverseLauncher\Launcher.exe"

# Optional arguments passed every time the game is launched.
$GameArgs = ""

# Poll interval in seconds.
$PollIntervalSeconds = 1
