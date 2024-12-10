variable "ami_id" {
  description = "The AMI ID to use for the instance"
  default     = "ami-0e9085e60087ce171"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to launch"
  default     = "t2.micro"
}

# KMS Encryption
# ESM Connection
# variable "key_name" {
#   description = "Key pair name for EC2 instance"
#   default     = "EC2KP_Internship_Jakub"
#   type        = string
# }