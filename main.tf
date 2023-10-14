terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region  = "us-east-2"
  version = "~> 2.46"
}

//HTTP server --> SG
//SG --> 80 TCP, 22 TCP, CIDR ["0.0.0.0/0"]

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "web-public-subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "web-public-subnet1"
  }
}
resource "aws_subnet" "web-public-subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "web-public-subnet2"
  }
}
resource "aws_subnet" "app-private-subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "app-private-subnet2"
  }
}
resource "aws_subnet" "app-private-subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "app-private-subnet2"
  }
}
resource "aws_subnet" "db-private-subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"

  tags = {
    Name = "db-private-subnet1"
  }
}
resource "aws_subnet" "db-private-subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"

  tags = {
    Name = "db-private-subnet2"
  }
}

#Internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

#Route Table 

resource "aws_route_table" "web-route-table" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "web-route-table"
  }
}
# Create Web Subnet association with Web route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-public-subnet1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-public-subnet2.id
  route_table_id = aws_route_table.web-rt.id
}

#Create EC2 Instance (two webservers in sydney AZ's)
resource "aws_instance" "web-server-1" {
  ami                    = "ami-067d1e60475437da2"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-2a"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id              = aws_subnet.web-public-subnet1.id
  

  tags = {
    Name = "web-server-1"
  }

}

resource "aws_instance" "web-server-2" {
  ami                    = "ami-067d1e60475437da2"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-2b"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id              = aws_subnet.web-public-subnet2.id
  

  tags = {
    Name = "web-server-2"
  }

}

#Create EC2 Instance (two application servers in syney AZ's)

resource "aws_instance" "app-server-1" {
  ami                    = "ami-067d1e60475437da2"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-2a"
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  subnet_id              = aws_subnet.app-private-subnet1.id
 

  tags = {
    Name = "app-server-1"
  }

}

resource "aws_instance" "app-server-2" {
  ami                    = "ami-067d1e60475437da2"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-2b"
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  subnet_id              = aws_subnet.app-private-subnet2.id
  

  tags = {
    Name = "app-server-2"
  }

}

# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "web-sg"
  }
}

# Create Application Security Group

resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

# Create Database Security Groups

resource "aws_security_group" "database-sg" {
  name        = "Db-sg"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.database-sg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Db-sg"
  }
}

# Application load balancer and Target Group
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.web-public-subnet1.id, aws_subnet.web-public-subnet2.id]
}

resource "aws_lb_target_group" "alb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "alb1" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.web-server-1.id
  port             = 80

  depends_on = [
    aws_instance.web-server-1,
  ]
}
resource "aws_lb_target_group_attachment" "alb2" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.web-server-2.id
  port             = 80

  depends_on = [
    aws_instance.web-server-2,
  ]
}
resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}
# RDS Instance Creation
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20" 
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "mydb"
  username               = "username"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db-sg.id]
}

# Subnet Group association with the RDS
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.db-private-subnet1.id, aws_subnet.db-private-subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}
