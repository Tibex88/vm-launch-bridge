using System.Net;
using System.Net.WebSockets;
using System.Text;

const string prefix = "http://+:12345/";

var listener = new HttpListener();
listener.Prefixes.Add(prefix);

try
{
    listener.Start();
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Failed to start listener on {prefix}");
    Console.Error.WriteLine(ex);
    return 1;
}

Console.WriteLine("Mock WebSocket server listening on ws://0.0.0.0:12345/");

while (true)
{
    try
    {
        var context = await listener.GetContextAsync();

        if (!context.Request.IsWebSocketRequest)
        {
            context.Response.StatusCode = 400;
            var buffer = Encoding.UTF8.GetBytes("Expected WebSocket request\n");
            await context.Response.OutputStream.WriteAsync(buffer);
            context.Response.Close();
            continue;
        }

        Console.WriteLine($"WebSocket client connected from {context.Request.RemoteEndPoint}");
        var wsContext = await context.AcceptWebSocketAsync(null);
        var socket = wsContext.WebSocket;
        var bufferReceive = new byte[8192];

        while (socket.State == WebSocketState.Open)
        {
            var result = await socket.ReceiveAsync(bufferReceive, CancellationToken.None);

            if (result.MessageType == WebSocketMessageType.Close)
            {
                Console.WriteLine("WebSocket client requested close");
                await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "bye", CancellationToken.None);
                break;
            }

            var message = Encoding.UTF8.GetString(bufferReceive, 0, result.Count);
            Console.WriteLine("Received WS payload:");
            Console.WriteLine(message);

            var reply = Encoding.UTF8.GetBytes("AUTH_OK");
            await socket.SendAsync(reply, WebSocketMessageType.Text, true, CancellationToken.None);
            Console.WriteLine("Sent AUTH_OK");
        }
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine(ex);
    }
}
