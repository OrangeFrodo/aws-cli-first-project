# Resource EC2
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  #key_name      = var.key_name
  # associate_public_ip_address = true                                      
  subnet_id              = count.index % 2 == 0 ? aws_subnet.private_subnet_1.id : aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.alb_sg.id] # Attach the EC2 security group
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance.name

  # Bootstrap script to install Nginx
  # Different index.html for each instance
  # THIS DOES NOT WORK !!!!!
  user_data = <<EOT
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get install apache2 -y

  mkdir -p /var/www/html
  echo "<html><body><h1>Hello from EC2 instance ${count.index} </h1></body></html>" | sudo tee /var/www/html/index.html > /dev/null

  sudo systemctl start apache2
  sudo systemctl enable apache2
  EOT

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "EC2_Internship_Jakub_${count.index}"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "IAM_Role_Internship_Jakub"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "EC2_Internship_Jakub"
  role = aws_iam_role.ec2_role.name
}
