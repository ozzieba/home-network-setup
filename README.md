# Home Network Setup

This repository contains the configuration and scripts to set up your home network using k3OS on a Pine64 QuartzPro64 SBC. The setup includes:

- **k3OS** as the base operating system
- **KubeVirt** with PCIe passthrough for virtualization
- **OpenBSD VM** with PF and routing configurations
- **Home Assistant VM** for smart home management
- **Declarative configurations** for infrastructure management
- **SSH access** using your public key

## Prerequisites

- Pine64 QuartzPro64 SBC
- MicroSD card (for bootloader and initial setup)
- SSD for storage
- Managed Switch (DGS-1248)
- Deco S4 units
- Additional WiFi routers/APs
- Ethernet cables, power supplies
- Computer (laptop) with Git and GitHub CLI (`gh`) installed
- `pwgen`, `jq` installed
- Ensure your SSH public key is available at `~/.ssh/id_ed25519.pub`

## Setup Instructions

1. **Prepare the MicroSD Card**

   - Build the temporary k3OS ARM64 image using the provided script.
   - Flash the image onto the MicroSD card.

2. **Initial Physical Connections**

   - Connect the SBC directly to your laptop via Ethernet.
   - Assign static IPs to both the laptop and the SBC.

3. **Boot the SBC and Discover PCIe Device Name**

   - Insert the MicroSD card into the SBC.
   - Power on the SBC to boot into k3OS.
   - SSH into the SBC and obtain the PCIe device name.

4. **Build the Final k3OS Image**

   - Update the configuration files with the discovered PCIe device name.
   - Build the final k3OS image using the provided script.
   - Flash the new image onto the MicroSD card.

5. **Configure Network Devices**

   - Set up the managed switch with VLANs.
   - Reconfigure physical connections as instructed.

6. **Final Steps**

   - Follow the prompts in `deploy.sh` to complete the setup.

For detailed deployment instructions, run the `deploy.sh` script.

## Wiring Diagram

Refer to the `docs/network-diagram.png` file for the network topology.

## Troubleshooting

If you encounter any issues, refer to the troubleshooting section provided by the `deploy.sh` script.

