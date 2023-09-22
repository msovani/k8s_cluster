# Terraform Settings Block
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "~> 3.21" # Optional but recommended in production
    }
  }
}

locals {
  ami                        = "ami-053b0d53c279acc90"
  node_instance_type         = "t3.medium"
  control_pane_instance_type = "t3.medium"
  node_count                 = 1
  home_ip                    = ["72.68.111.18/32"] # put your own ip here
  kubernetes_version         = "1.27.1-00"
  kubernetes_short_version   = "1.27.1"
}

# Provider Block
provider "aws" {
  profile = "default" # AWS Credentials Profile configured on your local desktop terminal  $HOME/.aws/credentials
  region  = "us-east-1"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "deployer-key"
  public_key = "<<Put your own ssh public key here>>"
}
resource "aws_security_group" "allow_ssh_from_home" {
  name        = "k8s-dev-labs"
  description = "Allow inbound ssh and all connections from nodes"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.home_ip
  }
  ingress {
    description = "Allow from this SG"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
# Resource Block
resource "aws_instance" "kube-master" {
  ami             = local.ami
  instance_type   = local.control_pane_instance_type
  key_name        = aws_key_pair.terraform_key.key_name
  security_groups = [aws_security_group.allow_ssh_from_home.name]
  user_data       = templatefile("master-init.sh", { "kubernetes_version" : local.kubernetes_version, "kubernetes_short_version" : local.kubernetes_short_version })
  tags = {
    Name = "kube-control-plane"
  }
}
output "Master_node_ip" {
  value = aws_instance.kube-master.public_ip
}


resource "aws_instance" "kube-node1" {
  ami             = local.ami
  count           = local.node_count
  instance_type   = local.node_instance_type
  key_name        = aws_key_pair.terraform_key.key_name
  security_groups = [aws_security_group.allow_ssh_from_home.name]
  user_data       = templatefile("node-init.sh", { "nodeindex" : count.index, "kubernetes_version" : local.kubernetes_version })
  tags = {
    Name = "kube-node-${count.index}"
  }
}

output "node_ip" {
  value = aws_instance.kube-node1[*].public_ip
}