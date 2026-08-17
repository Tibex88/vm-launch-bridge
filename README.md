# VM Launch Bridge

This folder contains no-website-code bridges for launching the Windows VM game from the Mac host.

## What it does

- The website continues to authenticate normally in the Mac browser.
- The website continues to send the game token over WebSocket to the game in the VM.
- Option A: a host-side script writes a launch command into a shared folder.
- Option B: a macOS `sail3dl://` handler forwards the full protocol URL to a tiny HTTP receiver in the Windows VM.

This keeps the website repo untouched.

## Folder layout

- `shared/`
  VirtualBox shared folder root. The Mac script writes command files here.
- `mac/trigger-launch.sh`
  Host-side script that writes a launch command file.
- `mac/build-handler.sh`
  Builds a minimal macOS app bundle that registers `sail3dl://` and forwards the URL to the VM receiver.
- `windows/config.ps1`
  Windows-side watcher config.
- `windows/Watch-LaunchFolder.ps1`
  Windows-side watcher loop.
- `windows/start-watcher.bat`
  Convenience launcher for the watcher.
- `windows/Receive-Sail3dl.ps1`
  Windows-side HTTP receiver that accepts forwarded `sail3dl://` URLs and opens them with the registered Windows handler.
- `windows/start-receiver.bat`
  Convenience launcher for the receiver.
- `windows/Mock-WebSocketServer.ps1`
  Tiny mock WebSocket server for validating what the website sends.
- `windows/start-mock-ws.bat`
  Convenience launcher for the mock WebSocket server.
- `windows/mock-ws-server.js`
  Tiny Node-based mock WebSocket server. Prefer this over the PowerShell mock if available.
- `windows/start-mock-ws-node.bat`
  Convenience launcher for the Node mock WebSocket server.

## Setup

### Shared-folder bridge

1. In VirtualBox, mount `/Users/m4pro/git/vm-launch-bridge/shared` as a shared folder into the Windows VM.
2. In Windows, confirm the shared folder path and update `windows/config.ps1` if needed.
3. In Windows, set `GameCommand` in `windows/config.ps1` to the launcher or `.exe` you want to start.
4. Start the watcher in the VM:

```bat
start-watcher.bat
```

5. From macOS, trigger a launch command:

```bash
./mac/trigger-launch.sh
```

Optional custom label:

```bash
./mac/trigger-launch.sh --label "manual test"
```

### Protocol-forwarding bridge

This option lets the Mac browser fire `sail3dl://...`, but the Windows VM handles it.

1. In VirtualBox, add a NAT port-forward rule:

```text
Name: Sail3dlReceiver
Protocol: TCP
Host IP:
Host Port: 4567
Guest IP:
Guest Port: 4567
```

2. In the Windows VM, start the receiver as Administrator:

```bat
start-receiver.bat
```

3. On macOS, build the protocol handler app:

```bash
./mac/build-handler.sh
```

4. Open the generated app once so Launch Services registers the custom scheme:

```bash
open ./mac/Sail3dlForwarder.app
```

After that, when the Mac browser fires `sail3dl://token?...`, the macOS handler app forwards the full URL to `http://127.0.0.1:4567/launch`, which VirtualBox forwards into the Windows VM. The Windows receiver then runs:

```powershell
Start-Process "<full sail3dl url>"
```

### Mock WebSocket test server

Use this when you want to validate the website WebSocket flow without depending on the game executable.

In the Windows VM:

Preferred if Node is installed:

```bat
start-mock-ws-node.bat
```

Fallback:

```bat
start-mock-ws.bat
```

The mock server listens on `ws://0.0.0.0:12345/`.

What it does:

- logs when a client connects
- logs the raw text message payload
- replies with `AUTH_OK`

This lets you confirm exactly what the website is sending.

## Notes

- The launch command file does not need to carry the auth token if your existing WebSocket auth path already works.
- If you later want to pass extra metadata, the JSON format already supports that.
- Processed command files are moved into `processed/` by the watcher.
- The protocol-forwarding path does not need the game `.exe` path, only the existing Windows `sail3dl://` handler.
