resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.elb_sg.id]  # Permite apenas do ELB
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.elb_sg.id]  # Permite apenas do ELB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego de saída para qualquer destino
  }

  tags = {
    Name = "eks-sg"
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "elb-sg"
  description = "Security group para o Load Balancer do EKS"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego HTTP público
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego HTTPS público
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permite saída para qualquer destino
  }

  tags = {
    Name = "elb-sg"
  }
}
