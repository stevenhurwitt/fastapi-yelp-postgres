# Security Hardening Guide for Yelp API

This guide covers the security measures implemented to protect your Yelp API server.

## ✅ Current Security Status

**Port 80 Security Enhancement: SUCCESSFULLY IMPLEMENTED**
- Malicious requests blocked with HTTP 444 (connection closed)
- Admin paths blocked: `/admin`, `/wp-admin`, `/phpmyadmin`, etc.
- Dangerous file extensions blocked: `.php`, `.asp`, `.env`, etc.
- Legitimate traffic redirects to HTTPS (301)
- Let's Encrypt challenges preserved for certificate renewal
- Security headers applied even on HTTP connections
- All security measures tested and verified working

## 🛡️ Security Stack Overview

Your server is now protected by multiple layers of security:

1. **UFW Firewall** - Network-level filtering
2. **Fail2ban** - Intrusion detection and prevention  
3. **Nginx Security Headers** - Application-level protection
4. **SSL/TLS Encryption** - Data in transit protection
5. **Rate Limiting** - DOS attack prevention

## 🚫 Fail2ban Configuration

### Active Protection Jails

- **SSH Protection** (`sshd`)
  - Monitors: `/var/log/auth.log`
  - Max attempts: 3 before 1-hour ban
  
- **FastAPI Authentication** (`fastapi-auth`)
  - Monitors: API authentication failures
  - Max attempts: 5 before 1-hour ban
  
- **Nginx HTTP Auth** (`nginx-http-auth`)
  - Monitors: Basic auth failures
  - Max attempts: 5 before 1-hour ban
  
- **Bot/Vulnerability Scanning** (`nginx-botsearch`)
  - Monitors: Attempts to access admin panels, config files
  - Max attempts: 10 before 2-hour ban
  
- **DOS Attack Prevention** (`nginx-dos`)
  - Monitors: High request rates
  - Max attempts: 100 requests/minute before 30-minute ban
  
- **Bad Bots** (`nginx-badbots`)
  - Monitors: Known malicious user agents
  - Max attempts: 2 before 24-hour ban

### Management Commands

```bash
# Check security status
./ssl-manager.sh security

# Detailed fail2ban status
./fail2ban-manager.sh status

# View currently banned IPs
./fail2ban-manager.sh banned

# View recent attacks
./fail2ban-manager.sh attacks

# Live monitoring
./fail2ban-manager.sh monitor

# Unban an IP (if needed)
./fail2ban-manager.sh unban 192.168.1.100

# Add IP to permanent whitelist
./fail2ban-manager.sh whitelist 192.168.1.100
```

## 🔥 Firewall Configuration

### Current UFW Rules
```bash
# Check firewall status
sudo ufw status

# Current configuration:
# - Port 22 (SSH): Limited (rate-limited)
# - Port 80 (HTTP): Limited (rate-limited) 
# - Port 443 (HTTPS): Limited (rate-limited)
# - All other ports: Blocked
```

### UFW Rate Limiting
- **LIMIT rules** allow max 6 connections per 30 seconds
- Prevents connection flooding attacks
- Automatically blocks IPs exceeding limits

## 🔒 Nginx Security Headers

Your nginx configuration includes these security headers:

```nginx
# Security Headers (already configured)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### What They Protect Against:
- **HSTS**: Forces HTTPS connections
- **X-Frame-Options**: Prevents clickjacking
- **X-Content-Type-Options**: Prevents MIME sniffing attacks
- **X-XSS-Protection**: Basic XSS protection
- **Referrer-Policy**: Controls referrer information leakage

## 📊 Monitoring and Alerts

### Log Locations
```bash
# Fail2ban logs
sudo tail -f /var/log/fail2ban.log

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs  
sudo tail -f /var/log/nginx/error.log

# System authentication logs
sudo tail -f /var/log/auth.log
```

### Regular Monitoring Commands
```bash
# Daily security check
./ssl-manager.sh security

# Check for attacks
./fail2ban-manager.sh attacks

# View active connections
netstat -tuln

# Check system resources
htop
```

## ⚠️ Common Attack Patterns Detected

Fail2ban will automatically block these attack types:

### 1. Vulnerability Scanners
- Requests to `/admin`, `/wp-admin`, `/phpmyadmin`
- Searching for config files (`.env`, `wp-config.php`)
- Directory traversal attempts (`../../../etc/passwd`)

### 2. Bot Attacks
- High-frequency automated requests
- Known malicious user agents
- SQL injection attempts in URLs

### 3. Brute Force Attacks
- Multiple failed login attempts
- SSH connection attempts
- API authentication failures

### 4. DOS Attacks
- Excessive requests in short time periods
- Connection flooding
- Resource exhaustion attempts

## 🚨 Emergency Procedures

### If Under Attack
```bash
# 1. Check current security status
./ssl-manager.sh security

# 2. View active attacks
./fail2ban-manager.sh attacks

# 3. Monitor live activity
./fail2ban-manager.sh monitor

# 4. If needed, temporarily block all traffic except local
sudo ufw default deny incoming

# 5. Check system resources
htop
df -h
```

### Manual IP Blocking
```bash
# Block specific IP immediately
./fail2ban-manager.sh ban 192.168.1.100

# Block entire subnet
sudo ufw deny from 192.168.1.0/24

# Emergency: Block all external traffic
sudo ufw default deny incoming
```

### Recovery Procedures
```bash
# Unban your own IP if accidentally blocked
./fail2ban-manager.sh unban YOUR_IP

# Add your IP to permanent whitelist
./fail2ban-manager.sh whitelist YOUR_IP

# Reset firewall to default
sudo ufw --force reset
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw limit ssh
sudo ufw limit 80/tcp
sudo ufw limit 443/tcp
sudo ufw enable
```

## 📈 Security Metrics and KPIs

### Key Metrics to Monitor
- **Failed authentication attempts per hour**
- **Banned IPs per day**
- **Attack origin countries**
- **Most targeted endpoints**
- **Response time impact from security measures**

### Performance Impact
- **Fail2ban**: Minimal CPU/memory usage (~20MB)
- **UFW**: No noticeable performance impact
- **Security headers**: <1ms additional response time
- **Rate limiting**: Prevents resource exhaustion

## 🔧 Advanced Configuration

### Custom Fail2ban Rules
To create custom rules for your specific needs:

```bash
# Edit jail configuration
sudo nano /etc/fail2ban/jail.local

# Create custom filter
sudo nano /etc/fail2ban/filter.d/custom-filter.conf

# Restart fail2ban
sudo systemctl restart fail2ban
```

### Whitelist Trusted IPs
```bash
# Your current local network is already whitelisted:
# 127.0.0.1/8 (localhost)
# 192.168.0.0/16 (local network)
# 10.0.0.0/8 (private networks)
# 172.16.0.0/12 (private networks)

# Add additional trusted IPs
./fail2ban-manager.sh whitelist 203.0.113.1
```

### Email Notifications (Optional)
To receive email alerts for security events:

```bash
# Edit fail2ban configuration
sudo nano /etc/fail2ban/jail.local

# Uncomment and configure:
# destemail = your-email@example.com
# sendername = Fail2Ban-YelpAPI
# sender = fail2ban@yourdomain.com

# Install mail server
sudo apt install postfix mailutils
```

## 🛠️ Maintenance Tasks

### Daily
- Check security status: `./ssl-manager.sh security`
- Review attack summary: `./fail2ban-manager.sh attacks`

### Weekly  
- Update system: `sudo apt update && sudo apt upgrade`
- Review fail2ban logs: `./fail2ban-manager.sh logs 200`
- Check disk space: `df -h`

### Monthly
- Review and clean old logs
- Update security configurations
- Test backup/recovery procedures
- Review firewall rules

## 📚 Security Best Practices

### Operational Security
1. **Keep system updated** - Regular security patches
2. **Monitor logs daily** - Early detection of threats
3. **Use strong passwords** - For all accounts
4. **Limit SSH access** - Key-based authentication preferred
5. **Regular backups** - Both data and configuration

### Application Security
1. **Input validation** - Already implemented in FastAPI
2. **Rate limiting** - Configured in nginx and fail2ban
3. **HTTPS only** - HTTP automatically redirects
4. **Security headers** - Comprehensive protection
5. **Database security** - PostgreSQL hardening

### Network Security
1. **Firewall rules** - Minimal open ports
2. **Intrusion detection** - Fail2ban monitoring
3. **Traffic analysis** - Regular log review
4. **VPN access** - Consider for administrative tasks

## 🆘 Support and Resources

### Documentation Files
- `SSL_SETUP_GUIDE.md` - SSL/HTTPS configuration
- `LETSENCRYPT_GUIDE.md` - Certificate management
- `SECURITY_GUIDE.md` - This file

### Useful Commands Reference
```bash
# Security overview
./ssl-manager.sh security

# Fail2ban management  
./fail2ban-manager.sh status

# System monitoring
htop
sudo netstat -tuln
sudo ss -tuln

# Log analysis
sudo tail -f /var/log/fail2ban.log
sudo grep "$(date '+%Y-%m-%d')" /var/log/nginx/access.log
```

Your Yelp API server is now comprehensively protected against common web attacks and intrusion attempts!