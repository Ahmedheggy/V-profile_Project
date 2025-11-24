#!/bin/bash
set -e

##########################################
# Install Dependencies
##########################################
sudo dnf -y install java-11-openjdk java-11-openjdk-devel git maven wget

##########################################
# Install Tomcat
##########################################
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
tar xzvf apache-tomcat-9.0.75.tar.gz

useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat || true
cp -r /tmp/apache-tomcat-9.0.75/* /usr/local/tomcat/
chown -R tomcat:tomcat /usr/local/tomcat

##########################################
# Create Tomcat service (Java 11)
##########################################
cat <<EOL > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk"
Environment="CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/usr/local/tomcat"
Environment="CATALINA_BASE=/usr/local/tomcat"
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable --now tomcat

##########################################
# Clone App Source Code
##########################################
cd /tmp
rm -rf sourcecodeseniorwr || true
git clone https://github.com/abdelrahmanonline4/sourcecodeseniorwr.git
cd sourcecodeseniorwr

##########################################
# Fix application.properties
##########################################
cat <<EOF > src/main/resources/application.properties
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://db01:3306/accounts?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
jdbc.username=admin
jdbc.password=admin123

memcached.active.host=mc01
memcached.active.port=11211
memcached.standBy.host=mc01
memcached.standBy.port=11211

rabbitmq.address=rmq01
rabbitmq.port=5672
rabbitmq.username=guest
rabbitmq.password=guest

# Disable elasticsearch completely
elasticsearch.host=disabled
elasticsearch.port=0
elasticsearch.cluster=disabled
elasticsearch.node=disabled
EOF

##########################################
# Build application
##########################################
mvn clean install -DskipTests

##########################################
# Deploy WAR to Tomcat
##########################################
systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/ROOT.war
cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
chown -R tomcat:tomcat /usr/local/tomcat/webapps/

systemctl start tomcat
sleep 10

echo "---- Deployment Completed ----"
curl -I http://localhost:8080/ || true
