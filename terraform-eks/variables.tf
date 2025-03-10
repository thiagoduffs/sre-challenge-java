variable "region" {
  description = "Região AWS"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  default     = "sre-challenge-eks"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDRs para as subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "github_token" {
  description = "Token de acesso ao GitHub"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "Tipo da instância dos nodes"
  type        = string
  default     = "t3.micro"  # Mantendo dentro do Free Tier
}

variable "github_owner" {
  description = "Nome do dono do repositório no GitHub (usuário ou organização)"
  type        = string
}

variable "connection_arn" {
  description = "ARN da conexão CodeStar com o GitHub"
  type        = string
}