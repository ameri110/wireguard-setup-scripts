# Setup WireGuard VPN like a piece of cake 🍰
Here you can find some useful shell scripts in order to setup WireGuard VPN server on a Linux server as easily as possible.

<p>&nbsp;</p>

## WireGuard
There are a bunch of tunneling protocols in order to make a VPN. For example ~~[PPTP](https://www.bgocloud.com/knowledgebase/32/mikrotik-chr-how-to-setup-pptp-vpn-server.html)~~, ~~[L2TP](https://blog.johannfenech.com/mikrotik-l2tp-ipsec-vpn-server/)~~, [IKEv2/IPSec](https://github.com/jawj/IKEv2-setup), [OpenVPN](https://github.com/angristan/openvpn-install) and of course [WireGuard](https://www.wireguard.com/).

Among these all, WireGuard seems to be the most interesting. It is lite (about 4,000 lines of code), fast and secure. So in 2020, WireGuard was officially added to the Linux kernel 5.6 release (so also Android kernels) by Linus Torvalds.

## Setup the server
Here you can follow the instructions step by step to setup a VPN server using WireGuard.

The scripts are tested on Ubuntu 20.04 but you can run them on Debian, Fedora, CentOS and Arch Linux.


You can buy a cheap Linux IaaS from these cloud providers for the VPN server:
Cloud Provider | Location | Price (starting at) | Traffic |
|--|--|--|--|
Vultr | Worldwide (USA is recommended because of sanctions!) | $3.50/month | - |
Digital Ocean | Worldwide (USA is recommended because of sanctions!) | $5/month | -
Hetzner | Germany (Finland did not work as VPN server for me!) | €3/month | 20 TB |

### Clone the repository
Run the following commands to download the scripts:
```
wget -O - https://github.com/xei/wireguard-setup-scripts/archive/master.tar.gz | tar xz
cd wireguard-setup-scripts-master
```

### Setup WireGuard server
Run the following command to setup the WireGuard server:
```
sudo ./setup-wireguard-server.sh
```
You have to answer some questions in order to configure the server. However you can leave the default values.
```
Enter a private IPv4 for WireGuard server: 10.0.0.1
Enter a private IPv6 for WireGuard server: fd42:42:42::1
Enter a port [1-65535] for WireGuard to listen: 51820
Enter a name for WireGuard network interface: wg0
```

When you see the message `WireGuard is setup successfully.` you can go on.

### Create a new peer (client)
Run the following command to create a new client (here named `xei-pc`):
```
sudo ./create-new-peer.sh xei-mobile
```
This command will generate a QR code that can be scanned by Wireguard client mobile application. It also generate a config file in `/etc/wireguard/peers/xei-mobile/` directory that can be used instead of the QR code.

Note that you can not connect to the VPN as one client with more than one devices at the same time. You have to create different clients for different devices. for example `xei-pc` and `xei-mobile`.

> You have to modify the client's config file and change `DNS` section to something like `1.1.1.1` or `8.8.8.8`.

### Revoke a peer (client)
You can remove a client by running the following command:
```
sudo ./revoke-peer.sh xei-mobile
```
`xei-mobile` is the name of the client you want to remove.

### Remove WireGuard server
You can remove the WireGuard server completely by running the following command:
```
sudo ./remove-wireguard-server.sh
```
Note that the above script will remove the directory `/etc/wireguard` and its contents including all peers' config files. Backup the direcory if it is necessary.

### WireGuard client applications
When you create a new peer (client) with the above command, a config file will be generated in `/etc/wireguard/peers/client-name/` directory that should be imported to WireGuard client application.

WireGuard client application is available in almost all platforms:

[Download WireGuard client application for Windows](https://download.wireguard.com/windows-client/wireguard-amd64-0.1.1.msi)

[Download WireGuard client application for macOS](https://itunes.apple.com/us/app/wireguard/id1451685025?ls=1&mt=12)

[Download WireGuard client application for Linux](https://www.wireguard.com/install)

[Download WireGuard client application for Android](https://play.google.com/store/apps/details?id=com.wireguard.android)

[Download WireGuard client application for iOS](https://itunes.apple.com/us/app/wireguard/id1441195209?ls=1&mt=8)
