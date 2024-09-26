#!/bin/bash

echo "Welcome to the Home Network Setup Deployment Script."
echo "This script will guide you through the deployment process step by step."
echo

# Function to pause and wait for user input
function pause() {
   read -p "$*"
}

# Function to display generated password
function display_password() {
   echo "A secure password has been generated for the VMs and services:"
   echo "Password: $PASSWORD"
   echo "Please keep this password in a secure place."
   echo
}

# Step 1: Prepare the Temporary MicroSD Card
echo "Step 1: Prepare the Temporary MicroSD Card"
echo "Building the temporary k3OS ARM64 image..."
echo

# Build the temporary k3OS image
chmod +x k3os/scripts/build-temp-k3os-image.sh
k3os/scripts/build-temp-k3os-image.sh

echo
echo "The temporary k3OS ARM64 image has been built successfully."
echo "You can find the image at k3os/images/k3os-arm64-temp.iso"
echo

pause "Press [Enter] to flash the temporary image onto the MicroSD card..."

echo
echo "Flashing the temporary image onto the MicroSD card..."
echo "Please ensure your MicroSD card is inserted and identified (e.g., /dev/sdX)."
echo "WARNING: This will erase all data on the MicroSD card."
echo

read -p "Enter the device identifier for your MicroSD card (e.g., /dev/sdX): " sdcard_device
sudo dd if=k3os/images/k3os-arm64-temp.iso of=$sdcard_device bs=4M status=progress conv=fsync

echo
echo "The temporary image has been flashed to the MicroSD card."
echo

# Discover Laptop Ethernet Interface Name
echo "Discovering your laptop's Ethernet interface name..."
echo "Please ensure that only the USB-C Ethernet adapter is connected."
echo

available_interfaces=$(ip -o link show | awk -F': ' '{print $2}')
echo "Available network interfaces:"
echo "$available_interfaces"
echo

read -p "Enter the name of your USB-C Ethernet interface: " laptop_eth_interface

# Assign static IPs
echo "Assigning static IPs to your laptop and the SBC..."

sudo ifconfig $laptop_eth_interface $LAPTOP_IP netmask $NETMASK up
echo "Your laptop's Ethernet interface ($laptop_eth_interface) has been set to IP: $LAPTOP_IP"

pause "Insert the MicroSD card into the SBC and connect it to your laptop via Ethernet. Press [Enter] when ready."

echo
echo "Waiting for the SBC to boot up (this may take a couple of minutes)..."
sleep 120

echo "The SBC should now be reachable at $TEMP_SBC_IP."
echo

# Step 2: Access the SBC and Discover PCIe Device Name
echo "Attempting to SSH into the SBC to discover the PCIe device name..."
ssh-keyscan -H $TEMP_SBC_IP >> ~/.ssh/known_hosts
ssh rancher@$TEMP_SBC_IP "echo 'Successfully connected to SBC.'"

if [ $? -ne 0 ]; then
    echo "SSH connection failed. Please check the connection and try again."
    exit 1
fi

echo "SSH connection established."
echo

echo "Discovering PCIe device name on the SBC..."
PCI_DEVICE=$(ssh rancher@$TEMP_SBC_IP "lspci | grep Ethernet | awk '{print \$1}'")
echo "PCIe Ethernet device found: $PCI_DEVICE"

if [ -z "$PCI_DEVICE" ]; then
    echo "Failed to discover PCIe device name. Exiting."
    exit 1
fi

echo "Updating configuration files with the PCIe device name..."

# Update the openbsd-vm.yaml with the correct PCIe device selector
sed -i "s/deviceSelector: .*/deviceSelector: \"$PCI_DEVICE\"/" k3os/manifests/openbsd-vm.yaml

# Step 3: Build the Final MicroSD Card
echo
echo "Building the final k3OS ARM64 image with updated configurations..."
chmod +x k3os/scripts/build-k3os-image.sh
k3os/scripts/build-k3os-image.sh

echo
echo "The final k3OS ARM64 image has been built successfully."
echo "You can find the image at k3os/images/k3os-arm64.iso"
echo

pause "Press [Enter] to flash the final image onto the MicroSD card..."

echo
echo "Flashing the final image onto the MicroSD card..."
sudo dd if=k3os/images/k3os-arm64.iso of=$sdcard_device bs=4M status=progress conv=fsync

echo
echo "The final image has been flashed to the MicroSD card."
echo

pause "Insert the MicroSD card back into the SBC and power it on. Press [Enter] when ready."

echo
echo "Waiting for the SBC to boot up with the final image (this may take a couple of minutes)..."
sleep 120

# Step 4: Configure Network Devices
echo
echo "Step 4: Configure Network Devices"
echo "Please follow the instructions to set up the switch and reconfigure physical connections."
echo

echo "1. **Physical Connections**"
echo "   - Disconnect the direct Ethernet connection between the laptop and the SBC."
echo "   - Connect the SBC to the switch on port 1."
echo "   - Connect your laptop to the switch on port 2."
echo "   - Connect the modem to the switch on port 24."
echo "   - Ensure the Deco units are connected to the main Ethernet network as per your plan."
echo

pause "Press [Enter] after making the physical connections."

echo
echo "2. **Configure Static IP on Laptop for Management Network**"
echo "Assigning static IP to your laptop's Ethernet interface for the management network..."
sudo ifconfig $laptop_eth_interface 192.168.0.2 netmask 255.255.255.0 up

echo
echo "Your laptop's Ethernet interface ($laptop_eth_interface) has been set to IP: 192.168.0.2"
echo

echo "3. **Access the Switch's Web Interface**"
echo "   - Open a web browser and navigate to http://192.168.0.1"
echo "   - Log in using the default credentials (refer to the switch's manual)."
echo

echo "4. **Configure VLANs on the Switch**"
echo "   - VLAN 10: Modem and SBC router (Ports 1 and 24)"
echo "   - VLAN 20: Main Ethernet network (Ports 3-10)"
echo "   - VLAN 30: IoT network connected only to the SBC (Ports 11-18)"
echo "   - VLAN 40: Deco network connected to the main Ethernet network (Ports 19-22)"
echo "   - VLAN 50: Management network (SBC router, switch itself, and management port for laptop) (Ports 1, 2)"
echo

echo "5. **Assign Ports to VLANs**"
echo "   - Configure port memberships according to the above VLAN assignments."
echo "   - Set port 1 (SBC) as a trunk port for VLANs 10, 30, and 50."
echo "   - Set port 2 (laptop) as an access port for VLAN 50."
echo

pause "Press [Enter] after configuring the switch."

# Step 5: Final Steps
echo
echo "Deployment is complete!"
echo
echo "You can access the OpenBSD VM via SSH at 192.168.1.1 using the generated password."
echo "You can access Home Assistant at http://192.168.1.3:8123"
echo

# Troubleshooting Section
echo "If you encounter any issues during the deployment, consider the following troubleshooting tips:"
echo "- Ensure the MicroSD card is properly flashed and inserted."
echo "- Verify that the SBC is powered on and connected to the switch."
echo "- Check the status of the Kubernetes cluster by SSHing into the SBC and running 'kubectl get nodes'."
echo "- Review the logs of the VMs using 'kubectl logs <pod-name>' on the SBC."
echo "- Ensure that the VLANs are correctly configured on the switch."
echo "- Confirm that the physical connections match the instructions."
echo
echo "For further assistance, consult the documentation or reach out to the community."
echo

