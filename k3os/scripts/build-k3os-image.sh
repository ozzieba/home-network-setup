#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
K3OS_REPO="https://github.com/rancher/k3os.git"
IMAGE_DIR="k3os/images"
CONFIG_DIR="../configs"

# Create images directory
mkdir -p "$IMAGE_DIR"

# Clone k3OS repository
git clone "$K3OS_REPO" k3os-build
cd k3os-build

# Checkout the latest stable release
git checkout v0.20.14-k3s1r0

# Copy custom configurations
mkdir -p packer/conf
cp -r "$CONFIG_DIR"/* packer/conf/

# Build k3OS for ARM64 with custom configurations
PACKER_CONF="packer/conf" make PACKAGER_OPTS="--platform=arm64"

# Move the built image to the images directory
mv dist/artifacts/k3os-arm64.iso "../$IMAGE_DIR/"

echo "k3OS ARM64 image built successfully at $IMAGE_DIR/k3os-arm64.iso."

