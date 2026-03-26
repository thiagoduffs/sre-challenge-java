variable "aws_region" {
  description = "Regiao AWS principal"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e nomeacao de recursos)"
  type        = string
}

variable "environment" {
  description = "Ambiente (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "team_name" {
  description = "Nome do time responsavel"
  type        = string
}

# Glue
variable "glue_database_name" {
  description = "Nome do Glue Catalog Database principal"
  type        = string
  default     = ""
}

variable "data_lake_bucket" {
  description = "Nome do bucket S3 do data lake"
  type        = string
  default     = ""
}

variable "glue_scripts_bucket" {
  description = "Nome do bucket S3 para scripts Glue"
  type        = string
  default     = ""
}

variable "glue_temp_bucket" {
  description = "Nome do bucket S3 temporario do Glue"
  type        = string
  default     = ""
}
