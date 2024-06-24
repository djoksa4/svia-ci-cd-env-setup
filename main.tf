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

  # Provisioning steps using remote-exec provisioner
  user_data = <<-EOF
<powershell>
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server

# Set service to start automatically
Set-Service -Name sshd -StartupType 'Automatic'

# Start the OpenSSH Server
Start-Service sshd

# Disable Windows Defender Firewall for the private network profile
Set-NetFirewallProfile -Profile Private -Enabled False

# Disable Windows Defender Firewall for the public network profile
Set-NetFirewallProfile -Profile Public -Enabled False

# Update sshd_config
@"
Match Group administrators
       AuthorizedKeysFile .ssh/authorized_keys
PubkeyAuthentication yes
PasswordAuthentication no
"@ | Set-Content -Path 'C:\\ProgramData\\ssh\\sshd_config' -Force

# Create .ssh folder and authorized_keys file
New-Item -Path 'C:\\ProgramData\\ssh\\.ssh' -ItemType Directory
Set-Content -Path 'C:\\ProgramData\\ssh\\.ssh\\authorized_keys' -Value 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCq1I/emKCK9fD0k8LwyAmPCp14XsgPn3d1ODzTfzch9qpsROFvT5Z/SvChu0Uaix7fnM1Ce9binkJbebHA/XEVdqKbadHiMm0HeLQTIVorG8Gfppt8fFFNXNmf53/HsQsyq6MgHYPEGeqQpaPQSgzbzz/A6uOkMR3GDxeK0mW9G0J0TOKjJTDQJqhMgpezURFar9L29tQEs9jfwmj+sN0hVycXXfjRQ97YdwjxAycvCzHawrqhL1b6t1hG5u7DgsEzx5dUJMuffgDhzCOr9Dht/Ry6Z7iEd2ySKJeajbM91/sOj/vpQOciz7dr9Yu8VWrBwGooHlOP5bkg2iYt9Lwj interinstance'

New-Item -Path 'C:\\Users\\Administrator\\.ssh' -ItemType Directory
Set-Content -Path 'C:\\Users\\Administrator\\.ssh\\authorized_keys' -Value 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCq1I/emKCK9fD0k8LwyAmPCp14XsgPn3d1ODzTfzch9qpsROFvT5Z/SvChu0Uaix7fnM1Ce9binkJbebHA/XEVdqKbadHiMm0HeLQTIVorG8Gfppt8fFFNXNmf53/HsQsyq6MgHYPEGeqQpaPQSgzbzz/A6uOkMR3GDxeK0mW9G0J0TOKjJTDQJqhMgpezURFar9L29tQEs9jfwmj+sN0hVycXXfjRQ97YdwjxAycvCzHawrqhL1b6t1hG5u7DgsEzx5dUJMuffgDhzCOr9Dht/Ry6Z7iEd2ySKJeajbM91/sOj/vpQOciz7dr9Yu8VWrBwGooHlOP5bkg2iYt9Lwj interinstance'


# Restart SSH service
Restart-Service sshd

# Create directory structure and files
New-Item -Path 'C:\\Users\\Administrator\\Desktop\\Approved' -ItemType Directory
New-Item -Path 'C:\\Users\\Administrator\\Desktop\\Approved\\20240119' -ItemType Directory
Set-Content -Path 'C:\\Users\\Administrator\\Desktop\\Approved\\20240119\\pks1.js' -Value 'const version = "This is version 1.14"'
Set-Content -Path 'C:\\Users\\Administrator\\Desktop\\Approved\\20240119\\pks2.js' -Value 'const version = "This is version 1.14"'
</powershell>
EOF

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

  user_data = <<-EOF
              #!/bin/bash

              # Create a destination directory for files
              mkdir -p /home/ec2-user/live_files/JS

              # Add interinstance public key to authorized_keys
              echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCq1I/emKCK9fD0k8LwyAmPCp14XsgPn3d1ODzTfzch9qpsROFvT5Z/SvChu0Uaix7fnM1Ce9binkJbebHA/XEVdqKbadHiMm0HeLQTIVorG8Gfppt8fFFNXNmf53/HsQsyq6MgHYPEGeqQpaPQSgzbzz/A6uOkMR3GDxeK0mW9G0J0TOKjJTDQJqhMgpezURFar9L29tQEs9jfwmj+sN0hVycXXfjRQ97YdwjxAycvCzHawrqhL1b6t1hG5u7DgsEzx5dUJMuffgDhzCOr9Dht/Ry6Z7iEd2ySKJeajbM91/sOj/vpQOciz7dr9Yu8VWrBwGooHlOP5bkg2iYt9Lwj interinstance' >> /root/.ssh/authorized_keys
              EOF
  
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

  user_data = <<-EOF
              #!/bin/bash
              # Add Jenkins repo
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

              # Add the key
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              # Install Java
              sudo yum install java -y

              # Install Git
              sudo yum install git -y

              # Install Jenkins
              sudo yum install jenkins -y

              # start Jenkins automatically on system boot 
              sudo systemctl enable jenkins

              # start Jenkins service
              sudo systemctl start jenkins

              # Create A4L key file with specified content
              echo '-----BEGIN RSA PRIVATE KEY-----
              MIIEpAIBAAKCAQEAptRorQhhNF4O4b6XEs6uZsLSZkaA5HCfvLCPYDg1gIfbvgIM
              xwXbZ37ZoNRsJi0MBpyWrxkOOvznaIlBK10hRu70+kjImHqG3aLf9kVzcoXtk1w1
              nhgP73UXFA4E6mURLh5joYBWqPZj9YEQ5gq77MzoRmmDqcUFomGqI48JXgqvCiD5
              zMHmIbkJ+7f4viKihgSDGdfUN/Q8D66oi/8B1UTd5NuOgH/M8PcX7XrDukce6PCc
              Q5PxiuIlJ7+7wYuKaAs9A4B0BFc3NZrF2xEAx3J6wXj0A5M9hKnm2mE+H6R3u579
              fMhhDmrjhliNDwxytlsoA7pJtbS+428Q5O4b9wIDAQABAoIBAHob5NYp2QQ8iEYB
              e5B/iTWcCeZkWnlaWgEBdqAl5DtEtblYxMNz7QjO1zoZ4WL7+95nBP/6pejVLgfc
              1r+HthC2XMdJONIqdMaLLcSTRxIfJyqCBpjF4fwSRycdr8lk2nNYOPJ//m5Dkhyj
              MJxAZRbJUIYhOwarOBmHxMGsM14J37ia9VIgTBLOgtyvMFVcQS3+HB7eql0E2s9z
              F+gnF31lxP3uZIVpjyYMIJ30AlPpe4SSVhMtv3B05NCQ8PROm4drmeq798zPQsQT
              SuUr79mB37WiOq8dSrrdMr6F/nqUoSJAkjz0+JapD2lJ47K0ksB1ALgobBfgXbzG
              hErsYFkCgYEA8TLuoTgiPBeD8cSi3+9teyqcZOLR6HUBFIp1j6AaAqeE+FLxCb49
              cbPpvwfwR4LZk9akKGi3ZDxmiIMAG9HoOGbJ3XwQ8h5v5HngMA87QvpI4XTZ336s
              fgTNMtG+6Jclp1/LMhG92o4KiZWujvwIeER1br9iV25OhAlIkNyS4s0CgYEAsREw
              FWfzmD28eXX/WBaK+shvgkTcz3vN1c6t0k3K2/FTP557blyEtf90G9aOqZRectOB
              whmcwhYTn49wqLKf+ZyWRNPM2EfGRPkqYVKRc60vnLpnliykTlOt5tt8gcsaZ2ag
              DUmFCfg8q1L6AcOfyHy2Aw7Jx1D0fpdVIe6j4dMCgYEAheulm1Yzi/HyjLaFSJkD
              zLMoCsv1iIAOjX0jMQ/P4VFp/wbuVl6OdydRzYN24f3BGNjAZL9ftAPlWj6CPPAb
              Y9WOl69fKU/FCLKyy3xphxK4jJX4sqL+2ymHVYQn37Ssb3Y8uBwpscPUDfhR54oA
              meZI3ajdzXWtmpoc9HHEDLECgYB247eJZ/bjrfAzDcuZdelzYcmdimdI2TPn75I+
              twUSkQL4oIz4GR7ypMdtOa8opfqU1vc1QMVEfFZIuKNIYkeP7lfndt8ACZFTFooi
              NrJ7HTnu3ipXZzobbYxCifUboSflbb7hrQ+rFgaGcnxzWsqab0I242MQdYb0yN/c
              nMNlCQKBgQCOv4H52xkJY42AWfaON8bK+OKGhyoy7gBiu/yQRkylZOrCbn48rdg7
              4HC+++1VN9WG6akk077HqZgEH2512k5i5pF33XKyyusVAO3YFm8mh7ZlqLl/eO4S
              xLqNd9DiLGk+b6sm3NqDBMeVTnIBn1JX28FXMz9EzSSz5KscxS+omA==
              -----END RSA PRIVATE KEY-----' | tee /home/ec2-user/.ssh/A4L.pem > /dev/null

              # Give Jenkins key ownership and permissions
              chown jenkins:jenkins /var/lib/jenkins/secrets/interinstance
              chmod 600 /var/lib/jenkins/secrets/interinstance

              # Add known_hosts and give permissions to Jenkins
              mkdir /var/lib/jenkins/.ssh
              touch known_hosts
              chown jenkins:jenkins /var/lib/jenkins/.ssh/known_hosts
              chmod 600 /var/lib/jenkins/.ssh/known_hosts
              EOF

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