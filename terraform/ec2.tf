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

  private_ip = count.index % 2 == 0 ? "10.0.3.90" : "10.0.4.90"

  # Bootstrap script to install Apache
  # Different index.html for each instance
  # THIS DOES NOT WORK !!!!!
  user_data = templatefile("bootstrap.sh", {
    instance_ip = count.index % 2 == 0 ? "10.0.3.90" : "10.0.4.90"
  })

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
