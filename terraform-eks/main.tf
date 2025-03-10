# Criar a VPC para o cluster EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

# Criar Subnets públicas para o EKS
resource "aws_subnet" "eks_subnets" {
  count = 2

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

# Criar Internet Gateway para permitir acesso externo
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

# Criar tabela de rotas para permitir saída pela Internet
resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-route-table"
  }
}

# Associar a tabela de rotas às subnets
resource "aws_route_table_association" "eks_route_assoc" {
  count = length(var.subnet_cidrs)

  subnet_id      = aws_subnet.eks_subnets[count.index].id
  route_table_id = aws_route_table.eks_route_table.id
}

# Criar Role para o Cluster EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Criar o Cluster EKS
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = aws_subnet.eks_subnets[*].id
    endpoint_public_access = true
  }

  tags = {}

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

# Criar Role para os Nodes do EKS
resource "aws_iam_role" "node_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permissões para os Nodes
resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "container_registry" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Criar Auto Scaling Group (ASG) e Node Group com 1 nó (Free Tier)
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.eks_subnets[*].id

  scaling_config {
    desired_size = 2  # Free Tier
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.instance_type]

  tags = {}

  depends_on = [aws_iam_role_policy_attachment.node_policy]
}

data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.eks_nodes.node_group_name]
  }
}

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

# Criar um Classic Load Balancer (ELB) no Free Tier
resource "aws_elb" "eks_elb" {
  name               = "eks-elb"
  internal           = false
  security_groups    = [aws_security_group.eks_sg.id]
  subnets           = aws_subnet.eks_subnets[*].id
  instances          = data.aws_instances.eks_nodes.ids  # Usa os nodes coletados dinamicamente

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port          = 80
    lb_protocol      = "HTTP"
  }

  health_check {
    target              = "HTTP:8080/" # Certifique-se de que o alvo está correto
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "eks-elb"
  }

  depends_on = [aws_eks_node_group.eks_nodes]  # Garante que os nodes sejam criados antes do ELB
}

# Security Group para o Load Balancer
resource "aws_security_group" "elb_sg" {
  name        = "elb-sg"
  description = "Security group para o Load Balancer do EKS"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego HTTP público (ajuste se necessário)
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
