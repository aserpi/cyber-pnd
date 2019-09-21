#!/bin/zsh

COFFEE="pnd-fantasticcoffee"
DC="pnd-dc"
INTFW="pnd-intfw"
MAINFW="pnd-mainfw"
PROXY="pnd-proxy"


for arg in "$@"; do
    if [[ $arg = "coffee" ]]; then
        COFFEE_START=true
    elif [[ $arg = "dc" ]]; then
        DC_START=true
    elif [[ $arg = "proxy" ]]; then
        DC_START=true
        PROXY_START=true
    fi
done


[[ `sudo docker network ls | grep -E "\snetkit_0_DMZ\s"` =~ "^\w*" ]] && DMZ="br-$MATCH"
VBoxManage modifyvm $MAINFW --bridgeadapter2 "$DMZ"
VBoxManage modifyvm $PROXY --bridgeadapter1 "$DMZ"
echo -e "DMZ:\t\t$DMZ"

if ! [[ `sudo ip link show br-firewalls 2> /dev/null` ]]; then
    sudo brctl addbr br-firewalls
    sudo ip link set br-firewalls up
fi
VBoxManage modifyvm $INTFW --bridgeadapter1 "br-firewalls"
VBoxManage modifyvm $MAINFW --bridgeadapter3 "br-firewalls"
echo -e "Firewalls:\tbr-firewalls"

[[ `sudo docker network ls | grep -E "\snetkit_0_server\s"` =~ "^\w*" ]] && SERVER="br-$MATCH"
VBoxManage modifyvm $INTFW --bridgeadapter2 "$SERVER"
VBoxManage modifyvm $DC --bridgeadapter1 "$SERVER"
echo -e "Server:\t\t$SERVER"

[[ `sudo docker network ls | grep -E "\snetkit_0_client\s"` =~ "^\w*" ]] && CLIENT="br-$MATCH"
sudo ip route del 100.64.0.0/16 &> /dev/null
sudo ip address flush dev $CLIENT
sudo ip address add 100.64.2.5/24 dev $CLIENT
sudo ip route add 100.64.0.0/16 via 100.64.2.1
VBoxManage modifyvm $INTFW --bridgeadapter3 $CLIENT
echo -e "Client:\t\t$CLIENT"

if ! [[ `sudo ip link show br-external 2> /dev/null` ]]; then
    sudo brctl addbr br-external
    sudo ip link set br-external up
fi
VBoxManage modifyvm $COFFEE --bridgeadapter1 "br-external"
VBoxManage modifyvm $MAINFW --bridgeadapter4 "br-external"
echo -e "External:\tbr-external"

VBoxManage startvm "$INTFW"
VBoxManage startvm "$MAINFW"
if (( ${+DC_START} )); then VBoxManage startvm "$DC"; fi
if (( ${+PROXY_START} )); then VBoxManage startvm "$PROXY"; fi
if (( ${+COFFEE_START} )); then
    vared -p "Press Enter when mainfw has finished starting..." -c ignored
    VBoxManage startvm "$COFFEE"
fi

