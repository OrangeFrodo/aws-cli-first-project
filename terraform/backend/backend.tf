# KMS KEY
# ENCRYPTE THE DISK KMS

resource "aws_s3_bucket" "s3_terraform_state" {
  bucket = "s3bucket-internship-jakub-12932"

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.s3_terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "dynamo_terraform_locks" {
  name         = "terraform-locks-internship-jakub"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformStateLocks"
    Environment = "production"
  }
}
