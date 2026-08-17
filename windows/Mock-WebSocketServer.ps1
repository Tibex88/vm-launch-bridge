param()

Add-Type -AssemblyName System.Net.Http

$listener = New-Object System.Net.HttpListener
$prefix = "http://+:12345/"
$listener.Prefixes.Add($prefix)

try {
  $listener.Start()
} catch {
  Write-Error "Failed to start mock WebSocket listener on $prefix. Run in an elevated PowerShell if needed. $_"
  exit 1
}

Write-Host "Mock WebSocket server listening on ws://0.0.0.0:12345/"

while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()

    if (-not $context.Request.IsWebSocketRequest) {
      $context.Response.StatusCode = 400
      $bytes = [System.Text.Encoding]::UTF8.GetBytes("Expected WebSocket request")
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $context.Response.Close()
      continue
    }

    Write-Host "WebSocket client connected from $($context.Request.RemoteEndPoint)"
    $wsContext = $context.AcceptWebSocketAsync($null).GetAwaiter().GetResult()
    $socket = $wsContext.WebSocket
    $buffer = New-Object byte[] 8192

    while ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
      $segment = [ArraySegment[byte]]::new($buffer)
      $result = $socket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

      if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        Write-Host "WebSocket client requested close"
        $socket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "bye", [Threading.CancellationToken]::None).GetAwaiter().GetResult()
        break
      }

      $message = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
      Write-Host "Received WS payload:"
      Write-Host $message

      $reply = [System.Text.Encoding]::UTF8.GetBytes("AUTH_OK")
      $replySegment = [ArraySegment[byte]]::new($reply)
      $socket.SendAsync($replySegment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
      Write-Host "Sent AUTH_OK"
    }
  }
  catch {
    Write-Error $_
  }
}
