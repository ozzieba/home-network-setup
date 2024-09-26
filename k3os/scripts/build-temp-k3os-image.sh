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
git clone "$K3OS_REPO" k3os-build-temp
cd k3os-build-temp

# Checkout the latest stable release
git checkout v0.20.14-k3s1r0

# Create temporary config.yaml
cat << EOCONFIG > packer/conf/config.yaml
ssh_authorized_keys:
  - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEkZOa1sRkc3/9/k3kgcN5LToGqlutZ5h/VyMxAfWG+O oz@oz-ThinkPad-P16v-Gen-1"
hostname: "sbc-temporary"
k3os:
  password: "IPfDjVETF5bgo1e4"
runcmd:
  - "ip addr add 192.168.68.200/18 dev eth0"
  - "ip link set eth0 up"
EOCONFIG

# Build k3OS for ARM64 with temporary configurations
PACKER_CONF="packer/conf" make PACKAGER_OPTS="--platform=arm64"

# Move the built image to the images directory
mv dist/artifacts/k3os-arm64.iso "../$IMAGE_DIR/k3os-arm64-temp.iso"

echo "Temporary k3OS ARM64 image built successfully at $IMAGE_DIR/k3os-arm64-temp.iso."

