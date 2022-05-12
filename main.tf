# Creating AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Creating AWS EC2-Instance
resource "aws_instance" "VM-01" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name      = "SSH-Key"
  tags = {
    Name = "vsftpd"
  }
}

resource "aws_instance" "VM-02" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name      = "SSH-Key"
  tags = {
    Name = "vsftp-client"
  }
}

# Creating EBS Volumes
resource "aws_ebs_volume" "EBS-1" {
  availability_zone = "us-east-1a"
  size              = 1
  tags = {
    Name = "EBS-1"
  }
}

resource "aws_ebs_volume" "EBS-2" {
  availability_zone = "us-east-1a"
  size              = 1
  tags = {
    Name = "EBS-2"
  }
}

#Generatong and creating Key Pair for SSH
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "SSH-Key" {
  key_name   = "SSH-Key" # Create a "Key" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh
  provisioner "local-exec" { # Create a "Key.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./SSH-Key.pem"
  }
}

#Output vaules
output "instance_ip_addr" {
  value       = aws_instance.VM-01.public_ip
  description = "The public IP address of the VM-1 instance."
}

output "instance_ip_addr_2" {
  value       = aws_instance.VM-02.public_ip
  description = "The public IP address of the VM-2 instance."
}
