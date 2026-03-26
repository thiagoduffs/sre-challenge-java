# POC - Importacao de Infraestrutura AWS para Terraform

## Pre-requisitos

- Terraform >= 1.11.0
- AWS CLI v2 configurado com credenciais de leitura
- Bucket S3 para state (veja bootstrap abaixo)

## Bootstrap: Criar Bucket S3 para State

```bash
export BUCKET_NAME="<EMPRESA>-terraform-state-<ACCOUNT_ID>"

aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1

aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}, "BucketKeyEnabled": true}]
  }'

aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## Quick Start

```bash
# 1. Editar backend.tf com o nome real do bucket e projeto
vi environments/prod/backend.tf

# 2. Copiar e preencher variaveis
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
vi environments/prod/terraform.tfvars

# 3. Inventariar recursos AWS
cd ../scripts/inventory
chmod +x *.sh
./run_all.sh

# 4. Gerar import blocks a partir do inventario
cd ../helpers
chmod +x generate_import_blocks.sh
./generate_import_blocks.sh glue ../inventory/output/glue.txt > ../../poc/environments/prod/imports/glue.tf
./generate_import_blocks.sh ec2 ../inventory/output/ec2.txt > ../../poc/environments/prod/imports/ec2.tf
./generate_import_blocks.sh s3 ../inventory/output/s3.txt > ../../poc/environments/prod/imports/s3.tf
./generate_import_blocks.sh vpc ../inventory/output/vpc.txt > ../../poc/environments/prod/imports/vpc.tf

# 5. Revisar os import blocks gerados
vi ../../poc/environments/prod/imports/*.tf

# 6. Inicializar e gerar configuracao
cd ../../poc/environments/prod
terraform init
terraform plan -generate-config-out=generated_resources.tf

# 7. Revisar, refatorar o codigo gerado, e validar
terraform plan   # deve mostrar zero changes

# 8. Aplicar (state vai para S3 automaticamente)
terraform apply
```
