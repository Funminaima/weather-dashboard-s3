resource "aws_vpc" "python-weather-dashboard-vpc"{
    cidr_block = "10.0.0.0/16"
    depends_on = [ docker_registry_image.this ]
}

//create two public subnet and two private subnet
resource "aws_subnet" "public-1" {
  vpc_id = aws_vpc.python-weather-dashboard-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "public-subnet-1 | us-east-1a"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id = aws_vpc.python-weather-dashboard-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "public-subnet-2 | us-east-1b"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id = aws_vpc.python-weather-dashboard-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "private-subnet-1 | us-east-1a"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id = aws_vpc.python-weather-dashboard-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "private-subnet-2 | us-east-1b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id= aws_vpc.python-weather-dashboard-vpc.id

  tags={
    "Name"= "weather-dashboard-igw"
  }
}

resource "aws_route_table" "rt" {
    vpc_id=aws_vpc.python-weather-dashboard-vpc.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

     tags={
    "Name"= "weather-dashboard-rt"
  }
  
}

# attach your public subnet to the rt 
resource "aws_route_table_association" "public_subnet-asso1" {
  subnet_id = aws_subnet.public-1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "public_subnet-asso2" {
  subnet_id = aws_subnet.public-2.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "egress-only" {
  # ... other configuration ...
    name        = "egress-all"
  description = "Allow all outbound traffic"
   vpc_id=aws_vpc.python-weather-dashboard-vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ingress" {
  # ... other configuration ...
    name        = "ingress-all"
  description = "Allow all inbound traffic"
   vpc_id=aws_vpc.python-weather-dashboard-vpc.id

  ingress {
    from_port        = 5000
    to_port          = 5000
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
}

resource "aws_security_group" "ingress-http" {
  # ... other configuration ...
    name        = "ingress-http"
  description = "Allow all http inbound traffic"
   vpc_id=aws_vpc.python-weather-dashboard-vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
}
