#----------------------
# Creating AWS Provider
#----------------------
provider "aws" {
  region = "us-east-1"
}

#----------------------
# Creating AWS EC2-Instance
#----------------------
resource "aws_instance" "K8s-Master-01" {
  ami               = "ami-04505e74c0741db8d"
  instance_type     = "t2.medium"
  availability_zone = "us-east-1a"
  key_name          = "Key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic.id
  }

  # depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "K8s-Master-01"
  }

  user_data = file("kubeadm-master.sh")
}


resource "aws_instance" "K8s-Master-02" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2."
  availability_zone = "us-east-1b"
  key_name = "Keypair-1"
  # depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "K8s-Master-02"
  }
}

resource "aws_instance" "K8s-Worker-Node-01" {
  ami               = "ami-04505e74c0741db8d"
  instance_type     = "t2.medium"
  availability_zone = "us-east-1a"
  key_name          = "Key"
  # depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "K8s-Worker-Node-01"
  }

  user_data = file("kubeadm-worker.sh")
}


resource "aws_instance" "K8s-Node-02" {
  ami               = "ami-04505e74c0741db8d"
  instance_type     = "t2.medium"
  availability_zone = "us-east-1b"
  key_name          = "Key"
  # depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "K8s-Node-02"
  }
  user_data = file("kubeadm-worker.sh")
}
#----------------------
# Creating VPC
#----------------------
resource "aws_vpc" "vpc_1" {
  cidr_block = "10.0.0.0/23"

  tags = {
    Name = "vpc-1"
  }
}

#----------------------
# Creating Subnets
#----------------------
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet_1"
  }
}

# resource "aws_subnet" "subnet_2" {
#   vpc_id            = aws_vpc.vpc_1.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
#
#   tags = {
#     Name = "Subnet_2"
#   }
# }

#----------------------
# Creating Internet Gateway
#----------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "Internet Gateway"
  }
}

#----------------------
# Creating Route Tables
#----------------------
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route Table"
  }
}
#----------------------
# Creating Route Table Associations
#----------------------
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt.id
}

#----------------------
# Creating SG
#----------------------
resource "aws_security_group" "sg" {
  name        = "allow_traffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_traffic"
  }
}

#----------------------
# Creating Network Interface
#----------------------
# resource "aws_network_interface" "nic" {
#   subnet_id       = aws_subnet.subnet_1.id
#   private_ips     = ["10.0.0.50"]
#   security_groups = [aws_security_group.sg.id]
# }

#----------------------
# Creating EIP
#----------------------
# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.nic.id
#   associate_with_private_ip = "10.0.0.50"
#   depends_on                = [aws_internet_gateway.gw]
# }

#----------------------
# Creating Key Pair for SSH
#----------------------
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "key-pair" {
  key_name   = "Key" # Create a "Key" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create a "Key.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./Key.pem"
  }
}


output "instance_ip_addr" {
  value       = aws_instance.K8s-Master-01.public_ip
  description = "The public IP address of the VM-1 instance."
}

output "instance_ip_addr_2" {
  value       = aws_instance.K8s-Worker-Node-01.public_ip
  description = "The public IP address of the VM-2 instance."
}
