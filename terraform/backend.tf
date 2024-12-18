terraform {
  backend "s3" {
    bucket         = "s3bucket-internship-jakub-12932"
    key            = "terraform/state/terraform.tfstate" # Path in the bucket
    region         = "eu-west-1"                         # Replace with your region
    dynamodb_table = "terraform-locks-internship-jakub"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "postgres_backup" {
  bucket = "my-postgres-backup-bucket-internship-jakub-12932"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 30
    }
  }
}