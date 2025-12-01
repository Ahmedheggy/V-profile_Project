#!/bin/bash
set -e

dnf install epel-release -y
dnf install git mariadb-server expect -y   ## install "expect" for automating mysql_secure_installation
systemctl enable --now mariadb

DB_PASSWORD="admin123"
DB_USER="admin"
DB_NAME="accounts"

echo "Running mysql_secure_installation..."
/usr/bin/expect <<EOF_EXPECT
spawn mysql_secure_installation
expect "Enter current password" { send "\r" }
expect "unix_socket authentication" { send "n\r" }
expect "Change the root password?" { send "y\r" }
expect "New password" { send "$DB_PASSWORD\r" }
expect "Re-enter new password" { send "$DB_PASSWORD\r" }
expect "Remove anonymous users" { send "y\r" }
expect "Disallow root login remotely" { send "n\r" }
expect "Remove test database" { send "y\r" }
expect "Reload privilege tables" { send "y\r" }
expect eof
EOF_EXPECT

echo "Creating DB & user..."
mysql -u root -p$DB_PASSWORD <<EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

cd /tmp
git clone https://github.com/abdelrahmanonline4/sourcecodeseniorwr.git
cd sourcecodeseniorwr/
mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql

systemctl restart mariadb
