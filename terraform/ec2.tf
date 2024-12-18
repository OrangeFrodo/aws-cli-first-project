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

resource "aws_iam_policy_attachment" "ec2_cloudwatch_attach" {
  name       = "EC2CloudWatchAttach-Internship-Jakub"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "EC2_Internship_Jakub"
  role = aws_iam_role.ec2_role.name
}

## LOGS

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc_flow_logs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc_flow_logs_policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs_group" {
  name              = "/vpc/flowlogs"
  retention_in_days = 3
}

resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = "vpc-05ed2154c78668d0b"
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
}

resource "aws_sns_topic" "ec2_alerts_topic" {
  name = "ec2-alerts-topic-internship-jakub"
}

resource "aws_sns_topic_subscription" "email_subscription_1" {
  topic_arn = aws_sns_topic.ec2_alerts_topic.arn
  protocol  = "email-json"
  endpoint  = "jakub.daxner@trustsoft.eu"
}

resource "aws_sns_topic_subscription" "email_subscription_2" {
  topic_arn = aws_sns_topic.ec2_alerts_topic.arn
  protocol  = "email-json"
  endpoint  = "adam.simo@trustsoft.eu"
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm_1" {
  alarm_name          = "high-cpu-utilization-internship-jakub-1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80 # 80% CPU utilization
  alarm_description   = "This alarm triggers when CPU utilization exceeds 80% for 2 minutes."
  dimensions = {
    InstanceId = "i-070349fb6b2aee640"
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ec2_alerts_topic.arn]
  ok_actions      = [aws_sns_topic.ec2_alerts_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm_2" {
  alarm_name          = "high-cpu-utilization-internship-jakub-2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80 # 80% CPU utilization
  alarm_description   = "This alarm triggers when CPU utilization exceeds 80% for 2 minutes."
  dimensions = {
    InstanceId = "i-0ac127174124d1879"
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ec2_alerts_topic.arn]
  ok_actions      = [aws_sns_topic.ec2_alerts_topic.arn]
}

resource "aws_ssm_document" "cloudwatch_config" {
  count         = 2
  name          = "CloudWatchAgentConfig-${count.index}-Internship-Jakub"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "CloudWatch Agent configuration for EC2"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "InstallCloudWatchAgent"
        inputs = {
          runCommand = [
            "wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb",
            "sudo dpkg -i -E ./amazon-cloudwatch-agent.deb",
            "sudo apt-get update && sudo apt-get install -y collectd",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${aws_ssm_parameter.cloudwatch_config[count.index].name} -s",
            "sudo systemctl enable amazon-cloudwatch-agent",
            "sudo systemctl start amazon-cloudwatch-agent"
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_parameter" "cloudwatch_config" {
  count = 2
  name  = "CloudWatchAgentConfig-Internship-Jakub-${count.index}"
  type  = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      logfile                     = "/var/log/cloudwatch-agent.log"
    }
    metrics = {
      append_dimensions = {
        InstanceId = "${aws_instance.web[count.index].id}"
      }
      metrics_collected = {
        disk = {
          measurement              = ["used_percent", "inodes_free"]
          resources                = ["*"]
          ignore_file_system_types = ["sysfs", "tmpfs"]
        }
        mem = {
          measurement = ["mem_used_percent"]
        }
      }
    }
  })
  overwrite = true
}


resource "aws_ssm_association" "cloudwatch_agent" {
  count = 2
  name  = aws_ssm_document.cloudwatch_config[count.index].name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.web[count.index].id]
  }
}
