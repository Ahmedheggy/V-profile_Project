#!/bin/bash
# Create 3 master and 2 worker VMs definitions for kubeadm cluster (powered off)
#**********************************************************************************************************#

# note "SSD_PATH" is used to create the worker nodes on another block drive to reduce consuming of nvme resources.#

#**********************************************************************************************************#
#########  SKIP "SSD_PATH" if u have only one mounted drive
#**********************************************************************************************************#
########   Dont forget to change paths to your current local host path ######
#**********************************************************************************************************#
ISO_PATH="/var/lib/libvirt/images/CentOS-Stream-9-BaseOS-x86_64.iso"
NVME_PATH="/var/lib/libvirt/images"
SSD_PATH="/mnt/ssd/vms"

# Create directories if missing
mkdir -p "$NVME_PATH"
mkdir -p "$SSD_PATH"

# VM settings
RAM_MB=2048
VCPUS=2
DISK_SIZE=20G
OS_VARIANT="centos-stream9"

echo "=== Creating empty disk images ==="
# Master nodes on NVMe
for i in 1 2 3; do
  DISK_PATH="${NVME_PATH}/master${i}.qcow2"
  qemu-img create -f qcow2 "$DISK_PATH" $DISK_SIZE
done

# Worker nodes on SSD
for i in 1 2; do
  DISK_PATH="${SSD_PATH}/worker${i}.qcow2"
  qemu-img create -f qcow2 "$DISK_PATH" $DISK_SIZE
done

echo "=== Defining VMs (powered off) ==="
# Define master VMs
for i in 1 2 3; do
  VM_NAME="master${i}"
  DISK_PATH="${NVME_PATH}/${VM_NAME}.qcow2"
  virt-install \
    --name "$VM_NAME" \
    --ram "$RAM_MB" \
    --vcpus "$VCPUS" \
    --os-variant "$OS_VARIANT" \
    --network network=default \
    --disk path="$DISK_PATH",format=qcow2 \
    --graphics spice \
    --cdrom "$ISO_PATH" \
    --noautoconsole \
    --import
done

# Define worker VMs
for i in 1 2; do
  VM_NAME="worker${i}"
  DISK_PATH="${SSD_PATH}/${VM_NAME}.qcow2"
  virt-install \
    --name "$VM_NAME" \
    --ram "$RAM_MB" \
    --vcpus "$VCPUS" \
    --os-variant "$OS_VARIANT" \
    --network network=default \
    --disk path="$DISK_PATH",format=qcow2 \
    --graphics spice \
    --cdrom "$ISO_PATH" \
    --noautoconsole \
    --import
done

echo "All VM definitions created."
echo "Open Virt-Manager to start each VM one by one and install CentOS manually."

