# WsMockServer

Standalone Windows mock WebSocket server for testing the website connection flow.

It:

- listens on `ws://0.0.0.0:12345/`
- logs when a client connects
- logs the full incoming payload
- replies with `AUTH_OK`

Published executables are written under:

- `publish/win-x64/`
- `publish/win-arm64/`
