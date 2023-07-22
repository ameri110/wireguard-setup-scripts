#!/bin/bash


# Create and bind a new peer (client) to the setup WireGuard interface.

# Copyright (c) 2020 Hamidreza Hosseinkhani (xei) under the terms of the MIT license.
# https://github.com/xei/wireguard-setup-scripts
# Some parts of this script are inspired from https://github.com/angristan/wireguard-install

function ip2num() {
	IP=$1
	IPa=${IP%%.*}
	IP=${IP#*.*}
	IPb=${IP%%.*}
	IP=${IP#*.*}
	IPc=${IP%%.*}
	IP=${IP#*.*}
	IPd=${IP%%.*}
	IPn=$((IPa*256**3+IPb*256**2+IPc*256+IPd))
	echo $IPn
}

function num2ip() {
	IPn=$1
	IPa=$((IPn/256**3))
	IPb=$((IPn%256**3/256**2))
	IPc=$((IPn%256**2/256))
	IPd=$((IPn%256))
	echo $IPa.$IPb.$IPc.$IPd
}

function add_colon() {
    local input=$1
    local length=${#input}

    if (( length > 4 )); then
        # Extract the last four characters and the rest of the string
        last_four="${input: -4}"
        rest="${input:0:length-4}"
        
        # Concatenate the modified string with a colon and print it
        modified_string="$rest:$last_four"
        echo "$modified_string"
    else
        # If the string is not longer than four characters, print it as it is
        echo "$input"
    fi
}

function set_peer_name() {
	if [ $# -eq 0 ]
	then
		echo "Please pass a name for new peer as an argument."
		echo "For example:"
		echo "sudo ./create-new-peer.sh client2"
		exit 1
	else
		PEER_NAME=$1
	fi
}

function check_root_priviledge() {
	if [ "${EUID}" -ne 0  ]; then
		echo "Permission denied: Please run the script as root!"
		exit 1
	fi
}

function check_if_wireguard_is_setup() {
        if [[ ! -e /etc/wireguard/params ]]; then
                echo "WireGuard is not setup on the machine as a VPN server!."
		echo "Please run \"sudo ./setup-wireguard-server.sh\" at first."
                exit 1
        fi
}

function retrieve_peer_id() {
	if [[ -e /etc/wireguard/last-peer-id ]]; then
                source /etc/wireguard/last-peer-id
                ((PEER_ID=PEER_ID+1))
        else
                PEER_ID=2 # 2-254 , 1 is reserved for the server
        fi
}

function retrieve_wireguard_params() {
	source /etc/wireguard/params

 	PEER_ID_HEX=$( printf "%x" $PEER_ID )
  	PEER_ID_HEX_COLON=$(add_colon $PEER_ID_HEX)

	SUBNET_V4="${SERVER_PRIVATE_IPV4::-1}"
        SUBNET_V6="${SERVER_PRIVATE_IPV6::-1}"
	IPV4=$(num2ip $(($(ip2num $SERVER_PRIVATE_IPV4)+PEER_ID)))
        IPV6="${SUBNET_V6}${PEER_ID_HEX_COLON}"

	#DNS=${SERVER_PRIVATE_IPV4}
	DNS="8.8.8.8"
}

function generate_keys() {
        PRIVATE_KEY=$(wg genkey)
        PUBLIC_KEY=$(echo "${PRIVATE_KEY}" | wg pubkey)
        PRESHARED_KEY=$(wg genpsk)
}

function create_config_file() {
	mkdir -p /etc/wireguard/peers/${PEER_ID}-${PEER_NAME}

	echo "[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${IPV4}/32, ${IPV6}/64
DNS = ${DNS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${PRESHARED_KEY}
Endpoint = ${SERVER_PUBLIC_IPV4}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0" > "/etc/wireguard/peers/${PEER_ID}-${PEER_NAME}/${PEER_NAME}.conf"

	cat /etc/wireguard/peers/${PEER_ID}-${PEER_NAME}/${PEER_NAME}.conf | qrencode -o /etc/wireguard/peers/${PEER_ID}-${PEER_NAME}/${PEER_NAME}.png
}

function bind_peer_to_server() {
	echo "
### Peer Name: ${PEER_NAME}
### Peer ID: ${PEER_ID}
[Peer]
PublicKey = ${PUBLIC_KEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${IPV4}/32, ${IPV6}/64" >> "/etc/wireguard/${NIC_WG}.conf"

	systemctl restart wg-quick@${NIC_WG}
	wg show ${NIC_WG}
}

function update_last_peer_id_file() {
	echo "PEER_ID=${PEER_ID}" > "/etc/wireguard/last-peer-id"
}

function print_config_as_qr_code() {
        qrencode -t ansiutf8 <"/etc/wireguard/peers/${PEER_ID}-${PEER_NAME}/${PEER_NAME}.conf"
}


function main() {
	set_peer_name $1
	check_root_priviledge
	check_if_wireguard_is_setup
	retrieve_peer_id
	retrieve_wireguard_params
	generate_keys
	create_config_file
	bind_peer_to_server
	update_last_peer_id_file

	echo "Peer \"${PEER_NAME}\" with ID: \"${PEER_ID}\" is bound to \"${NIC_WG}\" WireGuard interface successfully."
	echo "You can find the peer configuration file in \"/etc/wireguard/peers/${PEER_ID}-${PEER_NAME}/\""	
	echo "You can also scan the following QR code by WireGuard mobile application to establish a VPN tunnel easily."
	echo ""
	print_config_as_qr_code
}


main $1
