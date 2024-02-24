terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.13.0"
    }
  }
  required_version = ">= 1.5.0"
}


provider "aws" {
  region = local.region-name
  profile= "test"
}

resource "aws_vpc" "my-vpc-1" {
    cidr_block = "10.0.0.0/16"
    tags={
        Name = "MY-PUBLIC-VPC"
    }
    
    }
resource "aws_subnet" "public-sub" {
    vpc_id = aws_vpc.my-vpc-1.id
    cidr_block = local.cidr_block
    availability_zone = local.az
    map_public_ip_on_launch = true

    tags = {
        Name = "public-Access"
    }

     
}

resource "aws_internet_gateway" "igw-pub" {
    vpc_id = aws_vpc.my-vpc-1.id
    tags={
        Name = "public-gw"
    }
    
  
}

resource "aws_route_table" "route-assoc" {
    vpc_id = aws_vpc.my-vpc-1.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw-pub.id
    }
  
}

resource "aws_route_table_association" "subnet-assoc" {
    subnet_id = aws_subnet.public-sub.id
    route_table_id = aws_route_table.route-assoc.id
  
}

// Security Group creation with inbound and outbound traffic rules
resource "aws_security_group" "public-access" {
  vpc_id = aws_vpc.my-vpc-1.id
  name = "pubic-SG"
  description = "Allow All Traffic"
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
}


resource "aws_security_group_rule" "rule-http" {
    type = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp" 
    security_group_id = aws_security_group.public-access.id
    cidr_blocks = ["0.0.0.0/0"]
  
}

/*
resource "aws_security_group_rule" "rule-dbaccess" {
    type = "dbaccess"
    from_port = 3306
    to_port = 3306
    protocol = "tcp" 
    security_group_id = "aws_security_group.public-access.id"
    cidr_blocks = ["0.0.0.0/0"]
  
}
resource "aws_security_group_rule" "rule-ssh" {
    type = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp" 
    security_group_id = aws_security_group.public-access.id
    cidr_blocks = ["0.0.0.0/0"]
  
}

resource "aws_security_group_rule" "rule-hhtps" {
    type = "https"
    from_port = 443
    to_port = 443
    protocol = "tcp" 
    security_group_id = aws_security_group.public-access.id
    cidr_blocks = ["0.0.0.0/0"]
  
}
*/

resource "aws_instance" "project" {
    count = 3
    ami = local.ami-id
    subnet_id = aws_subnet.public-sub.id
    vpc_security_group_ids = [aws_security_group.public-access.id]
    instance_type = local.type
    key_name = "tfkey"
    root_block_device {
       volume_type = "gp2"
       volume_size = 10
       delete_on_termination = true
    }
    tags = {
      Name = "Myproject${count.index}"
    }
   
  
}

output "vpc_name" {
  value = aws_vpc.my-vpc-1.tags
  
}

output "vpc_cidr" {

    value = aws_vpc.my-vpc-1.cidr_block
  
}

output "instances-1" {

    value = aws_instance.project[0].tags
  
}
output "instances-2" {

    value = aws_instance.project[2].tags
  
}






