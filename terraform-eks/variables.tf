variable "cluster_name" {
  description = "Nome do cluster EKS"
  default     = "sre-challenge-eks"
}

variable "region" {
  description = "Região AWS"
  default     = "us-east-1"
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

variable "instance_type" {
  description = "Tipo da instância dos nodes"
  default     = "t3.micro"
}
