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
