#!/bin/bash
# Remote deployment script for MEAN stack on VM
# This script is executed by Jenkins CI/CD pipeline via SSH
# Usage: This script is called automatically by Jenkins; manual use: ./deploy-remote.sh

set -e

# Configuration (override via environment variables if needed)
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-priyadarshankhavtode}"
BACKEND_IMAGE="${DOCKER_HUB_USERNAME}/crud-dd-task-mean-app-backend"
FRONTEND_IMAGE="${DOCKER_HUB_USERNAME}/crud-dd-task-mean-app-frontend"
COMPOSE_PATH="${COMPOSE_PATH:-.}"  # Current directory by default
DOCKER_HUB_PASSWORD="${DOCKER_HUB_PASSWORD:-}"  # Passed by Jenkins

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Main deployment steps
log_info "Starting MEAN stack deployment..."

# Step 1: Verify Docker is running
log_info "Checking Docker daemon..."
if ! docker ps &> /dev/null; then
    log_error "Docker daemon is not running. Please start Docker and try again."
    exit 1
fi
log_info "Docker daemon is running."

# Step 2: Authenticate with Docker Hub
if [ -z "$DOCKER_HUB_PASSWORD" ]; then
    log_warn "DOCKER_HUB_PASSWORD not set. Skipping Docker Hub authentication."
else
    log_info "Authenticating with Docker Hub..."
    echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin > /dev/null 2>&1
    log_info "Docker Hub authentication successful."
fi

# Step 3: Pull latest images
log_info "Pulling latest backend image: ${BACKEND_IMAGE}:latest"
docker pull "${BACKEND_IMAGE}:latest" || log_warn "Failed to pull backend image"

log_info "Pulling latest frontend image: ${FRONTEND_IMAGE}:latest"
docker pull "${FRONTEND_IMAGE}:latest" || log_warn "Failed to pull frontend image"

# Step 4: Navigate to compose directory
log_info "Navigating to Docker Compose directory: ${COMPOSE_PATH}"
cd "$COMPOSE_PATH" || {
    log_error "Failed to navigate to ${COMPOSE_PATH}. Directory does not exist."
    exit 1
}

# Step 5: Pull service images from docker-compose.yml
log_info "Pulling images defined in docker-compose.yml..."
docker compose pull || log_warn "Some images may have failed to pull"

# Step 6: Start/restart services
log_info "Starting Docker Compose services..."
docker compose up -d --remove-orphans

# Step 7: Wait a moment for services to stabilize
log_info "Waiting for services to stabilize..."
sleep 5

# Step 8: Verify services are running
log_info "Service status:"
docker compose ps

# Step 9: Run health check (optional)
log_info "Checking service connectivity..."
if docker compose exec -T mongodb mongosh --version &> /dev/null; then
    log_info "MongoDB is accessible."
else
    log_warn "MongoDB health check failed; services may still be starting."
fi

# Step 10: Clean up Docker Hub authentication
log_info "Logging out from Docker Hub..."
docker logout > /dev/null 2>&1

log_info "✅ Deployment completed successfully!"
log_info "Services are now running. Access the application at:"
log_info "  - Frontend: http://localhost:8081"
log_info "  - Backend API: http://localhost:8080"
log_info "  - MongoDB: localhost:27017"

exit 0
