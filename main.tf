terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region = "us-east-1"
}

################ NETWORK ################

# VPC setup
resource "aws_vpc" "sviacicd_vpc1" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "sviacicd-vpc1"
  }
}

# Subnet setup
resource "aws_subnet" "sn_db_A" {
  vpc_id            = aws_vpc.sviacicd_vpc1.id
  cidr_block        = "10.0.0.0/27"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn-db-A"
  }
}

resource "aws_subnet" "sn_priv_A" {
  vpc_id            = aws_vpc.sviacicd_vpc1.id
  cidr_block        = "10.0.0.32/27"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn-priv-A"
  }
}

resource "aws_subnet" "sn_pub_A" {
  vpc_id                  = aws_vpc.sviacicd_vpc1.id
  cidr_block              = "10.0.0.64/27"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sn-pub-A"
  }
}

# Internet Gateway setup
resource "aws_internet_gateway" "sviacicd_vpc1_igw" {
  vpc_id = aws_vpc.sviacicd_vpc1.id

  tags = {
    Name = "sviacicd-vpc1-igw"
  }
}

# Public Route Table setup
resource "aws_route_table" "sviacicd_vpc1_rt_pub" {
  vpc_id = aws_vpc.sviacicd_vpc1.id

  tags = {
    Name = "sviacicd-vpc1-rt-pub"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sviacicd_vpc1_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "sn_pub_A_assoc" {
  subnet_id      = aws_subnet.sn_pub_A.id
  route_table_id = aws_route_table.sviacicd_vpc1_rt_pub.id
}




################ INSTANCES ################

# EC2 Instances setup
resource "aws_instance" "sc11_instance" {
  ami           = "ami-006d8b952eb9afa79" # Windows AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_pub_A.id
  private_ip = "10.0.0.94"
 

  key_name = "A4L"

  vpc_security_group_ids = [aws_security_group.windows-RDPaccess-sg.id] # Associate the security group with the instance

  tags = {
    Name = "sc11"
  }

  # Provisioning script
  user_data = file("${path.module}/provisioning_scripts/sc11_windows_instance_provision.ps1")

}

resource "aws_instance" "app_server_instance" {
  ami           = "ami-0005e0cfe09cc9050" # Linux AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_pub_A.id
  private_ip = "10.0.0.73"

  key_name = "A4L"

  vpc_security_group_ids = [aws_security_group.app-server-sg.id] # Associate the security group with the instance

  tags = {
    Name = "app-server"
  }

  # Provisioning script
  user_data = file("${path.module}/provisioning_scripts/app_server_instance_provision.sh")
  
}

resource "aws_instance" "jenkins_server_instance" {
  ami           = "ami-0005e0cfe09cc9050" # Linux AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_pub_A.id
  private_ip = "10.0.0.87"

  key_name = "A4L"

  vpc_security_group_ids = [aws_security_group.jenkins-server-sg.id] # Associate the security group with the instance

  tags = {
    Name = "jenkins-server"
  }

  # Provisioning script
  user_data = file("${path.module}/provisioning_scripts/jenkins_server_instance_provision.sh")

}


# Security Group for Windows EC2 "sc11" instance
resource "aws_security_group" "windows-RDPaccess-sg" {
  name        = "windows-RDPaccess-sg"
  description = "Security group for Windows EC2 RDP access"

  vpc_id = aws_vpc.sviacicd_vpc1.id

  # Inbound rule for RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule allowing all traffic (for installing Jenkins, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Security Group for Linux EC2 "app-server" instance
resource "aws_security_group" "app-server-sg" {
  name        = "appserver-access-sg"
  description = "Security group for Linux EC2 app-server access"

  vpc_id = aws_vpc.sviacicd_vpc1.id

  # Inbound rule for SSH (port 22) for EC2 Instance Connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Linux EC2 "jenkins-server" instance
resource "aws_security_group" "jenkins-server-sg" {
  name        = "jenkins-server-sg"
  description = "Security group for Linux EC2 Jenkins access"

  vpc_id = aws_vpc.sviacicd_vpc1.id

  # Inbound rule for web access 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for SSH (port 22) for EC2 Instance Connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule allowing all traffic (for installing Jenkins, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}