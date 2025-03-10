resource "aws_codepipeline" "eks_pipeline" {
  name     = "eks-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_eks_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
    name             = "SourceAction"
    category         = "Source"
    owner            = "AWS"
    provider         = "CodeStarSourceConnection"
    version          = "1"
    output_artifacts = ["source_output"]

      configuration = {
      ConnectionArn = var.connection_arn
      FullRepositoryId = "99h58f2qe/sre-challenge"
      BranchName       = "develop"
      OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "DeployToEKS"
      category         = "Deploy"
      owner           = "AWS"
      provider        = "Kubernetes"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
      ClusterName  = var.cluster_name
      Namespace    = "default"
      RoleArn      = aws_iam_role.codepipeline_eks_role.arn
      ActionMode   = "APPLY"
      ManifestPath = "helm"  # Alterando para usar Helm diretamente
    }
  }
}
}
