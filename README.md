# Vprofile Multi-VM Vagrant Environment

This project provides a fully automated Vagrant-based multi-VM environment used to deploy the Vprofile application stack.
Each VM is provisioned automatically using shell scripts, and all services are configured end-to-end without manual steps.

## 1. Architecture Overview

The environment consists of five virtual machines:

| VM Name | IP Address       | Role                                |
|---------|------------------|--------------------------------------|
| web01   | 192.168.56.11    | Nginx reverse proxy (HTTPS)          |
| app01   | 192.168.56.12    | Tomcat + Java application            |
| rmq01   | 192.168.56.13    | RabbitMQ message broker              |
| mc01    | 192.168.56.14    | Memcached                            |
| db01    | 192.168.56.15    | MariaDB database                     |

All VMs are based on:
`eurolinux-vagrant/centos-stream-9`

## 2. Features

- Automated provisioning using shell scripts
- HTTPS enabled on Nginx with self-signed certificates
- Tomcat service installed as a systemd unit
- Source code cloned and built using Maven on app01
- Database auto-configured with secured root password and imported backup
- RabbitMQ configured with custom users and permissions
- Memcached configured to accept remote connections
- Hostname resolution across all VMs

## 3. Directory Structure

```
vprofile-vagrant/
│
├── Vagrantfile
│
└── provision/
    ├── db01.sh
    ├── mc01.sh
    ├── rmq01.sh
    ├── app01.sh
    └── web01.sh
```

## 4. Requirements

- Vagrant
- VirtualBox
- Vagrant Hostmanager plugin

Install using:
```
vagrant plugin install vagrant-hostmanager
```

## 5. How to Run

1. Clone the repository:
```
git clone <your-repo-url>
cd vprofile-vagrant
```

2. Bring up the entire environment:
```
vagrant up
```

3. Reprovision a single VM:
```
vagrant reload <vm-name> --provision
```

4. Destroy and rebuild:
```
vagrant destroy -f
vagrant up
```

## 6. Application Access

HTTPS Application URL:

```
https://192.168.56.11/
```

A browser warning will appear because of the self-signed certificate.

## 7. VM Roles Summary

### db01 (MariaDB)
- MariaDB server installed
- mysql_secure_installation automated
- Accounts DB created and populated

### mc01 (Memcached)
- Memcached installed and enabled
- Listens on 0.0.0.0

### rmq01 (RabbitMQ)
- RabbitMQ 3.8 installed
- Remote access enabled
- Test user created

### app01 (Tomcat)
- Java 11, Maven, Git installed
- Tomcat 9 set up under /usr/local/tomcat
- Vprofile WAR built and deployed

### web01 (Nginx)
- HTTPS reverse proxy
- Self-signed SSL certificate
- HTTP redirected to HTTPS

## 8. Notes

- Modify IP addresses if needed
- Self‑signed certificates for local use only
- Ensure VirtualBox supports virtualization

## 9. Troubleshooting

View logs:
```
journalctl -xe
```

Test database:
```
mysql -h db01 -u admin -padmin123 accounts
```

Test memcached:
```
telnet mc01 11211
```

## 10. License

This project is for learning and DevOps training purposes.
