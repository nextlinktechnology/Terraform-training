data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  key_name          = "circle-sa-eu-west-3"
  availability_zone = "eu-west-3a"

  network_interface {
    network_interface_id = aws_network_interface.network.id
    device_index         = 0
  }

  root_block_device{
    volume_size = 10
  }

  tags = {
    Name = "Circle ec2"
  }
}

resource "aws_network_interface" "network" {
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "Circle network interface"
  }
}

resource "aws_eip" "ip" {
  instance = aws_instance.ec2.id
  tags = {
    Name = "Circle eip"
  }
}
