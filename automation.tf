provider "aws" {
  region="us-east-1"
}

# VPC
resource "aws_vpc" "task_4_vpc" {
  cidr_block = "192.168.0.0/16"
}


# Public subnets
resource "aws_subnet" "task_4_public_subnet_1" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"
  cidr_block = "192.168.0.0/24"
  
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "task_4_public_subnet_1"
  }
}

resource "aws_subnet" "task_4_public_subnet_2" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"
  cidr_block = "192.168.1.0/24"

  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "task_4_public_subnet_2"
  }
}
# end


# Private subnets
resource "aws_subnet" "task_4_private_subnet_1" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"
  cidr_block = "192.168.2.0/24"

  availability_zone = "us-east-1a"

  tags = {
    Name = "task_4_private_subnet_1"
  }
}

resource "aws_subnet" "task_4_private_subnet_2" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"
  cidr_block = "192.168.3.0/24"

  availability_zone = "us-east-1b"

  tags = {
    Name = "task_4_private_subnet_2"
  }
}
# end

# aws security group
resource "aws_security_group" "task_4_project_sg_1" {
  name        = "task_4_project_sg_1"
  description = "Allow 22 and 80 from all internet inbound traffic"
  vpc_id     = "${aws_vpc.task_4_vpc.id}"

  ingress {
    from_port = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
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
    Name = "task_4_project_sg_1"
  }
}
#  end


# Internet Gateway
resource "aws_internet_gateway" "task_4_IG" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"

  tags = {
    Name = "task_4_IG"
  }
}
#end


# Route Tables
resource "aws_route_table" "task_4_public_RT" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.task_4_IG.id}"
  }

  tags = {
    Name = "task_4_public_RT"
  }
}

resource "aws_route_table" "task_4_private_RT" {
  vpc_id     = "${aws_vpc.task_4_vpc.id}"
  
  route {
      cidr_block = "0.0.0.0/0"
      instance_id = "${aws_instance.task_4_nat_instance.id}"
    }
  tags = {
    Name = "task_4_private_RT"
  }
}
# end


# Route table associations
resource "aws_route_table_association" "public_rt_association_1" {
  subnet_id = "${aws_subnet.task_4_public_subnet_1.id}"
  route_table_id = "${aws_route_table.task_4_public_RT.id}"
}
resource "aws_route_table_association" "public_rt_association_2" {
  subnet_id = "${aws_subnet.task_4_public_subnet_2.id}"
  route_table_id = "${aws_route_table.task_4_public_RT.id}"
}

resource "aws_route_table_association" "private_rt_association_1" {
  subnet_id = "${aws_subnet.task_4_private_subnet_1.id}"
  route_table_id = "${aws_route_table.task_4_private_RT.id}"
}
resource "aws_route_table_association" "private_rt_association_2" {
  subnet_id = "${aws_subnet.task_4_private_subnet_2.id}"
  route_table_id = "${aws_route_table.task_4_private_RT.id}"
}
# end

# Key pair
resource "aws_key_pair" "task-4-project-key-pair" {
  key_name   = "task-4-project-key-pair"
  public_key = "(Fill with your own key)"
}
# end


# Launch Template
resource "aws_launch_template" "task-4-LT" {
  name = "task-4-LT"

  image_id = "ami-0323c3dd2da7fb37d"

  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.task_4_project_sg_1.id}"]
  key_name = "task-4-project-key-pair"

  user_data = "${base64encode(file("./automation.sh"))}"
}
# end 


# Target Group 
resource "aws_lb_target_group" "task_4_TG" {
  name     = "task-4-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.task_4_vpc.id}"
}
# End 

# Load Balancer
resource "aws_lb" "task_4_lb" {
  name               = "task-4-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.task_4_project_sg_1.id}"]
  subnets            = ["${aws_subnet.task_4_public_subnet_1.id}", "${aws_subnet.task_4_public_subnet_2.id}"]

  # enable_deletion_protection = true

  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name = "task_4_lb"
  }
}
# End

# Aws lb listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.task_4_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.task_4_TG.arn}"
  }
}
# End


# Autoscaling group
resource "aws_autoscaling_group" "task_4_ASG" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = ["${aws_subnet.task_4_private_subnet_1.id}", "${aws_subnet.task_4_private_subnet_2.id}"]
  target_group_arns = ["${aws_lb_target_group.task_4_TG.arn}"]

  launch_template {
    id      = "${aws_launch_template.task-4-LT.id}"
    version = "$Latest"
  }
}
# End

# Nat instance
resource "aws_instance" "task_4_nat_instance" {
  ami           = "ami-00a9d4a05375b2763"
  instance_type = "t2.micro"
  source_dest_check=false
  vpc_security_group_ids = ["${aws_security_group.task_4_NATSG.id}"]
  subnet_id = "${aws_subnet.task_4_public_subnet_1.id}"
  associate_public_ip_address = true

  tags = {
    Name = "task_4_nat_instance"
  }
}
# End

# aws NATSG security group
resource "aws_security_group" "task_4_NATSG" {
  name        = "task_4_NATSG"
  description = "task_4_NATSG"
  vpc_id     = "${aws_vpc.task_4_vpc.id}"

  ingress {
    from_port = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port     = 443
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
    Name = "task_4_NATSG"
  }
}
#  end
