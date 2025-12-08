provider "aws" {
  region = "ap-southeast-2"
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group in default VPC
resource "aws_security_group" "node_sg" {
  name        = "node-sg"
  description = "Allow HTTP & SSH traffic"
  vpc_id      = data.aws_vpc.default.id

  # Allow NodeJS app (port 5000)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance in default VPC
resource "aws_instance" "node_app" {
  ami                    = "ami-003107ac7f78f1db1"
  instance_type          = "t3.micro"
  key_name               = "devops"
  vpc_security_group_ids = [aws_security_group.node_sg.id]

  user_data = <<EOF
#!/bin/bash
apt update -y
apt install -y git curl

# Install Node.js 18 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2
npm install -g pm2

cd /home/ubuntu
git clone https://github.com/venkataraviraja5/aws-s3.git
cd aws-s3
npm install

pm2 start index.js
pm2 startup systemd
pm2 save
EOF


  tags = {
    Name = "NodeJS-App"
  }
}

output "ec2_public_ip" {
  value = aws_instance.node_app.public_ip
}
