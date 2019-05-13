

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-09201ef0521be7729"
    us-east-2 = "ami-09201ef0521be7729"
    us-west-1 = "ami-09201ef0521be7729"
  }
}

#variable "instance_count" {
#  default = 3
# }

