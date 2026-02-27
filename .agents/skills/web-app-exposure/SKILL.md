# Spot Web App Exposure System

Expose web apps to the public internet via nginx reverse proxy.

## Directory & Permissions

- **Config directory:** `/etc/nginx/spot-apps/` (writable by Spot)
- **Nginx reload:** `sudo systemctl reload nginx` (no password needed)
- **Public URL pattern:** `https://data.basicbold.de/spot/<app-name>/`

## To Expose a New App

### 1. Start the app on a port (3000-3099 recommended)

```bash
cd /path/to/app
nohup npm run dev > /tmp/app.log 2>&1 &
```

### 2. Create nginx config

Create `/etc/nginx/spot-apps/<app-name>.conf`:

```nginx
location /spot/<app-name>/ {
    proxy_pass http://127.0.0.1:<PORT>/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect / /spot/<app-name>/;
}
```

### 3. Reload nginx

```bash
sudo systemctl reload nginx
```

### 4. Access at

```
https://data.basicbold.de/spot/<app-name>/
```

## Framework-Specific Configuration

### Next.js

Add to `next.config.js` or `next.config.ts`:

```javascript
module.exports = {
  basePath: '/spot/<app-name>',
  assetPrefix: '/spot/<app-name>',
  trailingSlash: true,
  // ... other config
}
```

**Important:** 
- `trailingSlash: true` is required for nginx proxy compatibility
- Restart the dev server after changing config

### WebSocket Apps

For WebSocket servers, add a separate config with longer timeout:

```nginx
location /spot/<app-name>-ws/ {
    proxy_pass http://127.0.0.1:<WS_PORT>/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_read_timeout 86400;
}
```

## Current Deployments

| App | Port | Path | Status |
|-----|------|------|--------|
| rage-viz | 3000 | /spot/rage-viz/ | Active |
| rage-ws | 8765 | /spot/rage-ws/ | Active |

## Troubleshooting

### 404 Not Found
- Check basePath matches nginx location
- Restart the dev server after config changes
- Verify app is running: `ss -tlnp | grep <PORT>`

### 502 Bad Gateway
- App not running on expected port
- Check app logs for errors

### WebSocket Connection Failed
- Ensure proxy_http_version 1.1 and Upgrade headers are set
- Check proxy_read_timeout for long-lived connections
