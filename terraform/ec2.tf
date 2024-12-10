# Resource EC2
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  #key_name      = var.key_name
  # associate_public_ip_address = true                                      
  subnet_id              = aws_subnet.private_subnet[count.index].id # SWITH TO PRIVATE
  vpc_security_group_ids = [aws_security_group.alb_sg.id]            # Attach the EC2 security group

  # Bootstrap script to install Nginx
  # Different index.html for each instance
  user_data = <<EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y

              sudo echo "<html><body><h1>Hello from EC2 instance ${count.index}</h1></body></html>" > /var/www/html/index.html

              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "EC2_Internship_Jakub_${count.index}"
  }
}