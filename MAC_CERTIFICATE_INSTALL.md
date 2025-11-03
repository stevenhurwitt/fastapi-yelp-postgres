# 🍎 Quick Mac Certificate Installation Guide

## Fast Installation (3 Steps)

### Step 1: Download Certificate
Visit: `https://192.168.0.9/cert-install` and click **"🔒 Download Certificate"**

### Step 2: Install via Keychain
```bash
# Option A: Double-click the downloaded file
open ~/Downloads/yelp-api-certificate.crt

# Option B: Terminal command
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/Downloads/yelp-api-certificate.crt
```

### Step 3: Verify
Open Safari → Navigate to `https://192.168.0.9` → Should see 🔒 secure lock

---

## Manual Keychain Method

1. **Open Keychain Access** (`Cmd + Space` → "Keychain Access")
2. **Select "System" keychain** (left sidebar)
3. **Drag & drop** `yelp-api-certificate.crt` into Keychain Access
4. **Double-click** the "192.168.0.9" certificate
5. **Expand "Trust" section**
6. **Set to "Always Trust"**
7. **Enter admin password**

---

## Browser Compatibility

| Browser | Works After Installation | Notes |
|---------|-------------------------|-------|
| **Safari** | ✅ Automatic | Uses macOS Keychain |
| **Chrome** | ✅ Automatic | Uses macOS Keychain |
| **Edge** | ✅ Automatic | Uses macOS Keychain |
| **Firefox** | ❌ Manual | Separate certificate store |

---

## Firefox Special Steps

1. Navigate to `https://192.168.0.9` in Firefox
2. Click **"Advanced"** → **"Accept the Risk and Continue"**
3. Or: Firefox → Preferences → Privacy & Security → Certificates → View Certificates → Authorities → Import

---

## Troubleshooting

### Error -25294 (Common Import Error)

This error usually means duplicate item or permission issue. Try these fixes:

```bash
# Step 1: Clean up any existing certificates
sudo security delete-certificate -c "192.168.0.9" /Library/Keychains/System.keychain 2>/dev/null
security delete-certificate -c "192.168.0.9" ~/Library/Keychains/login.keychain 2>/dev/null

# Step 2: Download fresh certificate and convert format
curl -k https://192.168.0.9/certificate -o /tmp/cert.crt
openssl x509 -in /tmp/cert.crt -out /tmp/cert.pem -outform PEM

# Step 3: Import using PEM format
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/cert.pem
```

### Alternative: Login Keychain (No Admin Required)

```bash
# Import to your personal keychain instead
security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain /tmp/cert.crt
```

### Still getting warnings?
- Restart browser after installation
- Check certificate is in **System** keychain (not Login)
- Verify trust setting is **"Always Trust"**

### Permission denied?
- Use `sudo` for terminal installation
- Or install in "Login" keychain (works for current user only)
- Check keychain permissions: `sudo chmod 644 /Library/Keychains/System.keychain`

---

## Terminal One-Liner

Download and install in one command:
```bash
curl -k https://192.168.0.9/certificate -o /tmp/cert.crt && sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/cert.crt && echo "Certificate installed! Restart your browser."
```

🎉 **That's it!** Your Mac will now trust the Yelp API certificate across all browsers (except Firefox).