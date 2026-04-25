# 🔐 SSL Certificate Installation Guide for Microsoft Edge

## Download the Certificate

The SSL certificate for your Yelp API has been copied to:
```
/home/steven/fastapi-yelp-postgres/yelp-api-certificate.crt
```

### Method 1: Direct Download (Easiest)

1. **Visit the certificate download page**:
   - Open Microsoft Edge
   - Navigate to: `https://192.168.0.9/cert-install`
   - You'll see a styled download page with instructions
   - Click the **"🔒 Download Certificate (.crt)"** button
   - The certificate will download as `yelp-api-certificate.crt`

2. **Alternative direct download**:
   - Navigate directly to: `https://192.168.0.9/certificate`
   - The certificate will download automatically

### Method 2: Download via Browser Certificate Dialog

1. **Access the certificate via HTTPS**:
   - Open Microsoft Edge
   - Navigate to: `https://192.168.0.9`
   - You'll see a security warning about the untrusted certificate

2. **Download the certificate**:
   - Click the **lock icon** or **"Not secure"** warning in the address bar
   - Click **"Certificate is not valid"** or **"Certificate"**
   - In the certificate dialog, click **"Details"** tab
   - Click **"Copy to File..."** button
   - Choose **"Base-64 encoded X.509 (.CER)"** format
   - Save as `yelp-api-certificate.cer`

### Method 3: Direct File Transfer

If you have file access to the server:
1. Copy the file `yelp-api-certificate.crt` to your Windows machine
2. The certificate is ready to install (no need to rename)

---

## Install Certificate in Microsoft Edge

### Step 1: Open Certificate Manager

**Option A - Via Edge Settings:**
1. Open Microsoft Edge
2. Click the three dots menu (⋯) → **Settings**
3. Search for **"certificates"** or go to **Privacy, search, and services**
4. Scroll down to **Security** section
5. Click **"Manage certificates"**

**Option B - Via Windows (Faster):**
1. Press `Windows + R`
2. Type `certmgr.msc` and press Enter
3. This opens the Certificate Manager directly

### Step 2: Import the Certificate

1. In Certificate Manager, expand **"Trusted Root Certification Authorities"**
2. Right-click on **"Certificates"** folder
3. Select **"All Tasks"** → **"Import..."**
4. Click **"Next"** in the Certificate Import Wizard
5. Click **"Browse"** and select your `yelp-api-certificate.cer` file
6. Click **"Next"**
7. **IMPORTANT**: Select **"Place all certificates in the following store"**
8. Make sure **"Trusted Root Certification Authorities"** is selected
9. Click **"Next"** then **"Finish"**
10. Click **"Yes"** when Windows asks for confirmation

### Step 3: Verify Installation

1. Navigate to `https://192.168.0.9` in Edge
2. You should now see a **secure lock icon** 🔒
3. The certificate warning should be gone
4. The site should load without security warnings

---

## Certificate Details

**Certificate Information:**
- **Subject**: CN=192.168.0.9, O=YelpAPI, L=Local, ST=Virginia, C=US
- **Issuer**: Self-signed
- **Valid From**: October 29, 2025
- **Valid Until**: October 29, 2026
- **Serial Number**: 6f:3e:f6:68:8c:b1:8e:2e:9a:bb:60:30:2f:af:38:2f:e8:3b:99:3a
- **Algorithm**: SHA-256 with RSA Encryption
- **Key Size**: 2048 bits

---

## Alternative: Browser-Specific Exception

If you prefer not to install the certificate system-wide:

1. Navigate to `https://192.168.0.9`
2. Click **"Advanced"** on the security warning
3. Click **"Continue to 192.168.0.9 (unsafe)"**
4. Edge will remember this exception for the session

---

## Troubleshooting

### Certificate Not Trusted
- Make sure you installed it in **"Trusted Root Certification Authorities"**
- Restart Microsoft Edge after installation
- Clear browser cache if needed

### Still Getting Warnings
- Check that the certificate subject matches exactly: `192.168.0.9`
- Verify you're accessing `https://192.168.0.9` (not localhost or other IP)
- Ensure certificate is not expired

### Import Failed
- Make sure the certificate file has `.cer` or `.crt` extension
- Try "Base-64 encoded X.509" format if binary doesn't work
- Run Certificate Manager as Administrator if needed

---

## Security Note

⚠️ **Important**: This is a self-signed certificate for development/local use only. 

- Only install certificates you trust
- This certificate is only valid for `192.168.0.9`
- For production, use certificates from trusted Certificate Authorities (CA)

---

## 🍎 Installing Certificate on macOS

### Download Certificate for Mac

1. **Visit the certificate download page**:
   - Open Safari, Chrome, or Edge on Mac
   - Navigate to: `https://192.168.0.9/cert-install`
   - Click the **"🔒 Download Certificate (.crt)"** button
   - The certificate will download as `yelp-api-certificate.crt`

2. **Alternative direct download**:
   - Navigate directly to: `https://192.168.0.9/certificate`
   - The certificate will download automatically

### Method 1: Using Keychain Access (Recommended)

1. **Open Keychain Access**:
   - Press `Cmd + Space` and type "Keychain Access"
   - Or go to **Applications** → **Utilities** → **Keychain Access**

2. **Import the Certificate**:
   - In Keychain Access, select **"System"** keychain in the left sidebar
   - Drag and drop the `yelp-api-certificate.crt` file into the main window
   - Or use **File** → **Import Items...** and select the certificate

3. **Trust the Certificate**:
   - Find the certificate "192.168.0.9" in the list
   - Double-click on it to open certificate details
   - Expand the **"Trust"** section
   - Change **"When using this certificate"** to **"Always Trust"**
   - Enter your Mac password when prompted
   - Close the certificate window

### Method 2: Using Terminal (Alternative)

```bash
# Download certificate
curl -k https://192.168.0.9/certificate -o ~/Downloads/yelp-api-certificate.crt

# Add to System Keychain (requires admin password)
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/Downloads/yelp-api-certificate.crt
```

### Method 3: Double-Click Installation

1. **Download the certificate** using any method above
2. **Double-click** the `yelp-api-certificate.crt` file in Finder
3. **Keychain Access will open** automatically
4. **Choose "System" keychain** when prompted
5. **Enter your admin password**
6. **Trust the certificate** following step 3 from Method 1

### Verify Installation on Mac

1. **Open Safari** and navigate to `https://192.168.0.9`
2. You should see a **secure lock icon** 🔒 in the address bar
3. **No certificate warnings** should appear
4. The site should load normally

### Browser-Specific Notes for Mac

- **Safari**: Uses macOS Keychain (installation above works automatically)
- **Chrome**: Uses macOS Keychain (installation above works automatically)
- **Firefox**: Has its own certificate store (see Firefox section below)
- **Edge**: Uses macOS Keychain (installation above works automatically)

### Firefox on Mac (Special Instructions)

Firefox uses its own certificate store and requires separate installation:

1. **Open Firefox** and navigate to `https://192.168.0.9`
2. **Click "Advanced"** on the security warning
3. **Click "Accept the Risk and Continue"**
4. Or manually import:
   - Firefox → **Preferences** → **Privacy & Security**
   - Scroll to **Certificates** → **View Certificates**
   - **Authorities** tab → **Import...**
   - Select the certificate file
   - Check **"Trust this CA to identify websites"**

### Troubleshooting on Mac

**Error -25294 (Duplicate Item/Import Failed):**
This is a common Keychain error. Try these solutions in order:

1. **Clear existing certificate attempts:**
   ```bash
   # Remove any existing certificate with same name
   sudo security delete-certificate -c "192.168.0.9" /Library/Keychains/System.keychain 2>/dev/null
   security delete-certificate -c "192.168.0.9" ~/Library/Keychains/login.keychain 2>/dev/null
   ```

2. **Convert certificate format:**
   ```bash
   # Download and convert to PEM format
   curl -k https://192.168.0.9/certificate -o /tmp/cert.crt
   openssl x509 -in /tmp/cert.crt -out /tmp/cert.pem -outform PEM
   ```

3. **Import using terminal with specific format:**
   ```bash
   # Try importing the PEM version
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/cert.pem
   ```

4. **Alternative: Import to Login keychain first:**
   ```bash
   # Import to user keychain (no sudo needed)
   security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain /tmp/cert.crt
   ```

5. **Reset Keychain permissions:**
   ```bash
   # Fix keychain permissions
   sudo chmod 644 /Library/Keychains/System.keychain
   ```

**Certificate Not Trusted:**
- Make sure you selected **"System"** keychain during import
- Verify the trust setting is set to **"Always Trust"**
- Restart your browser after installation

**Still Getting Warnings:**
- Check Keychain Access to ensure certificate is in **System** keychain
- Verify certificate subject matches: `192.168.0.9`
- Clear browser cache and cookies

**Permission Issues:**
- You need admin privileges to add to System keychain
- Try using `sudo` with the terminal method
- Or add to "login" keychain instead (works for current user only)

**Keychain Access GUI Issues:**
- Try quitting and reopening Keychain Access
- Use Terminal method instead of GUI drag-and-drop
- Check if certificate file is corrupted by re-downloading

### Remove Certificate (If Needed)

To remove the certificate later:
1. **Open Keychain Access**
2. **Select "System" keychain**
3. **Find "192.168.0.9" certificate**
4. **Right-click** → **Delete**
5. **Enter admin password**

---

## Alternative Browsers

The same certificate can be installed in:
- **Chrome**: Uses Windows certificate store (Windows) or Keychain (Mac)
- **Firefox**: Has its own certificate store (different process on all platforms)
- **Safari** (macOS): Uses Keychain Access (instructions above)
- **Edge**: Uses system certificate store on both Windows and Mac

---

## Next Steps

After installing the certificate:
1. ✅ Browse to `https://192.168.0.9` - should show secure lock
2. ✅ Test the API endpoints - no SSL warnings
3. ✅ Frontend should work without timeout issues
4. ✅ Postman will also work with the installed certificate

The certificate installation will eliminate SSL handshake delays and timeout issues!