# Let's Encrypt Certificate Setup Guide

This guide will help you replace your self-signed certificate with a trusted Let's Encrypt certificate.

## Prerequisites

Before starting, you need:

### 1. Domain Name
- **Purchase a domain name** from any registrar (GoDaddy, Namecheap, etc.)
- **OR use a free dynamic DNS service** like:
  - Duck DNS (duckdns.org)
  - No-IP (noip.com)
  - DynDNS

### 2. DNS Configuration
Point your domain to your public IP address:
- **Your current public IP**: `98.192.215.212`
- Create an **A record** in your DNS settings pointing to this IP

### 3. Router Configuration
Configure port forwarding on your router:
- **Port 80** (HTTP) → 192.168.0.9:80
- **Port 443** (HTTPS) → 192.168.0.9:443

### 4. Firewall Configuration
Allow incoming connections:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Quick Setup with Duck DNS (Free Option)

If you don't have a domain, you can use Duck DNS for free:

1. **Go to https://www.duckdns.org/**
2. **Sign in** with Google/GitHub/etc.
3. **Create a subdomain** (e.g., `myyelp.duckdns.org`)
4. **Set the IP** to your public IP: `98.192.215.212`
5. **Install the Duck DNS client** on your Pi:

```bash
# Create directory
mkdir ~/duckdns
cd ~/duckdns

# Download script
wget "https://www.duckdns.org/update?domains=YOUR_SUBDOMAIN&token=YOUR_TOKEN&ip=" -O duck.sh
chmod +x duck.sh

# Test it
./duck.sh

# Set up cron job for auto-updates
echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1" | crontab -
```

## Let's Encrypt Setup Steps

### Step 1: Check Requirements
```bash
./letsencrypt-setup.sh check
```

### Step 2: Verify Domain Setup
Replace `yourdomain.com` with your actual domain:
```bash
./letsencrypt-setup.sh verify yourdomain.com
```

### Step 3: Complete Setup
Replace with your domain and email:
```bash
./letsencrypt-setup.sh setup yourdomain.com your-email@example.com
```

### Step 4: Rebuild Application
After certificate setup, rebuild your containers:
```bash
docker-compose -f docker-compose.local.yml down
docker-compose -f docker-compose.local.yml up -d --build
```

## Manual Step-by-Step Process

If you prefer to do it manually:

### 1. Prepare Nginx for Verification
```bash
# Temporary HTTP-only config for Let's Encrypt verification
sudo ./letsencrypt-setup.sh verify yourdomain.com
```

### 2. Obtain Certificate
```bash
sudo certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  --domains yourdomain.com
```

### 3. Update Nginx Configuration
```bash
./letsencrypt-setup.sh configure yourdomain.com
```

### 4. Test Certificate
```bash
./letsencrypt-setup.sh test yourdomain.com
```

## Troubleshooting

### Common Issues

#### 1. Domain Not Accessible
**Error**: "Domain is not accessible via HTTP"

**Solutions**:
- Check port forwarding on your router (port 80 → 192.168.0.9)
- Verify DNS propagation: `nslookup yourdomain.com`
- Test from external network: `curl http://yourdomain.com`

#### 2. Certificate Verification Failed
**Error**: "Failed to obtain certificate"

**Solutions**:
- Ensure domain points to correct IP
- Check firewall rules: `sudo ufw status`
- Verify nginx is serving on port 80
- Check Let's Encrypt logs: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`

#### 3. Rate Limiting
**Error**: "Too many certificates already issued"

**Solutions**:
- Let's Encrypt has rate limits (50 certificates per week per domain)
- Use staging environment for testing: `--staging` flag
- Wait for rate limit to reset

### Testing Commands

```bash
# Test domain resolution
nslookup yourdomain.com

# Test HTTP accessibility from outside
curl -I http://yourdomain.com/

# Test port connectivity
telnet yourdomain.com 80
telnet yourdomain.com 443

# Check certificate details
openssl s_client -servername yourdomain.com -connect yourdomain.com:443

# Check nginx configuration
sudo nginx -t

# View Let's Encrypt logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Automatic Renewal

Let's Encrypt certificates expire every 90 days. Set up automatic renewal:

```bash
# Setup auto-renewal
./letsencrypt-setup.sh auto-renew

# Test renewal
sudo certbot renew --dry-run

# Check renewal status
systemctl status certbot.timer
```

## Network Configuration Examples

### Router Port Forwarding
Most routers have a similar setup:
1. Log into your router's admin panel (usually 192.168.1.1 or 192.168.0.1)
2. Look for "Port Forwarding" or "Virtual Servers"
3. Add rules:
   - **Service**: HTTP, **External Port**: 80, **Internal IP**: 192.168.0.9, **Internal Port**: 80
   - **Service**: HTTPS, **External Port**: 443, **Internal IP**: 192.168.0.9, **Internal Port**: 443

### Firewall Configuration
```bash
# Check current rules
sudo ufw status

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall if not already enabled
sudo ufw enable
```

## Security Considerations

### After Setup
1. **Remove self-signed certificates**:
   ```bash
   sudo rm -f /etc/nginx/ssl/yelp-api.*
   ```

2. **Update security headers** (already included in script)

3. **Monitor certificate expiry**:
   ```bash
   sudo certbot certificates
   ```

### Best Practices
- Keep your system updated
- Monitor renewal logs
- Use strong passwords for router/DNS accounts
- Consider using Cloudflare for additional security

## Access URLs After Setup

Once complete, your application will be available at:
- **Frontend**: https://yourdomain.com/
- **API Documentation**: https://yourdomain.com/docs
- **API Endpoints**: https://yourdomain.com/api/v1/...

The certificate will be trusted by all browsers with no security warnings!

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot User Guide](https://certbot.eff.org/docs/using.html)
- [Duck DNS Setup Guide](https://www.duckdns.org/install.jsp)
- [SSL Labs SSL Test](https://www.ssllabs.com/ssltest/)

## Support

If you encounter issues:
1. Run `./letsencrypt-setup.sh check` for basic diagnostics
2. Check logs in `/var/log/letsencrypt/`
3. Verify DNS and port forwarding
4. Test from an external network