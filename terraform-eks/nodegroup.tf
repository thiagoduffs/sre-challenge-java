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