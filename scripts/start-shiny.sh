#!/bin/bash
# Startup script for MD-ALL Shiny Server
# Handles initialization, logging, and graceful shutdown

set -e

echo "=========================================="
echo "MD-ALL Web Application Starting..."
echo "=========================================="

# Set timezone
export TZ=${TZ:-America/Los_Angeles}
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create necessary directories
mkdir -p /data/uploads /data/outputs /data/temp /logs

# Set permissions
chown -R shiny:shiny /data /logs
chmod 1777 /data/temp

# Initialize logging
LOG_FILE="/logs/startup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"

# Check R installation
echo "=========================================="
echo "Checking R installation..."
echo "=========================================="
R --version | head -n 1

# Check required R packages
echo "=========================================="
echo "Checking R packages..."
echo "=========================================="
R --quiet --no-save <<EOF
packages <- c("shiny", "shinydashboard", "MDALL", "dplyr", "ggplot2")
installed <- installed.packages()[,"Package"]
missing <- packages[!packages %in% installed]
if (length(missing) > 0) {
  cat("ERROR: Missing packages:", paste(missing, collapse=", "), "\n")
  quit(status = 1)
} else {
  cat("All required packages are installed.\n")
}
EOF

# Check data directories
echo "=========================================="
echo "Checking directories..."
echo "=========================================="
ls -la /data/
ls -la /logs/

# Check environment variables
echo "=========================================="
echo "Environment Configuration:"
echo "=========================================="
echo "AUTH_ENABLED: ${AUTH_ENABLED:-false}"
echo "LOG_LEVEL: ${LOG_LEVEL:-INFO}"
echo "MAX_WORKERS: ${MAX_WORKERS:-4}"
echo "UPLOAD_MAX_SIZE_MB: ${UPLOAD_MAX_SIZE_MB:-500}"

# Health check endpoint
echo "=========================================="
echo "Creating health check endpoint..."
echo "=========================================="
mkdir -p /srv/shiny-server/health
cat > /srv/shiny-server/health/app.R <<'HEALTHCHECK'
library(shiny)
ui <- fluidPage("OK")
server <- function(input, output, session) {}
shinyApp(ui, server)
HEALTHCHECK
chown -R shiny:shiny /srv/shiny-server/health

# Graceful shutdown handler
shutdown_handler() {
    echo "=========================================="
    echo "Received shutdown signal..."
    echo "=========================================="
    echo "Cleaning up temporary files..."
    find /data/temp -type f -mtime +1 -delete
    echo "Stopping Shiny Server..."
    pkill -TERM shiny-server
    wait
    echo "Shutdown complete."
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# Start Shiny Server
echo "=========================================="
echo "Starting Shiny Server..."
echo "=========================================="
echo "Access the application at:"
echo "  http://localhost:3838"
echo "=========================================="

# Run as shiny user
exec su -s /bin/bash -c "/usr/bin/shiny-server" shiny &

# Keep the script running
wait $!
