## Prerequisites Before this file

## 5 Virutal Machines with resources minimum (2 cpus core, 2gb ram, 20gb disk space)
## Optional creating 3 VMs (1 master node - 2 workers)
## set hostname for each VM to easy identify each vm For Example: master 1 >>>>> hostnamectl set-hostname master1
# Kubernetes Cluster Setup Guide (CentOS Stream 9)

A simple step-by-step guide to deploy a **Highly Available Kubernetes Cluster** using **kubeadm**, **containerd**, and **Flannel CNI**.

---

##  Node Information (ip differs from host to another)

|     Role      | Hostname|      IP         |
|---------------|---------|-----------------|
| Control Plane | master1 | 192.168.124.140 |
| Control Plane | master2 | 192.168.124.207 |
| Control Plane | master3 | 192.168.124.68  |
|     Worker    | worker1 | 192.168.124.249 |
|     Worker    | worker2 | 192.168.124.123 |

**Add hostname & ip to /etc/hosts to use hostnames instead IPs**
** kindly note that IPs are assigned by the VMM or virtual manager so it will be different **

---## First update the system###

sudo dnf update -y
sudo dnf install -y curl wget vim git net-tools lsof iproute iptables conntrack socat ebtables ethtool


##  Step 1: System Preparation (All Nodes)

### 1.1 Disable SELinux & Swap

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab   ##### this cmd edits the /etc/fstab file and add '#' to the swap line
```

### 1.2 Configure Firewall

#### Option A: Disable Firewall (Lab/Testing)
```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

#### Option B: Open Required Ports
```bash
# Master Nodes
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250-10259/tcp
sudo firewall-cmd --permanent --add-port=30000-32767/tcp

# Worker Nodes
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --permanent --add-port=8472/udp  # Flannel
sudo firewall-cmd --reload
```

### 1.3 Kernel & Network Modules

```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

---

## Step 2: Install Containerd (All Nodes)

### Add Containerd Repository

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io
```

### Configure & Enable Containerd

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Use systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl enable --now containerd             ### enable containerd service to be running automated after booting process
sudo systemctl status containerd
```

---

## Step 3: Install Kubernetes Components (All Nodes)

```bash
export KUBE_VERSION="v1.31"

sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBE_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBE_VERSION/rpm/repodata/repomd.xml.key
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
```

---

## Step 4: Initialize Control Plane (master1 only)

```bash
kubeadm init --control-plane-endpoint="192.168.124.140":6443 --upload-certs --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.124.140    ### replace ip with your master1 node ip
```

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
```

> **Save the join commands displayed in the output!**

---

## Step 5: Join Additional Masters

Use the command from `master1` output:

```bash
sudo kubeadm join 192.168.124.140:6443 --token <token>   --discovery-token-ca-cert-hash sha256:<hash>   --control-plane --certificate-key <cert-key>
```

Repeat kubeconfig setup as above.

---

## Step 6: Join Worker Nodes

Use the **worker join command**:

```bash
sudo kubeadm join 192.168.124.140:6443 --token <token>   --discovery-token-ca-cert-hash sha256:<hash>
```

---

## Step 7: Install Flannel CNI

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl get pods -n kube-flannel -w
```

---

## Step 8: Verification

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl get pods -n kube-flannel
kubectl cluster-info
```

-----------------------------------------
-----------------------------------------

### Troubleshooting ###

### Token Expired
```bash
kubeadm token create --print-join-command
kubeadm init phase upload-certs --upload-certs
```

### Reset Node
```bash
sudo kubeadm reset --force
sudo systemctl restart kubelet
```

### Flannel Issues
```bash
sudo modprobe br_netfilter
kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

---

## Useful Commands

```bash
kubeadm token create --print-join-command
kubectl get componentstatuses
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

---

## Completion Checklist

- [x] All nodes show `Ready`
- [x] All kube-system pods Running
- [x] Flannel pods Running on all nodes
- [x] CoreDNS pods Running
- [x] Network connectivity working

Time to deploy your applications!:D
