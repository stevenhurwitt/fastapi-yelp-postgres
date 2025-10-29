#!/bin/bash

# SSL Management Script for Yelp API
# This script helps manage SSL certificates and nginx configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="/etc/nginx/ssl"
NGINX_SITE="/etc/nginx/sites-available/yelp-api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

check_ssl_status() {
    print_status "Checking SSL certificate status..."
    
    if [ -f "$SSL_DIR/yelp-api.crt" ] && [ -f "$SSL_DIR/yelp-api.key" ]; then
        print_status "SSL certificates found"
        openssl x509 -in "$SSL_DIR/yelp-api.crt" -text -noout | grep -E "(Subject:|Not After :|DNS:|IP Address:)"
    else
        print_error "SSL certificates not found"
        return 1
    fi
}

check_nginx_status() {
    print_status "Checking nginx status..."
    
    if systemctl is-active --quiet nginx; then
        print_status "Nginx is running"
        sudo netstat -tlnp | grep nginx | grep -E ":80|:443" || print_warning "Port information requires sudo"
    else
        print_error "Nginx is not running"
        return 1
    fi
}

check_containers_status() {
    print_status "Checking Docker containers status..."
    
    cd "$SCRIPT_DIR"
    docker-compose -f docker-compose.local.yml ps
}

test_https_connection() {
    print_status "Testing HTTPS connections..."
    
    # Test frontend
    print_status "Testing frontend (HTTPS)..."
    if curl -k -s -o /dev/null -w "%{http_code}" https://192.168.0.9/ | grep -q "200"; then
        print_status "✓ Frontend accessible via HTTPS"
    else
        print_error "✗ Frontend not accessible via HTTPS"
    fi
    
    # Test API docs
    print_status "Testing API docs (HTTPS)..."
    if curl -k -s -o /dev/null -w "%{http_code}" https://192.168.0.9/docs | grep -q "200"; then
        print_status "✓ API docs accessible via HTTPS"
    else
        print_error "✗ API docs not accessible via HTTPS"
    fi
    
    # Test HTTP redirect
    print_status "Testing HTTP to HTTPS redirect..."
    if curl -s -o /dev/null -w "%{http_code}" http://192.168.0.9/ | grep -q "301"; then
        print_status "✓ HTTP to HTTPS redirect working"
    else
        print_error "✗ HTTP to HTTPS redirect not working"
    fi
}

renew_certificate() {
    print_warning "Regenerating self-signed SSL certificate..."
    
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/yelp-api.key" \
        -out "$SSL_DIR/yelp-api.crt" \
        -subj "/C=US/ST=Virginia/L=Local/O=YelpAPI/CN=192.168.0.9" \
        -addext "subjectAltName=IP:192.168.0.9,DNS:localhost,DNS:raspberrypi"
    
    print_status "Certificate regenerated. Reloading nginx..."
    sudo nginx -s reload
    print_status "✓ Certificate renewal complete"
}

restart_services() {
    print_status "Restarting all services..."
    
    cd "$SCRIPT_DIR"
    
    # Restart Docker containers
    print_status "Restarting Docker containers..."
    docker-compose -f docker-compose.local.yml restart
    
    # Reload nginx
    print_status "Reloading nginx..."
    sudo nginx -s reload
    
    print_status "✓ All services restarted"
}

show_urls() {
    print_status "Access URLs:"
    echo "🌐 Frontend (HTTPS): https://192.168.0.9/"
    echo "📚 API Documentation: https://192.168.0.9/docs"  
    echo "🔧 API Health Check: https://192.168.0.9/health"
    echo "⚠️  Note: You may need to accept the self-signed certificate in your browser"
}

case "${1:-status}" in
    "status")
        print_status "=== SSL Setup Status ==="
        check_ssl_status
        echo
        check_nginx_status  
        echo
        check_containers_status
        echo
        test_https_connection
        echo
        show_urls
        ;;
    "test")
        test_https_connection
        ;;
    "renew")
        renew_certificate
        ;;
    "restart")
        restart_services
        ;;
    "urls")
        show_urls
        ;;
    *)
        echo "Usage: $0 [status|test|renew|restart|urls]"
        echo "  status  - Show complete SSL setup status (default)"
        echo "  test    - Test HTTPS connections"
        echo "  renew   - Regenerate SSL certificate"
        echo "  restart - Restart all services"
        echo "  urls    - Show access URLs"
        exit 1
        ;;
esac