# Sail3 API Proxy

This Docker proxy lets the Windows VM call the production hostname while actually hitting the local backend running on the Mac host.

## What it does

- listens on host port `80`
- accepts requests for `sail3-api.eu-north-1.elasticbeanstalk.com`
- forwards them to `http://host.docker.internal:5095`

## Start

```bash
cd /Users/m4pro/git/vm-launch-bridge/proxy
docker compose up -d
```

## Stop

```bash
cd /Users/m4pro/git/vm-launch-bridge/proxy
docker compose down
```

## Verify on the Mac

```bash
curl -i http://127.0.0.1/api/account/info \
  -H 'Host: sail3-api.eu-north-1.elasticbeanstalk.com'
```

You should see the same response your local backend would return on port `5095`.

## Windows VM hosts override

Run Notepad as Administrator and add this line to:

`C:\Windows\System32\drivers\etc\hosts`

```text
10.0.2.2 sail3-api.eu-north-1.elasticbeanstalk.com
```

If your VM is not using the default NAT host gateway, replace `10.0.2.2` with the host IP the VM can reach.

## Notes

- your local backend must be running on the Mac on port `5095`
- this only solves routing; token validation still depends on the backend issuing the token the game expects
- if port `80` is already in use on the Mac, free it before starting the proxy
