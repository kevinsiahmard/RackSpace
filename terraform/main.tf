
########## RackSpace Assessment Task ###########
#
#  this script creates:
#         . one VPC
#         . two public subnets
#         . two private subnets
#         . four security groups
#         . two ec2 instances
#         . one mysql instance in AWS RDS
#         . one ELB
#         . one internet gateway
#


########## defining AWS as provider ##########
########## reading AWS credentials from terraform.tfvars file ##########
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


################ retreiving AZs info from region #######################
data "aws_availability_zones" "all" {}


############### creating new VPC ###############
resource "aws_vpc" "myapp" {
     cidr_block = "10.100.0.0/16"
tags = {
   Name = "myapp-vpc"
}
}


################  create public subnets ##########
resource "aws_subnet" "public_2a" {
    vpc_id = aws_vpc.myapp.id
    cidr_block = "10.100.0.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-2a"

    tags = {
        Name = "Myapp Public 2A"
    }
}

resource "aws_subnet" "public_2b" {
    vpc_id = aws_vpc.myapp.id
    cidr_block = "10.100.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-2b"

    tags = {
        Name = "Myapp Public 2B"
    }
}

#############  create private subnets ###########
resource "aws_subnet" "private_2a" {
    vpc_id = aws_vpc.myapp.id
    cidr_block = "10.100.3.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-2a"

    tags = {
        Name = "Myapp Private 2A"
    }
}

resource "aws_subnet" "private_2b" {
    vpc_id = aws_vpc.myapp.id
    cidr_block = "10.100.4.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-2b"

    tags = {
        Name = "Myapp Private 2B"
    }
}


############# create a internet gateway and link to VPC ###########

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp.id

    tags = {
        Name = "myapp-igw"
    }
}


################  create route from public subnets to internet through IG ################
resource "aws_route_table" "myapp-public-crt" {
    vpc_id = aws_vpc.myapp.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    
    tags = {
        Name = "myapp-public-crt"
    }
}


resource "aws_route_table_association" "myapp-crta-public_2a-subnet"{
    subnet_id = aws_subnet.public_2a.id
    route_table_id = aws_route_table.myapp-public-crt.id
}



resource "aws_route_table_association" "myapp-crta-public_2b-subnet"{
    subnet_id = aws_subnet.public_2b.id
    route_table_id = aws_route_table.myapp-public-crt.id

}



################  defining security groups #######################

resource "aws_security_group" "allow_ssh" {
  name = "allow_all"
  description = "Allow inbound SSH traffic from my IP"
  vpc_id = aws_vpc.myapp.id

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow SSH"
  }
}


resource "aws_security_group" "web_server" {
  name = "web server"
  description = "Allow HTTP and HTTPS traffic in, browser access out."
  vpc_id = aws_vpc.myapp.id

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "myapp_mysql_rds" {
  name = "mysql server"
  description = "Allow access to MySQL RDS"
  vpc_id = aws_vpc.myapp.id

  ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["${aws_instance.web01.private_ip}/32","${aws_instance.web02.private_ip}/32"]
  }

  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  vpc_id = aws_vpc.myapp.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

######################## create ec2 instances #################################

resource "aws_instance" "web01" {
    ami = "ami-00bf61217e296b409"
    instance_type = "t2.nano"
    subnet_id = aws_subnet.public_2a.id
    vpc_security_group_ids = ["${aws_security_group.web_server.id}","${aws_security_group.allow_ssh.id}"]
    key_name = "nephub"
    tags = {
        Name = "web01"
    }
}

resource "aws_instance" "web02" {
    ami = "ami-00bf61217e296b409"
    instance_type = "t2.nano"
    subnet_id = aws_subnet.public_2b.id
    vpc_security_group_ids = ["${aws_security_group.web_server.id}","${aws_security_group.allow_ssh.id}"]
    key_name = "nephub"
    tags = {
        Name = "web02"
    }
}


############  create ELB ###########################


resource "aws_elb" "web-elb" {
  name = "web-elb"
  subnets = [aws_subnet.public_2a.id, aws_subnet.public_2b.id] 
  security_groups = [aws_security_group.elb.id]  
listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }


  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  instances = [aws_instance.web01.id, aws_instance.web02.id]

  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags = {
    Name = "Web ELB"
  }
}


####################  create mysql instace as RDS ##############################



resource "aws_db_subnet_group" "myapp-db" {
    name = "db subnet group"
    description = "Our main group of subnets"
    subnet_ids = ["${aws_subnet.private_2a.id}", "${aws_subnet.private_2b.id}"]
    tags = {
        Name = "MyApp DB subnet group"
    }
}

resource "aws_db_instance" "web-rds-01" {
    identifier = "myappdb-rds"
    allocated_storage = 10
    engine = "mysql"
    instance_class = "db.t2.micro"
    name = "myappdb"
    username = var.db_root_user 
    password = var.db_root_pass
    vpc_security_group_ids = ["${aws_security_group.myapp_mysql_rds.id}"]
    db_subnet_group_name = aws_db_subnet_group.myapp-db.id
    skip_final_snapshot = "true"

}


