#!/bin/bash

echo "🧹 Cleaning up Docker resources..."

DOCKER_DIR="$(dirname "$0")/../../docker"

# Stop all containers
echo "⏸️  Stopping containers..."
cd "${DOCKER_DIR}"
docker-compose down

# Remove dangling images
echo "🗑️  Removing dangling images..."
docker image prune -f

# Remove dangling volumes (optional - preserves named volumes)
echo "🗑️  Removing dangling volumes..."
docker volume prune -f

# Clean build cache (optional)
read -p "Clean Docker build cache? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Cleaning build cache..."
    docker builder prune -f
fi

# Remove stopped containers
echo "🗑️  Removing stopped containers..."
docker container prune -f

# Summary
echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Docker disk usage:"
docker system df

echo ""
echo "💡 To remove ALL data including volumes:"
echo "   docker-compose down -v"
echo ""
echo "💡 To free more space:"
echo "   docker system prune -a --volumes"
