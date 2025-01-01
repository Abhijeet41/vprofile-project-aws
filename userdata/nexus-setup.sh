#!/bin/bash

# Importing Corretto GPG key and setting up repository
wget -O- https://yum.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/corretto-archive-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list

# Updating package lists and installing Amazon Corretto 17
sudo apt update
sudo apt install -y java-17-amazon-corretto-jdk wget

# Setting up Nexus installation directories
mkdir -p /opt/nexus/   
mkdir -p /tmp/nexus/                           
cd /tmp/nexus/
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz
sleep 10
EXTOUT=`tar xzvf nexus.tar.gz`
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`
sleep 5
rm -rf /tmp/nexus/nexus.tar.gz
sudo cp -r /tmp/nexus/* /opt/nexus/
sleep 5

# Adding Nexus user and setting permissions
sudo useradd -r -s /bin/false nexus
sudo chown -R nexus:nexus /opt/nexus 

# Creating Nexus systemd service
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOT
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Configuring Nexus to run as 'nexus' user
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Enabling and starting Nexus service
sudo systemctl daemon-reload
sudo systemctl start nexus
sudo systemctl enable nexus
