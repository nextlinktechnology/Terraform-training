resource "aws_security_group" "sg" {
  name        = "allow_circle"
  description = "Allow circle inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["220.135.202.135/32", "211.75.165.158/32"]
  }

  tags = {
    Name = "allow_circle"
  }
}
