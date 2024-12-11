# resource "aws_kms_key" "kms_key" {
#   description             = "KMS Key for encrypting sensitive data"
#   deletion_window_in_days = 30

#   tags = {
#     Name        = "KMSKey_Internship_Jakub"
#     Environment = "Production"
#   }
# }

# resource "aws_kms_alias" "kms_alias" {
#   name          = "alias/kms-key"
#   target_key_id = aws_kms_key.kms_key.key_id
# }

# resource "aws_kms_key" "kms_with_policy" {
#   description = "KMS Key with custom policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         Action   = "kms:*",
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow access for specific IAM role",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MyRole"
#         },
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# data "aws_caller_identity" "current" {}