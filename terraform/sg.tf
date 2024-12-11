# Create Security Group for the ALB
resource "aws_security_group" "alb_sg" {
  name   = "ALBSecurityGroup_Internship_Jakub"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALBSecurityGroup_Internship_Jakub"
  }
}