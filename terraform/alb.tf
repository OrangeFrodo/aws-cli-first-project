# Create Target Group
resource "aws_lb_target_group" "example_tg" {
  name        = "Jakub-example-target-group" # Name of the target group
  port        = 80                           # Port the target listens on
  protocol    = "HTTP"                       # Protocol (HTTP, HTTPS, or TCP)
  vpc_id      = aws_vpc.main_vpc.id          # VPC where the target group resides
  target_type = "instance"                   # Type of target (instance, ip, or lambda)

  tags = {
    Name = "TargetGroup_Internship_Jakub"
  }
}

# Create the ALB
resource "aws_lb" "example_alb" {
  name            = "walb-internship-jakub"
  internal        = false # Public-facing ALB
  security_groups = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
  load_balancer_type = "application"

  tags = {
    Name = "WebALB"
  }
}

# Define an Application Load Balancer (ALB) Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.example_alb.arn # Reference the ALB created earlier
  port              = 80                     # Listener port (e.g., HTTP port)
  protocol          = "HTTP"                 # Listener protocol (HTTP or HTTPS)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_tg.arn # Forward traffic to the target group
  }
}

# Register Private EC2 Instances in Target Group
resource "aws_lb_target_group_attachment" "private_instance_attachment" {
  count            = 2 # For multiple EC2 instances
  target_group_arn = aws_lb_target_group.example_tg.arn
  target_id        = aws_instance.web[count.index].id # Referencing private EC2 instances
  port             = 80                               # Port the target listens on
}