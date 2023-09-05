terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  // Change if you want to use a different AWS region
  region = "us-east-2"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "ec2_role_policy"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListAllMyBuckets"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}


// Create an EC2 instance
/*
  - Name your resources appropriately and use descriptive names
  - Use a key pair that you have created in the AWS Management Console
  - Use the `t2.micro` instance type
  - Use the latest Amazon Linux 2 AMI for your region (hardcode the AMI ID)
  - Use the default VPC for your region
*/

resource "aws_instance" "app_server" {
  ami           = "ami-0911e88fb4687e06b"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allowssh.id]
  associate_public_ip_address = true

  key_name = "JimCAWSInstanceKey"
  
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id

  tags = {
    Name = "jimc-tf-instance"
  }

}


// Create a security group for the EC2 instance
/*
  - Name your resources appropriately and use descriptive names
  - Use a Security Group that allows SSH access from anywhere
*/
resource "aws_security_group" "allowssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "vpc-0a45b8e72c09a7c94"

  ingress {
    description      = "SSH inbound traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}


