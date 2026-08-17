param()

$listener = New-Object System.Net.HttpListener
$prefix = "http://+:4567/launch/"
$listener.Prefixes.Add($prefix)

try {
  $listener.Start()
} catch {
  Write-Error "Failed to start HttpListener on $prefix. Run this script in an elevated PowerShell if needed. $_"
  exit 1
}

Write-Host "Listening on $prefix"

while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    if ($request.HttpMethod -ne "POST") {
      $response.StatusCode = 405
      $response.Close()
      continue
    }

    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
    $body = $reader.ReadToEnd()
    $reader.Close()

    $payload = $body | ConvertFrom-Json
    $url = [string]$payload.url

    if ([string]::IsNullOrWhiteSpace($url) -or -not $url.StartsWith("sail3dl://")) {
      $response.StatusCode = 400
      $bytes = [System.Text.Encoding]::UTF8.GetBytes("Invalid or missing sail3dl url")
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
      $response.Close()
      continue
    }

    Write-Host "Opening protocol url: $url"
    Start-Process $url

    $response.StatusCode = 200
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("OK")
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.Close()
  }
  catch {
    Write-Error $_
  }
}
