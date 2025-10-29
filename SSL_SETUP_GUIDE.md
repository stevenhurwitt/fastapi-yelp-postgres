# SSL/HTTPS Setup Guide

This guide explains the SSL/HTTPS setup for the Yelp Data API application.

## Overview

The application now runs with HTTPS encryption using:
- **Nginx** as a reverse proxy with SSL termination
- **Self-signed SSL certificates** for local development
- **Automatic HTTP to HTTPS redirect**
- **Docker containers** for the backend and frontend services

## Architecture

```
Browser (HTTPS) → Nginx (SSL) → Docker Containers (HTTP)
    ↓
https://192.168.0.9 → Frontend (React) on port 3000
https://192.168.0.9/api → Backend (FastAPI) on port 8000
```

## SSL Certificate Details

- **Type**: Self-signed certificate
- **Validity**: 1 year from creation
- **Subject**: CN=192.168.0.9
- **Subject Alternative Names**: 
  - IP: 192.168.0.9
  - DNS: localhost
  - DNS: raspberrypi

## Access URLs

- **Frontend**: https://192.168.0.9/
- **API Documentation**: https://192.168.0.9/docs
- **API Health Check**: https://192.168.0.9/health
- **API Endpoints**: https://192.168.0.9/api/v1/...

## Browser Security Warning

Since we're using a self-signed certificate, your browser will show a security warning the first time you visit. This is normal for self-signed certificates. To proceed:

1. Click "Advanced" or "Show Details"
2. Click "Proceed to 192.168.0.9 (unsafe)" or similar
3. Accept the certificate permanently for convenience

## Management Commands

Use the provided `ssl-manager.sh` script to manage the SSL setup:

```bash
# Check complete SSL status
./ssl-manager.sh status

# Test HTTPS connections
./ssl-manager.sh test

# Regenerate SSL certificate (if expired)
./ssl-manager.sh renew

# Restart all services
./ssl-manager.sh restart

# Show access URLs
./ssl-manager.sh urls
```

## Files Created/Modified

### SSL Files
- `/etc/nginx/ssl/yelp-api.crt` - SSL certificate
- `/etc/nginx/ssl/yelp-api.key` - SSL private key

### Nginx Configuration
- `/etc/nginx/sites-available/yelp-api` - Nginx site configuration
- `/etc/nginx/sites-enabled/yelp-api` - Enabled site symlink

### Application Configuration
- `nginx.conf` - Local copy of nginx configuration
- `frontend/.env.production` - Updated to use HTTPS
- `frontend/src/services/api.ts` - Updated API base URL
- `src/main.py` - Updated CORS configuration
- `ssl-manager.sh` - SSL management script

## Troubleshooting

### Certificate Issues
If you get certificate errors:
```bash
./ssl-manager.sh renew
```

### Service Issues
If services aren't responding:
```bash
./ssl-manager.sh restart
```

### Port Conflicts
If you get "address already in use" errors:
```bash
# Stop any conflicting services
sudo systemctl stop yelp-api  # If exists
sudo pkill -f uvicorn

# Restart containers
docker-compose -f docker-compose.local.yml restart
```

### Check Logs
```bash
# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Container logs
docker-compose -f docker-compose.local.yml logs -f web
docker-compose -f docker-compose.local.yml logs -f frontend
```

## Security Considerations

For **production deployment**, consider:

1. **Use a real SSL certificate** from Let's Encrypt or a Certificate Authority
2. **Configure proper firewall rules**
3. **Enable additional security headers**
4. **Use stronger SSL ciphers**
5. **Implement certificate pinning**

## Automated Startup

The current setup will automatically start on system boot:
- Nginx is enabled as a system service
- Docker containers can be set to restart automatically

To ensure containers start on boot, add to docker-compose.local.yml:
```yaml
services:
  web:
    restart: unless-stopped
  frontend:
    restart: unless-stopped
```

## Performance Optimization

For better performance in production:
- Enable gzip compression in nginx
- Add caching headers for static assets
- Use nginx rate limiting
- Optimize SSL session caching

The current configuration includes basic optimizations suitable for local development and small-scale deployment.