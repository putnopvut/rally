#!/bin/bash

OVS_REPO=$1
OVS_BRANCH=$2
OVS_USER=$3


echo "OVS_REPO: $OVS_REPO"
echo "OVS_BRANCH: $OVS_BRANCH"
echo "OVS_USER: $OVS_USER"

function is_ovs_installed {
    local installed=0
    if command -v ovs-vswitchd; then
        echo "ovs already installed"
        return 0
    fi

    return 1
}


function install_ovs {
    cd /home/$OVS_USER
    echo "PWD: $PWD"
    if [ -d ovs ] ; then
        cd ovs
        echo "git pull"
        git pull
    else
        echo "git clone -b $OVS_BRANCH $OVS_REPO"
        git clone -b $OVS_BRANCH $OVS_REPO
        cd ovs
    fi

    sudo apt-get install -y --force-yes gcc make automake autoconf \
                      libtool libcap-ng0 libssl1.0.0
    ./boot.sh
    mkdir build
    cd build
    ../configure --with-linux=/lib/modules/`uname -r`/build
    make -j 2
    sudo make install
    sudo make INSTALL_MOD_DIR=kernel/net/openvswitch modules_install

    sudo modprobe -r vport_geneve
    sudo modprobe -r openvswitch
    sudo modprobe openvswitch
    sudo modprobe vport-geneve

    dmesg | tail
    modinfo /lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko

    sudo chown $OVS_USER /usr/local/var/run/openvswitch
    sudo chown $OVS_USER /usr/local/var/log/openvswitch
}



if ! is_ovs_installed; then
    echo "Install ovs"
    install_ovs
fi

touch /tmp/ovs_install
echo "Install ovs done"
