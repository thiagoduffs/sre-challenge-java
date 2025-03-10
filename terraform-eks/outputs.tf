output "cluster_name" {
  description = "Nome do cluster criado"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "node_group_name" {
  description = "Nome do grupo de nós criado"
  value       = aws_eks_node_group.eks_nodes.node_group_name
}
