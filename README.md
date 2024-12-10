# AWS First project

## Resources created in vpc.tf
This configuration includes:
  VPC: A single VPC (10.0.0.0/16) with public and private subnets.
  Public Subnets: Two public subnets with Internet Gateway connectivity.
  Private Subnets: Two private subnets with NAT Gateway for outbound internet access.
  Route Tables: Separate route tables for public and private subnets.
  NAT Gateway: Allows instances in private subnets to access the internet securely.
  Internet Gateway: Enables internet connectivity for public subnets.
  
1. VPC
  Creates a VPC with a CIDR block of 10.0.0.0/16.
  Named: VPC_Intenrship_Jakub.

2. Public Subnets
  Count: 2 (one per availability zone).
  CIDR Block: Derived from the VPC CIDR block using Terraform's cidrsubnet function.
  Features:
      Automatically assigns public IPs to instances.
      Associated with the public route table.

3. Private Subnets
  Count: 2 (one per availability zone).
  CIDR Block: Derived from the VPC CIDR block using Terraform's cidrsubnet function.
  Features:
      Instances do not receive public IPs.
      Outbound internet access via NAT Gateway.

4. Route Tables
Public Route Table
  Routes all traffic (0.0.0.0/0) through the Internet Gateway.
  Associated with public subnets.

Private Route Table
  Routes all traffic (0.0.0.0/0) through the NAT Gateway.
  Associated with private subnets.  

5. NAT Gateway
  Provides internet access to instances in private subnets.
  Allocates an Elastic IP (EIP) for NAT Gateway.

6. Internet Gateway
  Provides internet access for public subnets.

7. Route Table Associations
  Associates the public route table with public subnets.
  Associates the private route table with private subnets.


## Resources created in sg.tf

1. VPC Association
  The security group is associated with the VPC defined by aws_vpc.main_vpc.id.

2. Inbound Rules
  Defines the inbound traffic allowed to the ALB:
    Protocol: TCP
    Port Range: 80 (HTTP traffic)
    Source: 0.0.0.0/0 (allows traffic from any IP address)

3. Outbound Rules
  Allows all outbound traffic from the ALB. This is required to ensure the ALB can forward traffic to registered targets (e.g., EC2 instances, Lambda functions).
    Protocol: All (-1)
    Port Range: All
    Destination: 0.0.0.0/0 (unrestricted)

## Features in ec2.tf

Features:
  Two EC2 Instances:
    Created with a dynamic count value (count = 2).
    Each instance is uniquely identified and tagged.

  Private Subnet Placement:
    The instances are placed in private subnets, ensuring they are not directly accessible from the internet.

  Security:
    Security group (alb_sg) attached to control traffic.

  Apache Web Server:
    Installed and configured through a user data script.
    Serves a unique HTML file per instance.

  Storage:
    Configures a 20GB root volume using the GP3 volume type

# Resources created in alb.tf

This configuration includes:
  Target Group:
    Manages and monitors EC2 instances as the backend targets.
  Application Load Balancer (ALB):
    A public-facing ALB to handle incoming traffic.
  Listener:
    Listens on port 80 (HTTP) and forwards requests to the Target Group.
  Target Group Attachments:
    Registers EC2 instances with the Target Group.

1. Target Group
The Target Group defines the backend instances that the ALB forwards traffic to.
  Resource: aws_lb_target_group.example_tg
  Configuration:
      Name: Jakub-example-target-group
      Port: 80 (HTTP traffic).
      Protocol: HTTP.
      Target Type: instance (targets are EC2 instances).
      VPC: Associated with the VPC defined in aws_vpc.main_vpc.id.

2. Application Load Balancer (ALB)
The Application Load Balancer manages traffic distribution to the Target Group.
  Resource: aws_lb.example_alb
  Configuration:
      Name: walb-internship-jakub.
      Internal: false (public-facing).
      Security Groups: Associated with the ALB security group alb_sg.
      Subnets: Uses public subnets to handle internet-facing traffic.
      Type: application.

3. ALB Listener
The ALB Listener listens for incoming HTTP traffic on port 80 and forwards it to the Target Group.
  Resource: aws_lb_listener.http_listener
  Configuration:
      Port: 80.
      Protocol: HTTP.
      Default Action: Forwards traffic to the Target Group.

4. Target Group Attachments
Registers EC2 instances with the Target Group to distribute traffic.
  Resource: aws_lb_target_group_attachment.private_instance_attachment
  Configuration:
      Target Group: Associates the instances with example_tg.
      Count: Registers two EC2 instances (count = 2).
      Target ID: Dynamically references aws_instance.web instances.
      Port: 80.
