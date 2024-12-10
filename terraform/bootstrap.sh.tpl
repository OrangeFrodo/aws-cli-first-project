#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 -y

sudo echo "<html><body><h1>Hello from EC2 instance ${count.index}</h1></body></html>" > /var/www/html/index.html

sudo systemctl start apache2
sudo systemctl enable apache2