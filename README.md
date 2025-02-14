Generic_Script_setup_Openvpn_Server_in_Linux_Mint_22.sh

Description

Hello Everyone, This script is designed to set up an OpenVPN server on Linux Mint 22. It is intended for users already familiar with Linux, as it requires manual configuration. You'll need to run this script as root.

This setup allows you to create .ovpn configuration files for client devices such as PCs, smartphones, or tablets, enabling them to securely connect to your local LAN from anywhere in the world.

Requirements

Linux Mint 22 (or compatible Ubuntu-based system)

Root access to execute the script

A static IP address is assigned to the server machine

OpenVPN client software for remote access

Setup Instructions

Download the script:

wget https://github.com/stspringer/Linux-Scripts/raw/main/Generic_Script_setup_Openvpn_Server_in_Linux_Mint_22.sh


Make the script executable:

chmod +x setup.sh

Run the script as root:

sudo ./setup.sh

Edit EasyRSA Variables (Before Running the Script): Open the script and modify the section under # Update EasyRSA vars file to include your country, city, and organization details.

Generate .ovpn Files for Clients: Once the setup is complete, you can generate .ovpn files for any client device that needs to connect to your VPN. This will allow secure remote access to your local LAN.

Download the Script

Click here to view and download the script.

Connecting with OpenVPN on Android

Install OpenVPN for Android from the Google Play Store.

Transfer the generated .ovpn file to your phone.

Open the OpenVPN app and import the .ovpn configuration.

Connect to your OpenVPN server from anywhere!

Use Case Example

I use this VPN setup to securely control my garage door and lights from anywhere, ensuring secure remote access to my home network.

Issues & Contributions

If you encounter any issues, please open an issue here.

Contributions are welcome! Feel free to submit a pull request with improvements.

License

This script is provided under the MIT License, allowing you to freely use, modify, and share it.
