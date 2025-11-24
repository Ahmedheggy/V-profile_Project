#!/bin/bash
set -e

dnf install nginx openssl -y

mkdir -p /etc/nginx/ssl

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=EG/ST=Cairo/L=Cairo/O=VProfile/OU=IT/CN=web01" \
  -keyout /etc/nginx/ssl/web01.key \
  -out /etc/nginx/ssl/web01.crt

chmod 600 /etc/nginx/ssl/web01.*

sed -i 's/server_name\s\+_;/server_name web01;/' /etc/nginx/nginx.conf

cat <<EOF > /etc/nginx/conf.d/server.conf
upstream vproapp {
    server app01:8080;
}

server {
    listen 443 ssl;
    server_name web01;

    ssl_certificate /etc/nginx/ssl/web01.crt;
    ssl_certificate_key /etc/nginx/ssl/web01.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://vproapp;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name web01;
    return 301 https://\$host\$request_uri;
}
EOF

systemctl restart nginx
systemctl enable nginx
