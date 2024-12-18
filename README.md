# AWS First project
# Diagram

![Trustsoft_first_project drawio](https://github.com/user-attachments/assets/2b358b62-29b3-4daa-9f95-4202e3d121f2)

## Connection to an instance

```
aws ssm start-session --target <instance-id> --region eu-west-1
```

## Trubleshoting in an instance

```
sudo systemctl status apache2
```

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

    
## Resources created in alb.tf

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

## Resources in backend.tf

1. Centralized State Management:
  Stores the Terraform state file in an S3 bucket to enable collaboration between team members.
  State file updates are automatically synchronized for all users.

2. State Locking:
  Uses a DynamoDB table (terraform-locks-internship-jakub) to lock the state file, preventing simultaneous updates and ensuring consistency.

3. Encryption:
  Encrypts the Terraform state file stored in the S3 bucket for added security.

4. Customizable Path:
  Allows storing the state file at a specific key path: terraform/state/terraform.tfstate.

## Resources in backend/backend.tf

Preparation for terraform execution.

1. S3 Bucket for Terraform State
The aws_s3_bucket resource creates an S3 bucket to store the Terraform state file securely.
Features:
  Stores Terraform state files for centralized state management.
  Includes tags for organization and environment identification.
Key Attributes:
  Bucket Name: s3bucket-internship-jakub-12932
  Tags:
      Name: TerraformStateBucket
      Environment: production

2. S3 Bucket Versioning
The aws_s3_bucket_versioning resource enables versioning on the S3 bucket to maintain a history of state files. This helps recover from accidental deletions or state corruption.
Key Attributes:
  Versioning Status: Enabled

3. Server-Side Encryption
The aws_s3_bucket_server_side_encryption_configuration resource ensures the Terraform state file is encrypted using AWS Key Management Service (KMS).
Key Attributes:
  Encryption Type: aws:kms
  KMS Key ARN: Dynamically references a KMS key (aws_kms_key.kms_key.arn).

4. DynamoDB Table for State Locking
The aws_dynamodb_table resource creates a DynamoDB table to manage state locks. This prevents simultaneous state modifications by multiple users or processes.
Key Attributes:
  Table Name: terraform-locks-internship-jakub
  Billing Mode: PAY_PER_REQUEST
  Partition Key: LockID (String)
Tags:
  Name: TerraformStateLocks
  Environment: production

## Resources created in kms/kms.tf

1. KMS Key (`aws_kms_key.kms_key`)
   Description: `KMS Key for encrypting sensitive data`
   Deletion Window: 30 days
   Tags:
     Name: `KMSKey_Internship_Jakub`
     Environment: `Production`

2. KMS Alias (`aws_kms_alias.kms_alias`)
   Name: `alias/kms-key_2`
   Target Key ID: References the created KMS key.

3. KMS Key with Custom Policy (`aws_kms_key.kms_with_policy`)
   Description: `KMS Key with custom policy`
   Policy Details:
     Allows full KMS permissions for the root AWS account.
     Grants specific actions (`Encrypt`, `Decrypt`, `GenerateDataKey*`, `DescribeKey`) to the IAM role `aws-controltower-AdministratorExecutionRole`.

# LOGS

## Resources of logs in EC2

1. IAM Role and Policies

    aws_iam_role.vpc_flow_logs_role:
        Creates an IAM role to allow VPC Flow Logs to assume the role.
        Policy grants access to CloudWatch Logs.
    aws_iam_role_policy.vpc_flow_logs_policy:
        Attaches a policy to the IAM role for CloudWatch logging actions (CreateLogStream and PutLogEvents).

2. CloudWatch Log Group

    aws_cloudwatch_log_group.vpc_flow_logs_group:
        Stores VPC flow logs.
        Logs are retained for 3 days.

3. VPC Flow Logs

    aws_flow_log.vpc_flow_logs:
        Captures all traffic for a specified VPC (vpc-05ed2154c78668d0b).
        Logs are sent to the CloudWatch log group.

4. SNS Topic for Alerts

    aws_sns_topic.ec2_alerts_topic:
        Creates an SNS topic for EC2 alerts.
    aws_sns_topic_subscription:
        Adds email subscriptions for notifications:
            jakub.daxner@trustsoft.eu
            adam.simo@trustsoft.eu

    !! ERRROR !!
    SNS wont subscribe to email, so basicly this means they have probably some AWS API problem.
    I have updated it to "email-json" but because of Wednesday (18.12.) tasks I don't want to type:
    ```
    terraform apply
    ```

5. CloudWatch Alarms

    High CPU Utilization Alarm:
        Triggers when CPU utilization exceeds 80% for 2 consecutive minutes.

All alarms are tied to the SNS topic for notifications.

6. CloudWatch Agent Configuration

    aws_ssm_document.cloudwatch_config:
        Configures the CloudWatch Agent on EC2 instances to collect system metrics (disk and memory).
    aws_ssm_parameter.cloudwatch_config:
        Stores CloudWatch Agent configuration in SSM Parameter Store.
    aws_ssm_association.cloudwatch_agent:
        Associates the configuration with the target EC2 instances.
