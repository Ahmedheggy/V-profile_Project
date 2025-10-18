#  Multi-Homed Container Architecture with Docker

This document summarizes all commands, explanations, and steps for demonstrating a **multi-homed container setup**, where a single NGINX Load Balancer is connected to **two isolated custom bridge networks**, segregating frontend and backend traffic.

---

## Objective
Demonstrate a multi-homed container setup:
- **Frontend Network:** handles client traffic
- **Backend Network:** handles internal service communication 
The NGINX Load Balancer (`nginx-lb`) bridges these networks, while client and backend containers remain isolated.

---

## Requirements

| Network | Name | Subnet | Connected Containers |
|---------|------|--------|--------------------|
| Frontend | frontend-net | 10.1.1.0/24 | nginx-lb, client-tester |
| Backend | backend-net | 10.1.2.0/24 | nginx-lb, backend-db |

| Container | Network Connection |
|-----------|------------------|
| nginx-lb | Multi-homed (frontend-net + backend-net) |
| client-tester | frontend-net only |
| backend-db | backend-net only |

---

## Step 1: Create Networks

### 🔹 Frontend Network:
```bash
docker network create --driver bridge --subnet 10.1.1.0/24 frontend-net
```

### 🔹 Backend Network:
```bash
docker network create --driver bridge --subnet 10.1.2.0/24 backend-net
```

### Explanation:
- `--driver bridge`: Creates a user-defined bridge network.
- `--subnet`: Specifies custom subnet for IP allocation.  
- Each network is isolated from the other.

---

## Step 2: Deploy Isolated Containers

### Backend Service (Database):
```bash
docker run -dit --name backend-db --network backend-net alpine sh
```

### Client Tester:
```bash
docker run -dit --name client-tester --network frontend-net alpine sh
```

### Explanation:
- `backend-db` only sees `backend-net`.  
- `client-tester` only sees `frontend-net`.  
- Isolation ensures no direct communication between frontend and backend.

---

## Step 3: Deploy Multi-Homed Container (NGINX Load Balancer)

### Command:
```bash
docker run -dit --name nginx-lb   --network frontend-net   --network backend-net   nginx
```

### Explanation:
- `--network frontend-net --network backend-net` connects a **single container to two networks**.  
- `nginx-lb` acts as the routing bridge between frontend and backend.

---

## Step 4: Verify IP Allocation

### Inspect NGINX Load Balancer IPs:
```bash
docker inspect nginx-lb | grep IPAddress
```

### Expected Output Example:
```
"IPAddress": "10.1.1.2"   # Frontend Network
"IPAddress": "10.1.2.2"   # Backend Network
```

### Explanation:
The container is **multi-homed** and receives **distinct IPs** from each connected network.

---

## Step 5: Isolation Test

### From client-tester, try to ping backend-db:
```bash
docker exec -it client-tester sh
ping backend-db
```

###  Expected Result:
- **Ping fails** because `client-tester` is not connected to `backend-net`.
- Confirms network isolation between frontend and backend.

### Optional: Verify nginx-lb can reach backend-db
```bash
docker exec -it nginx-lb ping backend-db
```

### Expected Result:
- **Ping succeeds**, demonstrating nginx-lb bridges the networks.

---

## Step 6: Useful Maintenance Commands

### List networks:
```bash
docker network ls
```

### Inspect a network:
```bash
docker network inspect frontend-net
docker network inspect backend-net
```

### Connect an existing container to a network:
```bash
docker network connect network_name container_name
```

### Disconnect a container:
```bash
docker network disconnect network_name container_name
```

---

## Conceptual Illustration

```
+------------------------------------------+
|              Docker Host                  |
|                                          |
|  Frontend Network: frontend-net           |
|   Subnet: 10.1.1.0/24                    |
|   Containers: client-tester, nginx-lb    |
|                                          |
|  Backend Network: backend-net             |
|   Subnet: 10.1.2.0/24                    |
|   Containers: backend-db, nginx-lb       |
|                                          |
|  Multi-Homed NGINX Load Balancer         |
|  bridges frontend-net <--> backend-net   |
+------------------------------------------+
```

---

## Expected Outcome

✅ `nginx-lb` has two IPs: one in `frontend-net` and one in `backend-net`.  
✅ `client-tester` cannot ping `backend-db`.  
✅ `nginx-lb` can communicate with both frontend and backend, acting as the bridge.  
✅ Isolation between frontend and backend networks is preserved.

---

## Summary of Steps

| Step | Description | Key Command |
|------|------------|-------------|
| 1 | Create frontend network | `docker network create --driver bridge --subnet 10.1.1.0/24 frontend-net` |
| 2 | Create backend network | `docker network create --driver bridge --subnet 10.1.2.0/24 backend-net` |
| 3 | Deploy isolated containers | `docker run -dit --name backend-db --network backend-net alpine sh` <br> `docker run -dit --name client-tester --network frontend-net alpine sh` |
| 4 | Deploy multi-homed container | `docker run -dit --name nginx-lb --network frontend-net --network backend-net nginx` |
| 5 | Verify IPs | `docker inspect nginx-lb | grep IPAddress` |
| 6 | Test isolation | `ping backend-db` from client-tester (should fail) |
| 7 | Test bridging | `ping backend-db` from nginx-lb (should succeed) |

**Result:** Multi-homed container architecture successfully demonstrates traffic segregation and controlled routing using Docker bridge networks.
