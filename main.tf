provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "demo-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-igw"
  }
}

# Create a route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a security group for SSH access
resource "aws_security_group" "ssh" {
  name        = "ssh-access"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description = "SSH from anywhere"
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

  tags = {
    Name = "demo-ssh-sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "public" {
  ami           = "ami-000a08b963606bb82"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name      = "fouad-key"

  tags = {
    Name = "public-demo-instance"
  }
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_instance.public.public_ip
  description = "The public IP address of the EC2 instance"
} 