#!/bin/bash

# Let's Encrypt SSL Certificate Setup for Yelp API
# This script helps set up Let's Encrypt certificates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_SITE="/etc/nginx/sites-available/yelp-api"
SSL_DIR="/etc/nginx/ssl"

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

check_requirements() {
    print_status "Checking Let's Encrypt requirements..."
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot is not installed. Please run: sudo apt install certbot python3-certbot-nginx"
        return 1
    fi
    
    # Check if nginx is running
    if ! systemctl is-active --quiet nginx; then
        print_error "Nginx is not running. Please start it first."
        return 1
    fi
    
    # Check public IP
    PUBLIC_IP=$(curl -4 -s ifconfig.me || echo "unknown")
    print_info "Your public IP address: $PUBLIC_IP"
    
    print_status "✓ Basic requirements check passed"
}

check_domain_setup() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        print_error "Domain name is required"
        return 1
    fi
    
    print_status "Checking domain setup for: $domain"
    
    # Check if domain resolves to public IP
    DOMAIN_IP=$(dig +short "$domain" | tail -n1)
    PUBLIC_IP=$(curl -4 -s ifconfig.me)
    
    print_info "Domain $domain resolves to: ${DOMAIN_IP:-'not found'}"
    print_info "Your public IP: $PUBLIC_IP"
    
    if [ "$DOMAIN_IP" != "$PUBLIC_IP" ]; then
        print_warning "Domain does not resolve to your public IP!"
        print_warning "Please configure your DNS to point $domain to $PUBLIC_IP"
        return 1
    fi
    
    # Test HTTP connectivity
    print_status "Testing HTTP connectivity..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$domain/" | grep -q "200\|301\|302"; then
        print_status "✓ Domain is accessible via HTTP"
    else
        print_error "✗ Domain is not accessible via HTTP"
        print_error "Please check:"
        print_error "1. Port forwarding (port 80) on your router"
        print_error "2. Firewall settings (allow port 80)"
        print_error "3. Nginx is running and serving your site"
        return 1
    fi
    
    print_status "✓ Domain setup verification passed"
}

setup_nginx_for_letsencrypt() {
    local domain="$1"
    
    print_status "Preparing nginx configuration for Let's Encrypt..."
    
    # Create a temporary nginx config that serves HTTP only for verification
    sudo tee "$NGINX_SITE" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other traffic to existing app
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Test nginx configuration
    if sudo nginx -t; then
        sudo nginx -s reload
        print_status "✓ Nginx configuration updated for Let's Encrypt"
    else
        print_error "Nginx configuration test failed"
        return 1
    fi
}

obtain_certificate() {
    local domain="$1"
    local email="$2"
    
    if [ -z "$email" ]; then
        print_error "Email address is required for Let's Encrypt"
        return 1
    fi
    
    print_status "Obtaining Let's Encrypt certificate for $domain..."
    
    # Create webroot directory
    sudo mkdir -p /var/www/html
    
    # Obtain certificate using webroot method
    if sudo certbot certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email "$email" \
        --agree-tos \
        --no-eff-email \
        --domains "$domain"; then
        
        print_status "✓ Certificate obtained successfully!"
        
        # Show certificate info
        sudo certbot certificates
        
    else
        print_error "Failed to obtain certificate"
        print_error "Common issues:"
        print_error "1. Domain not accessible from internet"
        print_error "2. Port 80 not forwarded or blocked"
        print_error "3. DNS not properly configured"
        return 1
    fi
}

configure_nginx_ssl() {
    local domain="$1"
    
    print_status "Configuring nginx with Let's Encrypt certificate..."
    
    # Update nginx configuration to use Let's Encrypt certificate
    sudo tee "$NGINX_SITE" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    # Let's Encrypt SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
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

    # Frontend (React App) - Default location
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # CORS headers for API
        add_header 'Access-Control-Allow-Origin' 'https://$domain' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://$domain' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }

    # API Documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # OpenAPI JSON
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Test nginx configuration
    if sudo nginx -t; then
        sudo nginx -s reload
        print_status "✓ Nginx configured with Let's Encrypt certificate"
    else
        print_error "Nginx configuration test failed"
        return 1
    fi
}

update_application_config() {
    local domain="$1"
    
    print_status "Updating application configuration for domain: $domain"
    
    # Update frontend environment
    if [ -f "$SCRIPT_DIR/frontend/.env.production" ]; then
        sed -i "s|REACT_APP_API_URL=.*|REACT_APP_API_URL=https://$domain|" "$SCRIPT_DIR/frontend/.env.production"
        print_status "✓ Updated frontend environment"
    fi
    
    # Update API service configuration
    if [ -f "$SCRIPT_DIR/frontend/src/services/api.ts" ]; then
        sed -i "s|return 'https://.*';|return 'https://$domain';|" "$SCRIPT_DIR/frontend/src/services/api.ts"
        print_status "✓ Updated API service configuration"
    fi
    
    # Update CORS configuration in backend
    if [ -f "$SCRIPT_DIR/src/main.py" ]; then
        # Add the new domain to CORS origins if not already present
        if ! grep -q "https://$domain" "$SCRIPT_DIR/src/main.py"; then
            sed -i "/allow_origins=\[/a\\        \"https://$domain\"," "$SCRIPT_DIR/src/main.py"
            print_status "✓ Updated CORS configuration"
        fi
    fi
    
    print_status "Application configuration updated. You may need to rebuild containers:"
    print_info "docker-compose -f docker-compose.local.yml up -d --build"
}

test_certificate() {
    local domain="$1"
    
    print_status "Testing Let's Encrypt certificate..."
    
    # Test HTTPS connection
    if curl -s -o /dev/null -w "%{http_code}" "https://$domain/" | grep -q "200"; then
        print_status "✓ HTTPS frontend accessible"
    else
        print_warning "✗ HTTPS frontend not accessible"
    fi
    
    # Test certificate validity
    print_info "Certificate information:"
    echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -issuer -subject -dates
    
    # SSL Labs test (optional)
    print_info "For a complete SSL test, visit: https://www.ssllabs.com/ssltest/analyze.html?d=$domain"
}

setup_auto_renewal() {
    print_status "Setting up automatic certificate renewal..."
    
    # Check if certbot timer is enabled
    if systemctl is-enabled certbot.timer &>/dev/null; then
        print_status "✓ Certbot auto-renewal is already enabled"
    else
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
        print_status "✓ Enabled certbot auto-renewal"
    fi
    
    # Test renewal
    print_status "Testing certificate renewal..."
    if sudo certbot renew --dry-run; then
        print_status "✓ Certificate renewal test passed"
    else
        print_warning "Certificate renewal test failed"
    fi
    
    print_info "Certificates will be automatically renewed before expiry"
}

show_usage() {
    echo "Let's Encrypt Certificate Setup for Yelp API"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  check                           - Check requirements and current setup"
    echo "  setup <domain> <email>          - Complete Let's Encrypt setup"
    echo "  verify <domain>                 - Verify domain configuration"
    echo "  obtain <domain> <email>         - Obtain certificate only"
    echo "  configure <domain>              - Configure nginx with existing certificate"
    echo "  test <domain>                   - Test certificate"
    echo "  renew                           - Renew certificates"
    echo "  auto-renew                      - Setup automatic renewal"
    echo
    echo "Examples:"
    echo "  $0 setup example.com user@example.com"
    echo "  $0 verify example.com"
    echo "  $0 test example.com"
    echo
    echo "Prerequisites:"
    echo "  1. Domain name pointing to your public IP"
    echo "  2. Port 80 and 443 forwarded to this machine"
    echo "  3. Firewall allowing incoming connections on ports 80 and 443"
}

case "${1:-help}" in
    "check")
        check_requirements
        ;;
    "verify")
        if [ -z "$2" ]; then
            print_error "Domain name required"
            show_usage
            exit 1
        fi
        check_domain_setup "$2"
        ;;
    "setup")
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Domain name and email required"
            show_usage
            exit 1
        fi
        check_requirements
        check_domain_setup "$2"
        setup_nginx_for_letsencrypt "$2"
        obtain_certificate "$2" "$3"
        configure_nginx_ssl "$2"
        update_application_config "$2"
        setup_auto_renewal
        test_certificate "$2"
        print_status "🎉 Let's Encrypt setup complete!"
        print_info "Your site is now available at: https://$2"
        ;;
    "obtain")
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Domain name and email required"
            show_usage
            exit 1
        fi
        check_requirements
        setup_nginx_for_letsencrypt "$2"
        obtain_certificate "$2" "$3"
        ;;
    "configure")
        if [ -z "$2" ]; then
            print_error "Domain name required"
            show_usage
            exit 1
        fi
        configure_nginx_ssl "$2"
        update_application_config "$2"
        ;;
    "test")
        if [ -z "$2" ]; then
            print_error "Domain name required"
            show_usage
            exit 1
        fi
        test_certificate "$2"
        ;;
    "renew")
        print_status "Renewing certificates..."
        sudo certbot renew
        sudo nginx -s reload
        print_status "✓ Certificate renewal complete"
        ;;
    "auto-renew")
        setup_auto_renewal
        ;;
    "help"|*)
        show_usage
        ;;
esac