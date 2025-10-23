#!/bin/bash

# 🍓 Complete Raspberry Pi Deployment Script
echo "🍓 Starting Yelp Data API on Raspberry Pi..."

# Configuration
BACKEND_HOST="192.168.0.9"
BACKEND_PORT="8000"
FRONTEND_PORT="3000"
PROJECT_DIR="/home/steven/fastapi-yelp-postgres"

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to stop existing services
stop_services() {
    echo "🛑 Stopping existing services..."
    
    # Stop backend
    if check_port $BACKEND_PORT; then
        echo "   Stopping backend on port $BACKEND_PORT..."
        pkill -f "uvicorn.*src.main:app" || true
        sleep 2
    fi
    
    # Stop frontend
    if check_port $FRONTEND_PORT; then
        echo "   Stopping frontend on port $FRONTEND_PORT..."
        pkill -f "python.*http.server.*$FRONTEND_PORT" || true
        pkill -f "serve.*build" || true
        sleep 2
    fi
}

# Function to start backend
start_backend() {
    echo "🚀 Starting FastAPI backend..."
    cd "$PROJECT_DIR"
    
    # Load environment variables
    if [ -f .env ]; then
        export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
        echo "   ✅ Environment variables loaded"
    else
        echo "   ⚠️  .env file not found!"
    fi
    
    # Start backend in background
    nohup ./.venv/bin/uvicorn src.main:app --host $BACKEND_HOST --port $BACKEND_PORT --reload > backend.log 2>&1 &
    BACKEND_PID=$!
    
    # Wait a moment and check if it started
    sleep 3
    if check_port $BACKEND_PORT; then
        echo "   ✅ Backend started successfully (PID: $BACKEND_PID)"
        echo "   📱 API available at: http://$BACKEND_HOST:$BACKEND_PORT"
        echo "   📚 Documentation at: http://$BACKEND_HOST:$BACKEND_PORT/docs"
    else
        echo "   ❌ Backend failed to start. Check backend.log for errors."
        return 1
    fi
}

# Function to start frontend
start_frontend() {
    echo "🌐 Starting React frontend..."
    cd "$PROJECT_DIR/frontend"
    
    # Build if needed
    if [ ! -d "build" ] || [ "src" -nt "build" ]; then
        echo "   📦 Building frontend..."
        snap run node.npm run build
    fi
    
    # Start frontend
    cd build
    nohup python3 -m http.server $FRONTEND_PORT --bind $BACKEND_HOST > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    
    # Wait a moment and check if it started
    sleep 2
    if check_port $FRONTEND_PORT; then
        echo "   ✅ Frontend started successfully (PID: $FRONTEND_PID)"
        echo "   🌐 Frontend available at: http://$BACKEND_HOST:$FRONTEND_PORT"
    else
        echo "   ❌ Frontend failed to start. Check frontend.log for errors."
        return 1
    fi
}

# Function to test services
test_services() {
    echo "🧪 Testing services..."
    
    # Test backend API
    if curl -s "http://$BACKEND_HOST:$BACKEND_PORT/health" > /dev/null; then
        echo "   ✅ Backend API is responding"
    else
        echo "   ❌ Backend API is not responding"
    fi
    
    # Test frontend
    if curl -s "http://$BACKEND_HOST:$FRONTEND_PORT" > /dev/null; then
        echo "   ✅ Frontend is serving files"
    else
        echo "   ❌ Frontend is not accessible"
    fi
}

# Function to show status
show_status() {
    echo ""
    echo "📊 Service Status:"
    echo "=================="
    echo "🔧 Backend:  http://$BACKEND_HOST:$BACKEND_PORT"
    echo "🌐 Frontend: http://$BACKEND_HOST:$FRONTEND_PORT"
    echo "📚 API Docs: http://$BACKEND_HOST:$BACKEND_PORT/docs"
    echo ""
    echo "📁 Log files:"
    echo "   Backend:  $PROJECT_DIR/backend.log"
    echo "   Frontend: $PROJECT_DIR/frontend/frontend.log"
    echo ""
    echo "🛑 To stop services: pkill -f uvicorn && pkill -f 'python.*http.server'"
    echo ""
}

# Main execution
case "${1:-start}" in
    "start")
        stop_services
        start_backend && start_frontend
        test_services
        show_status
        echo "🎉 Deployment complete! Your Yelp app is running!"
        ;;
    "stop")
        stop_services
        echo "🛑 Services stopped."
        ;;
    "restart")
        stop_services
        sleep 2
        start_backend && start_frontend
        test_services
        show_status
        ;;
    "status")
        show_status
        test_services
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo "  start   - Start both backend and frontend services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  status  - Show current status"
        ;;
esac
