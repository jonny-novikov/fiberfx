#!/bin/bash
# =============================================================================
# FiberFx Gateway - Local Development Database Proxy
# =============================================================================
#
# This script starts a Fly.io proxy to access codemoji-db from local development
#
# Prerequisites:
#   - flyctl installed and authenticated
#   - Access to codemoji-db Fly.io app
#
# Usage:
#   ./scripts/dev-proxy.sh        # Start proxy in background
#   ./scripts/dev-proxy.sh stop   # Stop proxy
#   ./scripts/dev-proxy.sh status # Check if proxy is running
#
# =============================================================================

set -e

PROXY_PORT=54321
FLY_APP="codemoji-db"
PID_FILE="/tmp/codemoji-db-proxy.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

start_proxy() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${YELLOW}Proxy already running on port $PROXY_PORT${NC}"
        exit 0
    fi

    echo -e "${GREEN}Starting database proxy...${NC}"
    echo "  Local port: $PROXY_PORT"
    echo "  Remote: codemoji-db.internal:5432"

    # Start proxy in background
    fly proxy $PROXY_PORT:5432 -a $FLY_APP &
    PROXY_PID=$!
    echo $PROXY_PID > "$PID_FILE"

    sleep 2

    if kill -0 $PROXY_PID 2>/dev/null; then
        echo -e "${GREEN}Proxy started successfully (PID: $PROXY_PID)${NC}"
        echo ""
        echo "Connection string for local development:"
        echo -e "${YELLOW}postgres://fireheadz_studio:9El4M7mB5Bkxqv5@localhost:$PROXY_PORT/codemoji_game${NC}"
        echo ""
        echo "Update your .env.local DATABASE_URL to use localhost:$PROXY_PORT"
    else
        echo -e "${RED}Failed to start proxy${NC}"
        rm -f "$PID_FILE"
        exit 1
    fi
}

stop_proxy() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo -e "${YELLOW}Stopping proxy (PID: $PID)...${NC}"
            kill $PID
            rm -f "$PID_FILE"
            echo -e "${GREEN}Proxy stopped${NC}"
        else
            echo "Proxy not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "No proxy running"
    fi
}

status_proxy() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}Proxy running (PID: $PID) on port $PROXY_PORT${NC}"
    else
        echo -e "${YELLOW}Proxy not running${NC}"
    fi
}

case "${1:-start}" in
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    status)
        status_proxy
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
