# 🧩 Docker Custom Bridge Network for HR Application Stack

This document summarizes all commands, explanations, and steps for establishing a **dedicated and isolated custom bridge network** for an HR application stack on a single Docker host.

---

## 🎯 Objective
Create an isolated Docker network for the HR application with proper service discovery using container names, while avoiding conflicts with the **corporate VPN** that uses the `172.17.0.0/16` range.

---

## ⚙️ Requirements

| Parameter | Value |
|------------|--------|
| **Network Type** | Custom Bridge |
| **Network Name** | `hr-app-net` |
| **Dedicated Subnet** | `192.168.20.0/24` |
| **Gateway** | `192.168.20.1` |
| **Application Stack** | - NGINX (Web Frontend) <br> - Alpine (Diagnostics Tester) |

---

## 🧱 Step 1: Network Creation

### 🔹 Command:
```bash
docker network create   --driver bridge   --subnet 192.168.20.0/24   --gateway 192.168.20.1   hr-app-net
```

### 💬 Explanation:
- `--driver bridge`: Creates a user-defined bridge network.
- `--subnet` and `--gateway`: Define the custom subnet and gateway to prevent conflicts with the VPN network.
- `hr-app-net`: The name of the network.

---

## 🔍 Step 2: Verify Network Configuration

### 🔹 Command:
```bash
docker network inspect hr-app-net
```

### 🔹 To filter subnet/gateway info:
```bash
docker network inspect hr-app-net | grep -E 'Subnet|Gateway'
```

### ✅ Expected Output:
```
"Subnet": "192.168.20.0/24",
"Gateway": "192.168.20.1"
```

---

## 🚀 Step 3: Deploy Containers

### 🔹 NGINX Server:
```bash
docker run -d -it --name nginx-server --network hr-app-net nginx
```

### 🔹 Alpine Tester:
```bash
docker run -d -it --name alpine-tester --network hr-app-net alpine sh
```

### 💬 Explanation:
- `-d`: Detached mode.
- `-i`: Interactive (keep STDIN open).
- `-t`: Allocate pseudo-TTY.###terminal###
- `--network hr-app-net`: Attach container to our custom bridge network.

---

## 🧩 Step 4: Verify IP Address Allocation

### 🔹 Check each container’s IP:
```bash
docker inspect nginx-server | grep IPAddress
docker inspect alpine-tester | grep IPAddress
```

### ✅ Expected Output Example:
```
"IPAddress": "192.168.20.2"
"IPAddress": "192.168.20.3"
```

### 💬 Explanation:
Each container receives a unique IP from the `192.168.20.0/24` range.

---

## 🧠 Step 5: Install Ping in Alpine

Alpine is minimal — it doesn’t include `ping` by default.

### 🔹 Command inside Alpine:
```bash
apk add iputils
```

### 💬 Explanation:
`iputils` stands for “IP Utilities” — it includes tools like `ping`, `tracepath`, etc.
`apk` is the package manger of Alpine

---

## 🌐 Step 6: Test Service Discovery (DNS Resolution)

### 🔹 Enter the Alpine container:
```bash
docker exec -it alpine-tester sh
```

### 🔹 Ping the NGINX container by name:
```bash
ping nginx-server
```

### ✅ Expected Result:
```
PING nginx-server (192.168.20.2): 56 data bytes
64 bytes from 192.168.20.2: seq=0 ttl=64 time=0.120 ms
```

### 💬 Explanation:
Docker’s **internal DNS** automatically maps `nginx-server` → `192.168.20.2`.  
Both containers are in the same subnet, so communication works directly.

---

## 🧭 Step 7: Verify Internal DNS and Connectivity

### 🔹 Test name resolution manually:
```bash
cat /etc/hosts
cat /etc/resolv.conf
```

You’ll see Docker’s internal DNS IP (`127.0.0.11`) responsible for service discovery.

---

## 🧰 Step 8: Useful Maintenance Commands

### List all networks:
```bash
docker network ls
```

### Inspect containers in a network:
```bash
docker network inspect hr-app-net | grep -E 'Name|IPv4Address'
```

### Connect a running container to the network:
```bash
docker network connect hr-app-net container_name
```

### Disconnect a container:
```bash
docker network disconnect hr-app-net container_name
```

---

## 📊 Expected Outcome

✅ Both containers receive IPs from `192.168.20.0/24`  
✅ `alpine-tester` can ping `nginx-server` by **name**, proving DNS-based discovery works  
✅ Network is **isolated** and **free from VPN conflicts**  

---

## 🖼️ Conceptual Illustration

```
+-----------------------------------------------------+
|                Docker Host (Bridge)                 |
|                                                     |
|  Network: hr-app-net (192.168.20.0/24)              |
|  Gateway: 192.168.20.1                              |
|                                                     |
|  +-------------------+       +-------------------+  |
|  | nginx-server      |<----->| alpine-tester     |  |
|  | 192.168.20.2      |       | 192.168.20.3      |  |
|  | hostname: nginx   |       | hostname: alpine  |  |
|  +-------------------+       +-------------------+  |
|                                                     |
+-----------------------------------------------------+
```

---

## 🏁 Summary

| Step | Description | Key Command |
|------|--------------|-------------|
| 1 | Create network | `docker network create --subnet 192.168.20.0/24 --gateway 192.168.20.1 hr-app-net` |
| 2 | Inspect network | `docker network inspect hr-app-net` |
| 3 | Run containers | `docker run -dit --name nginx-server --network hr-app-net nginx` |
| 4 | Verify IPs | `docker inspect container_name | grep IPAddress` |
| 5 | Install ping | `apk add iputils` |
| 6 | Ping by name | `ping nginx-server` |

---

✅ **Result:** Service discovery and communication via container names successfully demonstrated within an isolated Docker bridge network.
