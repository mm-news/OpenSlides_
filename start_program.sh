#!/bin/bash

set -e

echo "================================================"
echo "OpenSlides Setup and Start Script"
echo "================================================"
echo ""

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose is not installed. Please install Docker Compose (v2) first."
    exit 1
fi

echo "✓ Docker and Docker Compose are installed and running"
echo ""

# Step 1: Download OpenSlides manage tool if not present
echo "Step 1: Checking for OpenSlides manage tool..."
if [[ ! -f ./openslides ]]; then
    echo "  Downloading OpenSlides manage tool..."
    wget -q --show-progress https://github.com/OpenSlides/openslides-manage-service/releases/download/latest/openslides
    echo "  ✓ Downloaded"
else
    echo "  ✓ OpenSlides manage tool already exists"
fi

# Make it executable
if [[ ! -x ./openslides ]]; then
    chmod +x ./openslides
    echo "  ✓ Made executable"
fi
echo ""

# Step 2: Setup the instance
echo "Step 2: Setting up OpenSlides instance..."
if [[ ! -f ./docker-compose.yml ]]; then
    echo "  Running setup command..."
    ./openslides setup .
    echo "  ✓ Setup complete"
else
    echo "  ✓ docker-compose.yml already exists"
    echo "  (To reset the setup, remove docker-compose.yml and run this script again)"
fi
echo ""

# Step 3: Pull Docker images
echo "Step 3: Pulling Docker images..."
echo "  This may take several minutes on first run..."
docker compose pull
echo "  ✓ Images pulled"
echo ""

# Step 4: Start services
echo "Step 4: Starting Docker services..."
docker compose up --detach
echo "  ✓ Services started"
echo ""

# Step 5: Wait for services to be ready
echo "Step 5: Waiting for services to be ready..."
echo "  This may take a minute or two..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if ./openslides check-server 2>&1 | grep -q "Server is running"; then
        echo "  ✓ Server is ready"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "  ⚠ Server readiness check timed out, but continuing anyway..."
        echo "  You can manually check with: ./openslides check-server"
        break
    fi
    sleep 2
done
echo ""

# Step 6: Initialize data
echo "Step 6: Initializing data and creating superadmin account..."
if ./openslides initial-data 2>&1 | grep -q "Initial data created successfully\|Superadmin already exists"; then
    echo "  ✓ Initial data created"
else
    echo "  ⚠ Initial data creation may have failed, but continuing..."
    echo "  You can manually initialize with: ./openslides initial-data"
fi
echo ""

# Display success message
echo "================================================"
echo "✓ OpenSlides is now running!"
echo "================================================"
echo ""
echo "Access OpenSlides at: https://localhost:8000"
echo ""
echo "Default credentials:"
echo "  Username: superadmin"
echo "  Password: superadmin"
echo ""
echo "Note: You will see a browser warning about the self-signed"
echo "      SSL certificate. This is expected for local development."
echo ""
echo "Useful commands:"
echo "  - Stop services:    docker compose stop"
echo "  - View logs:        docker compose logs -f"
echo "  - Restart services: docker compose restart"
echo "  - Remove all:       docker compose down --volumes"
echo ""
echo "For more information, see INSTALL.md"
echo "================================================"
