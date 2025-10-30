#!/bin/bash

# Port 80 Security Hardening Script
# Options for securing or removing port 80

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_current_setup() {
    print_status "Checking current port 80 configuration..."
    
    # Check UFW rules
    print_info "Current UFW rules for port 80:"
    sudo ufw status | grep "80" || echo "  No port 80 rules found"
    
    # Check if nginx is listening on port 80
    if netstat -tlnp | grep -q ":80 "; then
        print_info "✓ Nginx is listening on port 80"
    else
        print_warning "✗ Nothing listening on port 80"
    fi
    
    # Check for Let's Encrypt certificates
    if sudo find /etc/letsencrypt/live -name "fullchain.pem" 2>/dev/null | head -1 >/dev/null; then
        print_warning "⚠️  Let's Encrypt certificates detected - port 80 needed for renewal"
    else
        print_info "No Let's Encrypt certificates found"
    fi
}

implement_restricted_port80() {
    print_status "Implementing restricted port 80 (Recommended approach)..."
    
    # Copy the secure HTTP configuration
    if [ -f "nginx-secure-http.conf" ]; then
        print_status "Updating nginx configuration for secure HTTP..."
        
        # Backup current configuration
        sudo cp /etc/nginx/sites-available/yelp-api /etc/nginx/sites-available/yelp-api.backup
        
        # Update nginx configuration to use secure HTTP
        print_status "Creating secure nginx configuration..."
        
        # Get domain name from current config if available
        domain=$(grep "server_name" /etc/nginx/sites-available/yelp-api | head -1 | awk '{print $2}' | sed 's/;//')
        if [ -z "$domain" ] || [ "$domain" = "192.168.0.9" ]; then
            domain="192.168.0.9 localhost raspberrypi"
        fi
        
        # Create new secure configuration
        sudo tee /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
# Secure HTTP configuration - restricted port 80
server {
    listen 80;
    server_name $domain;
    
    # Security: Drop malicious requests immediately
    
    # Block specific admin paths (exact matches first)
    location = /admin { return 444; }
    location = /administrator { return 444; }
    location = /wp-admin { return 444; }
    location = /wp-login { return 444; }
    location = /login { return 444; }
    location = /phpmyadmin { return 444; }
    location = /mysql { return 444; }
    location = /database { return 444; }
    location = /backup { return 444; }
    location = /config { return 444; }
    
    # Block admin directories
    location ^~ /admin/ { return 444; }
    location ^~ /administrator/ { return 444; }
    location ^~ /wp-admin/ { return 444; }
    location ^~ /phpmyadmin/ { return 444; }
    
    # Block file extensions
    location ~* \.(php|asp|aspx|jsp|cgi|pl|py|sh|exe|dll|bat|cmd)$ {
        return 444;
    }
    
    # Block hidden files
    location ~ /\.(ht|env|git|svn) {
        return 444;
    }
    
    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
        access_log off;
        log_not_found off;
    }
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Redirect everything else to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;

    # SSL Configuration (detect Let's Encrypt vs self-signed)
EOF

        # Add SSL configuration based on what certificates exist
        if sudo find /etc/letsencrypt/live -name "fullchain.pem" 2>/dev/null | head -1 | read cert_file; then
            cert_domain=$(basename $(dirname "$cert_file"))
            sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
    ssl_certificate /etc/letsencrypt/live/$cert_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$cert_domain/privkey.pem;
EOF
        else
            sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
    ssl_certificate /etc/nginx/ssl/yelp-api.crt;
    ssl_certificate_key /etc/nginx/ssl/yelp-api.key;
EOF
        fi
        
        # Add the rest of the HTTPS configuration
        sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<'EOF'
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;  
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Frontend (React App)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API Documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # OpenAPI JSON
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_Set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
        
        # Test nginx configuration
        if sudo nginx -t; then
            print_status "✓ Nginx configuration is valid"
            sudo nginx -s reload
            print_status "✓ Nginx reloaded with secure HTTP configuration"
        else
            print_error "Nginx configuration test failed"
            sudo cp /etc/nginx/sites-available/yelp-api.backup /etc/nginx/sites-available/yelp-api
            return 1
        fi
        
        # Install new fail2ban filter
        sudo cp nginx-http-attacks.conf /etc/fail2ban/filter.d/
        sudo cp fail2ban.local /etc/fail2ban/jail.local
        sudo systemctl restart fail2ban
        
        print_status "✓ Enhanced fail2ban protection for HTTP attacks activated"
        
    else
        print_error "nginx-secure-http.conf not found"
        return 1
    fi
}

remove_port80_completely() {
    print_warning "Implementing complete port 80 removal (HTTPS only)..."
    print_warning "This will:"
    print_warning "- Remove port 80 from firewall"
    print_warning "- Configure nginx for HTTPS only"
    print_warning "- Break Let's Encrypt renewal (if using Let's Encrypt)"
    print_warning "- Break HTTP to HTTPS redirects"
    
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "Aborted"
        return 1
    fi
    
    # Remove port 80 from UFW
    print_status "Removing port 80 from firewall..."
    sudo ufw delete allow 80/tcp
    
    # Configure nginx for HTTPS only
    print_status "Configuring nginx for HTTPS only..."
    
    # Backup current configuration
    sudo cp /etc/nginx/sites-available/yelp-api /etc/nginx/sites-available/yelp-api.backup
    
    # Remove HTTP server block, keep only HTTPS
    domain=$(grep "server_name" /etc/nginx/sites-available/yelp-api | tail -1 | awk '{print $2}' | sed 's/;//')
    if [ -z "$domain" ] || [ "$domain" = "192.168.0.9" ]; then
        domain="192.168.0.9 localhost raspberrypi"
    fi
    
    # Create HTTPS-only configuration
    sudo tee /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
# HTTPS-only configuration - no port 80
server {
    listen 443 ssl http2;
    server_name $domain;
EOF
    
    # Add SSL configuration
    if sudo find /etc/letsencrypt/live -name "fullchain.pem" 2>/dev/null | head -1 | read cert_file; then
        cert_domain=$(basename $(dirname "$cert_file"))
        sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
    
    ssl_certificate /etc/letsencrypt/live/$cert_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$cert_domain/privkey.pem;
EOF
        print_warning "⚠️  Let's Encrypt certificates detected!"
        print_warning "⚠️  Certificate renewal will fail without port 80!"
        print_warning "⚠️  Consider using DNS challenge for renewals"
    else
        sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<EOF
    
    ssl_certificate /etc/nginx/ssl/yelp-api.crt;
    ssl_certificate_key /etc/nginx/ssl/yelp-api.key;
EOF
    fi
    
    # Add the rest of the configuration
    sudo tee -a /etc/nginx/sites-available/yelp-api > /dev/null <<'EOF'
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Enhanced Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; img-src 'self' data:; font-src 'self'; connect-src 'self';" always;

    # Application routes (same as before)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_Set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    # Test and reload nginx
    if sudo nginx -t; then
        print_status "✓ Nginx configuration is valid"
        sudo nginx -s reload
        print_status "✓ Nginx reloaded - HTTPS only mode active"
    else
        print_error "Nginx configuration test failed"
        sudo cp /etc/nginx/sites-available/yelp-api.backup /etc/nginx/sites-available/yelp-api
        sudo ufw allow 80/tcp  # Restore port 80
        return 1
    fi
    
    print_status "✅ Port 80 completely removed - HTTPS only mode active"
    print_warning "Remember: Users must type 'https://' in their browsers"
}

restore_port80() {
    print_status "Restoring standard port 80 configuration..."
    
    # Restore UFW rule
    sudo ufw allow 80/tcp
    
    # Restore nginx configuration from backup
    if [ -f /etc/nginx/sites-available/yelp-api.backup ]; then
        sudo cp /etc/nginx/sites-available/yelp-api.backup /etc/nginx/sites-available/yelp-api
        sudo nginx -t && sudo nginx -s reload
        print_status "✓ Port 80 restored from backup"
    else
        print_warning "No backup found - you may need to reconfigure nginx manually"
    fi
}

show_current_security() {
    print_status "Current security status:"
    
    # UFW status
    print_info "Firewall rules:"
    sudo ufw status | grep -E "(80|443)"
    
    # Nginx listening ports
    print_info "Nginx listening ports:"
    sudo netstat -tlnp | grep nginx | grep -E ":80|:443"
    
    # Fail2ban status
    print_info "Fail2ban jails:"
    sudo fail2ban-client status | grep "Jail list"
}

case "${1:-check}" in
    "check")
        check_current_setup
        ;;
    "restrict")
        implement_restricted_port80
        print_status "✅ Port 80 restricted to essential functions only"
        print_info "Port 80 now only allows:"
        print_info "- Let's Encrypt certificate challenges"
        print_info "- HTTP to HTTPS redirects"
        print_info "- All attack patterns are blocked immediately"
        ;;
    "remove")
        remove_port80_completely
        ;;
    "restore")
        restore_port80
        ;;
    "status")
        show_current_security
        ;;
    *)
        echo "Port 80 Security Hardening"
        echo
        echo "Usage: $0 <command>"
        echo
        echo "Commands:"
        echo "  check     - Check current port 80 configuration"
        echo "  restrict  - Implement restricted port 80 (recommended)"
        echo "  remove    - Remove port 80 completely (HTTPS only)"
        echo "  restore   - Restore standard port 80 configuration"
        echo "  status    - Show current security status"
        echo
        echo "Recommended: Use 'restrict' for maximum security with functionality"
        echo "Only use 'remove' if you don't need Let's Encrypt renewals"
        ;;
esac