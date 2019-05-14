# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
  access_key = ""
  secret_key = ""
}

# Create a VPC to launch our instances into
resource "aws_vpc" "aarsh-terraform-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.aarsh-terraform-vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.aarsh-terraform-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.aarsh-terraform-vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.aarsh-terraform-vpc.id}"

 # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.aarsh-terraform-vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "aarsh-terraform-elb"
  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}



resource "aws_key_pair" "auth" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQd1IhJVtKg8zytX7FJBgjxqGrgt2dOqiyLx9qtHfv8BqTH+eDR/2Cfobj+5ICZXJKhg6K4Bfr8bSnLFkZN+bC/ys0ZC01AXOWE7J1bqDkfjS2gSTMkNoA6LTDCVyFEIeX9Im+NM7ERSwas22/YRHZWgfiPghhDK2DC0CMTk7qElH9QZ+KCyzdZOg+Ryg+IWO/MMGrcJ5MbnAqBTygR63oEX5WFAgC0LsOtDIbTByFPQQSrEHokDABhY2D68Qqd5azA1rqUbQ24Z7yyP87Zs5QbrpwaSef6dZoo8+HceOFmg6tuylv8lvGbVtlK1g8+uu1L88qjKjpjkcnosngiS62knFy8KtV2Tf8mFB3/URqOI+i4NN0BIAvVqI5lbLpgPXeRO++qN0g0pWy1vecPcIAd+XAPInRDUmlbB0z7lVuUutHigL6GD6iCP98lKV/lWOedfzr7ArtesLBXqXYIXqOl/RDAzCZy8nM357+pzZqBG5ho1Wf2fXcxcZsuQQQYE2c4MZHWf/A6SJQ9irZwCAwFWvHXTAoETDhOoLM/aMqCkefEN7nfxVw6VqhRPFKB7aFUlk4ZfzMwfXsvj4Tw8+OzIjDq1Vf1C6MiHw38hG5MtvL65t2W2RhveKTB7sQluAY5AgJEKLUhESnqPX78ylpv56zh3AZYHPEObOFIzSUbQ== ec2-user@ip-172-31-82-143.ec2.internal"
}


resource "aws_instance" "web" {
  #count = 3
  connection {
    user = "ec2-user"
    private_key = "${file("/home/ec2-user/.ssh/id_rsa")}" 
    type = "ssh"
    timeout = "1m"
    agent = false

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"
  #count = 3
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  key_name = "${aws_key_pair.auth.id}"

  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  subnet_id = "${aws_subnet.default.id}"

  provisioner "remote-exec" {

    inline = [
      "sudo yum -y update",
      "sudo amazon-linux-extras install nginx1.12 -y",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
    ]
    
}

    
  }



