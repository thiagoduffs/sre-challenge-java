resource "aws_iam_role" "codepipeline_eks_role" {
  name = "codepipeline-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eks_codepipeline_policy" {
  name        = "eks-codepipeline-policy"
  description = "Permite que o CodePipeline se conecte ao EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_codepipeline_attachment" {
  role       = aws_iam_role.codepipeline_eks_role.name
  policy_arn = aws_iam_policy.eks_codepipeline_policy.arn
}
