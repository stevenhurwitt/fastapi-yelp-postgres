# 🍓 Raspberry Pi Deployment Guide

## ✅ Backend Deployment (COMPLETED)

Your FastAPI backend is now running successfully!

- **API URL**: http://192.168.0.9:8000
- **Documentation**: http://192.168.0.9:8000/docs
- **Status**: ✅ Running with auto-reload

## 🎯 Frontend Deployment (Next Steps)

### 1. Install Node.js (Required for React frontend)

```bash
# Install Node.js 18.x LTS (recommended for Raspberry Pi)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### 2. Build and Serve Frontend

```bash
# Navigate to frontend directory
cd /home/steven/fastapi-yelp-postgres/frontend

# Install Node.js using snap (if not already installed)
sudo snap install node --classic

# Install dependencies
snap run node.npm install

# Build for production
snap run node.npm run build

# Serve the built frontend using Python (simplest method)
cd build && python3 -m http.server 3000 --bind 192.168.0.9

# Alternative: Use serve if you prefer
# snap run node.npm install --save-dev serve
# snap run node.npm exec serve -- -s build -p 3000 -H 192.168.0.9
```

### 3. Access Your Full Application

- **Frontend**: http://192.168.0.9:3000
- **Backend API**: http://192.168.0.9:8000
- **API Docs**: http://192.168.0.9:8000/docs

## 🔧 Production Setup Options

### Option A: Using PM2 (Process Manager)

```bash
# Install PM2
npm install -g pm2

# Start backend with PM2
pm2 start "/home/steven/fastapi-yelp-postgres/.venv/bin/uvicorn" --name "yelp-api" -- src.main:app --host 192.168.0.9 --port 8000

# Start frontend with PM2
cd /home/steven/fastapi-yelp-postgres/frontend
pm2 serve build 3000 --name "yelp-frontend"

# Save PM2 configuration
pm2 save
pm2 startup
```

### Option B: Using Systemd Services

```bash
# Copy the service file
sudo cp /home/steven/fastapi-yelp-postgres/yelp-api.service /etc/systemd/system/

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable yelp-api.service
sudo systemctl start yelp-api.service

# Check status
sudo systemctl status yelp-api.service
```

### Option C: Using Docker

```bash
# Build and run with Docker Compose (uses existing database)
docker-compose -f docker-compose.local.yml up -d

# View logs
docker-compose logs -f
```

## 🌐 Making It Accessible from Outside Your Network

### 1. Port Forwarding (Router Configuration)
- Forward port 8000 (API) and 3000 (Frontend) on your router
- Point them to your Raspberry Pi's IP (192.168.0.9)

### 2. Dynamic DNS (Optional)
```bash
# Install No-IP client for dynamic DNS
sudo apt-get install noip2
```

### 3. SSL Certificate (Optional)
```bash
# Install Certbot for Let's Encrypt SSL
sudo apt-get install certbot
# Configure SSL certificate (requires domain name)
```

## 📊 Performance Tips for Raspberry Pi

1. **Use a fast SD card** (Class 10 or better)
2. **Enable swap** if you have limited RAM:
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=1024
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```
3. **Monitor resources**: `htop` and `iotop`
4. **Consider using an SSD** instead of SD card for better performance

## 🛠️ Troubleshooting

### Backend Issues
```bash
# Check application logs
journalctl -u yelp-api.service -f

# Test database connection
psql -h 192.168.0.9 -p 5433 -U steven -d steven
```

### Frontend Issues
```bash
# Check if Node.js is installed
node --version

# Rebuild if needed
cd /home/steven/fastapi-yelp-postgres/frontend
rm -rf node_modules package-lock.json
npm install
npm run build
```

## 🎉 Success!

Your Yelp application is now deployed on your Raspberry Pi:
- **Cost**: $0/month (vs $15-45/month on AWS)
- **Performance**: Great for local/home network use
- **Control**: Full control over your data and deployment
- **Learning**: Perfect for development and learning

Enjoy your self-hosted Yelp data API! 🚀
