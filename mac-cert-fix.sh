#!/bin/bash

# Mac Certificate Installation Troubleshooter
# Fixes Error -25294 and other common Keychain issues

echo "🍎 Mac Certificate Installation Troubleshooter"
echo "=============================================="
echo
echo "This script will help fix Error -25294 and install the Yelp API certificate"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CERT_URL="https://192.168.0.9/certificate"
CERT_NAME="192.168.0.9"
TEMP_CERT="/tmp/yelp-cert.crt"
TEMP_PEM="/tmp/yelp-cert.pem"

echo -e "${BLUE}Step 1: Cleaning up existing certificates${NC}"
echo "Removing any existing certificates with the same name..."

# Remove from System keychain
sudo security delete-certificate -c "$CERT_NAME" /Library/Keychains/System.keychain 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Removed existing certificate from System keychain${NC}"
else
    echo -e "${YELLOW}ℹ️  No existing certificate found in System keychain${NC}"
fi

# Remove from Login keychain
security delete-certificate -c "$CERT_NAME" ~/Library/Keychains/login.keychain 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Removed existing certificate from Login keychain${NC}"
else
    echo -e "${YELLOW}ℹ️  No existing certificate found in Login keychain${NC}"
fi

echo
echo -e "${BLUE}Step 2: Downloading fresh certificate${NC}"
echo "Downloading certificate from: $CERT_URL"

curl -k "$CERT_URL" -o "$TEMP_CERT" --silent --show-error
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificate downloaded successfully${NC}"
    echo "Certificate saved to: $TEMP_CERT"
else
    echo -e "${RED}❌ Failed to download certificate${NC}"
    echo "Please check your network connection and try again"
    exit 1
fi

echo
echo -e "${BLUE}Step 3: Converting certificate format${NC}"
echo "Converting to PEM format to avoid import issues..."

openssl x509 -in "$TEMP_CERT" -out "$TEMP_PEM" -outform PEM 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificate converted to PEM format${NC}"
else
    echo -e "${YELLOW}⚠️  PEM conversion failed, using original format${NC}"
    TEMP_PEM="$TEMP_CERT"
fi

echo
echo -e "${BLUE}Step 4: Installing certificate${NC}"
echo "Attempting to install to System keychain (requires admin password)..."

sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TEMP_PEM"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificate installed successfully to System keychain!${NC}"
    INSTALL_SUCCESS=true
else
    echo -e "${RED}❌ Failed to install to System keychain${NC}"
    echo -e "${YELLOW}Trying Login keychain instead (no admin required)...${NC}"
    
    security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain "$TEMP_PEM"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Certificate installed successfully to Login keychain!${NC}"
        INSTALL_SUCCESS=true
    else
        echo -e "${RED}❌ Failed to install to Login keychain as well${NC}"
        INSTALL_SUCCESS=false
    fi
fi

echo
echo -e "${BLUE}Step 5: Verification${NC}"

if [ "$INSTALL_SUCCESS" = true ]; then
    echo "Checking if certificate is properly installed..."
    
    # Check System keychain
    security find-certificate -c "$CERT_NAME" /Library/Keychains/System.keychain >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Certificate found in System keychain${NC}"
        KEYCHAIN_LOCATION="System"
    else
        # Check Login keychain
        security find-certificate -c "$CERT_NAME" ~/Library/Keychains/login.keychain >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Certificate found in Login keychain${NC}"
            KEYCHAIN_LOCATION="Login"
        else
            echo -e "${RED}❌ Certificate not found in either keychain${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Restart your browser"
    echo "2. Visit https://192.168.0.9"
    echo "3. You should see a secure lock icon 🔒"
    echo
    echo -e "${BLUE}Certificate Details:${NC}"
    echo "📍 Location: $KEYCHAIN_LOCATION keychain"
    echo "🔗 Subject: $CERT_NAME"
    echo "🌐 Valid for: https://192.168.0.9"
    
else
    echo -e "${RED}❌ Installation failed${NC}"
    echo
    echo -e "${YELLOW}Alternative Solutions:${NC}"
    echo "1. Try running this script with sudo: sudo $0"
    echo "2. Manual installation via Keychain Access:"
    echo "   - Open Keychain Access"
    echo "   - File → Import Items → Select $TEMP_CERT"
    echo "3. Browser exception:"
    echo "   - Visit https://192.168.0.9"
    echo "   - Click 'Advanced' → 'Accept the Risk and Continue'"
fi

echo
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -f "$TEMP_CERT" "$TEMP_PEM"
echo -e "${GREEN}✅ Cleanup complete${NC}"

echo
echo "🔧 For more help, check:"
echo "   - MAC_CERTIFICATE_INSTALL.md"
echo "   - EDGE_CERTIFICATE_INSTALL.md (Mac section)"
echo "   - https://192.168.0.9/cert-install"