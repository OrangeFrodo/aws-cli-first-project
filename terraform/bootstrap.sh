#!/bin/bash
apt-get update -y
apt-get install -y apache2
echo "<h1>Hello from EC2 instance ${instance_ip}</h1>" > /var/www/html/index.html
systemctl start apache2
systemctl enable apache2