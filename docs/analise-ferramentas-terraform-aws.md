# Importacao de Infraestrutura AWS para Terraform - Documentacao Tecnica

> **Versao:** 2.0 - Atualizada em Marco/2026
> **Contexto:** Documentacao revisada apos constatacao do arquivamento do Terraformer (proposta original).
> **Objetivo:** Definir a ferramenta e o processo para importar a infraestrutura AWS existente para Terraform, gerando codigo HCL e state remoto no S3.

---

## Sumario

1. [Contexto e Motivacao](#1-contexto-e-motivacao)
2. [Estudo das Ferramentas](#2-estudo-das-ferramentas)
3. [Decisao Tecnica: Terraform Nativo](#3-decisao-tecnica-terraform-nativo)
4. [Arquitetura da Solucao](#4-arquitetura-da-solucao)
5. [Guia da POC - Passo a Passo](#5-guia-da-poc---passo-a-passo)
6. [Exemplos Praticos por Servico AWS](#6-exemplos-praticos-por-servico-aws)
7. [Estrutura de Repositorio Sugerida](#7-estrutura-de-repositorio-sugerida)
8. [Scripts de Inventario AWS](#8-scripts-de-inventario-aws)
9. [Refatoracao com IA (Cursor Agent)](#9-refatoracao-com-ia-cursor-agent)
10. [Riscos e Mitigacoes](#10-riscos-e-mitigacoes)
11. [Criterios de Sucesso da POC](#11-criterios-de-sucesso-da-poc)
12. [Proximos Passos](#12-proximos-passos)

---

## 1. Contexto e Motivacao

### 1.1 Problema

A infraestrutura AWS da equipe foi provisionada manualmente (console/CLI) ou por processos nao versionados. Precisamos:

- Trazer essa infraestrutura existente para Terraform (Infrastructure as Code)
- Gerar o **state remoto** e armazena-lo no **S3**
- Produzir codigo HCL de qualidade que siga os padroes da equipe
- Cobrir servicos incluindo os mais especificos como **AWS Glue**

### 1.2 Proposta Original vs Atualizada

| Aspecto | Proposta Original | Proposta Atualizada |
|---------|-------------------|---------------------|
| **Ferramenta principal** | Terraformer (Google) | **Terraform Nativo (import block)** |
| **Motivo da mudanca** | - | Terraformer **arquivado em marco/2026**, repositorio read-only, dependencias de 2021, vulnerabilidades conhecidas |
| **Geracao de state** | Via Terraformer | Via `terraform apply` com backend S3 |
| **Geracao de codigo** | Via Terraformer | Via `terraform plan -generate-config-out=` |
| **Versao minima Terraform** | N/A | **>= 1.10** (recomendado >= 1.11 para locking nativo S3) |

---

## 2. Estudo das Ferramentas

### 2.1 Ferramentas Avaliadas e Descartadas

#### Terraformer (Google) - DESCARTADO

| Aspecto | Detalhe |
|---------|---------|
| **Status** | **ARQUIVADO em Marco/2026** - Repositorio read-only |
| **Ultima release** | v0.8.30 (Marco/2025) |
| **Problema critico** | Usa Terraform v0.12.31 internamente (versao de 2021). Multiplas CVEs nao corrigidas. Funcionalidades quebradas em diversos providers. Nao recebera mais patches. |
| **Veredicto** | **NAO USAR.** Adotar agora significa divida tecnica e risco de seguranca imediatos. |

> **Nota:** O Terraformer era a ferramenta proposta na versao original deste documento. Dado o arquivamento do projeto, toda a estrategia foi revisada.

#### aws2tf - DESCARTADO

| Aspecto | Detalhe |
|---------|---------|
| **Status** | Ativo (aws-samples no GitHub) |
| **Linguagem** | Python/Shell |
| **Problema** | Cobertura limitada de servicos. AWS Glue sem suporte completo. Codigo gerado exige muita refatoracao. |
| **Veredicto** | Viavel para servicos core, mas insuficiente para nossa cobertura (Glue). |

#### Former2 - DESCARTADO

| Aspecto | Detalhe |
|---------|---------|
| **Status** | Ativo |
| **Problema** | Exige browser com extensao. Credenciais passam pelo browser (risco). Nao gera state file. CLI experimental e limitada. |
| **Veredicto** | Inaceitavel para workflow SRE/DevOps. Sem automacao nem reproducibilidade. |

#### TerraCognita (Cycloid) - DESCARTADO

| Aspecto | Detalhe |
|---------|---------|
| **Status** | Baixa atividade - ultima release v0.8.4 (Maio/2024) |
| **Problema** | Manutencao muito baixa. Suporte parcial a Glue. Risco de seguir o caminho do Terraformer. |
| **Veredicto** | Risco moderado de abandono. Nao adotar como ferramenta principal. |

### 2.2 Matriz Comparativa

| Criterio | Terraformer | aws2tf | Former2 | TerraCognita | **Terraform Nativo** |
|----------|:-----------:|:------:|:-------:|:------------:|:-------------------:|
| Mantido ativamente | NAO | Sim | Sim | Baixa | **Sim (oficial)** |
| Gera .tf | Sim | Sim | Sim | Sim | **Sim** |
| Gera state | Sim | Sim | Nao | Sim | **Sim** |
| State direto no S3 | Nao | Parcial | Nao | Nao | **Sim** |
| Suporte AWS Glue completo | Sim* | Nao | Sim | Parcial | **Sim** |
| Qualidade do codigo | Media | Media | Baixa | Media | **Media-Alta** |
| Sem dependencia externa | Nao | Nao | Nao | Nao | **Sim** |
| Garantia de continuidade | Nao | Incerto | Incerto | Incerto | **Sim** |
| CI/CD compativel | Sim | Sim | Nao | Sim | **Sim** |
| Bulk import (for_each) | N/A | N/A | N/A | N/A | **Sim (>= 1.7)** |

*\*Terraformer suportava Glue mas com bugs conhecidos e sem correcoes futuras.*

---

## 3. Decisao Tecnica: Terraform Nativo

### 3.1 Ferramenta Escolhida

**Terraform Import Block** (nativo, disponivel desde Terraform 1.5) com **geracao automatica de configuracao** (`-generate-config-out`).

### 3.2 Justificativa

1. **Ferramenta oficial da HashiCorp** - Garantia de continuidade e evolucao
2. **Suporte completo** - Todo recurso que o AWS provider suporta pode ser importado (incluindo Glue)
3. **State remoto nativo** - Com backend S3 configurado, o state e persistido automaticamente no S3
4. **Sem dependencias externas** - So precisa do binario do Terraform
5. **Versionavel e auditavel** - Import blocks sao arquivos `.tf` normais, versionados no Git
6. **CI/CD ready** - Funciona em pipelines sem interacao manual
7. **Evolucao constante** - Terraform 1.7+ trouxe `for_each` para imports em massa; 1.11+ trouxe locking nativo no S3

### 3.3 Requisitos

| Requisito | Versao/Detalhe |
|-----------|----------------|
| **Terraform** | >= 1.11.0 (recomendado para locking nativo S3) |
| **AWS Provider** | >= 5.x (ultima major estavel) |
| **AWS CLI** | v2 (para scripts de inventario) |
| **Backend** | S3 com versionamento e encriptacao habilitados |
| **Permissoes** | IAM role/user com acesso de leitura a todos os servicos + escrita no bucket S3 |

---

## 4. Arquitetura da Solucao

### 4.1 Fluxo de Importacao

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FLUXO DE IMPORTACAO                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. INVENTARIO          2. IMPORT BLOCKS       3. GENERATE CONFIG   │
│  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐    │
│  │  AWS CLI      │──────>│  imports.tf   │──────>│ generated.tf │    │
│  │  Scripts      │       │  (declarativo)│       │ (automatico) │    │
│  └──────────────┘       └──────────────┘       └──────┬───────┘    │
│                                                        │            │
│  4. REFATORACAO          5. VALIDACAO          6. APPLY             │
│  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐    │
│  │ Cursor Agent  │──────>│ terraform     │──────>│ terraform    │    │
│  │ + Revisao     │       │ plan          │       │ apply        │    │
│  │   manual      │       │ (0 changes)   │       │              │    │
│  └──────────────┘       └──────────────┘       └──────┬───────┘    │
│                                                        │            │
│                                                        v            │
│                                                 ┌──────────────┐   │
│                                                 │ S3 Backend    │   │
│                                                 │ (state +      │   │
│                                                 │  .tflock)     │   │
│                                                 └──────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Componentes

| Componente | Descricao |
|------------|-----------|
| **Scripts de inventario** | Bash scripts usando AWS CLI v2 para listar IDs de recursos por servico |
| **Import blocks** | Arquivos `.tf` declarativos que mapeiam recurso AWS -> recurso Terraform |
| **Config generation** | Terraform gera automaticamente o HCL dos recursos importados |
| **Refatoracao** | Cursor Agent + revisao manual para adequar ao padrao da equipe |
| **Backend S3** | Bucket S3 versionado e encriptado com locking nativo (>= 1.11) |

---

## 5. Guia da POC - Passo a Passo

### Passo 1: Preparar o Bucket S3 para State

Antes de iniciar a importacao, crie o bucket S3 que armazenara o state. Este bucket **nao sera importado** - sera criado manualmente (ou via CloudFormation) pois e o "bootstrap" da infraestrutura Terraform.

```bash
# Criar bucket para state
aws s3api create-bucket \
  --bucket <EMPRESA>-terraform-state-<ACCOUNT_ID> \
  --region us-east-1

# Habilitar versionamento (obrigatorio)
aws s3api put-bucket-versioning \
  --bucket <EMPRESA>-terraform-state-<ACCOUNT_ID> \
  --versioning-configuration Status=Enabled

# Habilitar encriptacao padrao
aws s3api put-bucket-encryption \
  --bucket <EMPRESA>-terraform-state-<ACCOUNT_ID> \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

# Bloquear acesso publico
aws s3api put-public-access-block \
  --bucket <EMPRESA>-terraform-state-<ACCOUNT_ID> \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Passo 2: Configurar o Backend Terraform

```hcl
# backend.tf
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "<EMPRESA>-terraform-state-<ACCOUNT_ID>"
    key          = "<PROJETO>/<AMBIENTE>/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true   # Locking nativo S3 (>= Terraform 1.10, GA em 1.11)
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}
```

> **Nota sobre locking:** A partir do Terraform 1.11, o S3 suporta **locking nativo** usando um arquivo `.tflock` armazenado ao lado do state. Isso **elimina a necessidade de DynamoDB** para lock, simplificando a infra e reduzindo custos.

### Passo 3: Inicializar o Terraform

```bash
terraform init
```

O `init` vai configurar o backend S3. Neste ponto o state esta vazio - vamos populá-lo nos proximos passos.

### Passo 4: Inventariar os Recursos AWS

Execute os scripts de inventario (detalhados na [secao 8](#8-scripts-de-inventario-aws)) para obter os IDs de todos os recursos que serao importados.

```bash
# Tornar executavel e rodar
chmod +x scripts/inventory/*.sh
./scripts/inventory/run_all.sh > inventario.json
```

### Passo 5: Criar os Import Blocks

Para cada recurso identificado, crie um import block. Organize por servico em arquivos separados:

```hcl
# imports/glue.tf
import {
  to = aws_glue_catalog_database.meu_database
  id = "meu_database"
}

import {
  to = aws_glue_crawler.meu_crawler
  id = "meu_crawler"
}

import {
  to = aws_glue_job.meu_etl_job
  id = "meu_etl_job"
}
```

```hcl
# imports/ec2.tf
import {
  to = aws_instance.app_server
  id = "i-0abc123def456789"
}

import {
  to = aws_security_group.app_sg
  id = "sg-0abc123def456789"
}
```

```hcl
# imports/s3.tf

# Import em massa usando for_each (Terraform >= 1.7)
locals {
  buckets_to_import = {
    data_lake  = "empresa-data-lake-prod"
    logs       = "empresa-logs-prod"
    artifacts  = "empresa-artifacts-prod"
  }
}

import {
  for_each = local.buckets_to_import
  to       = aws_s3_bucket.this[each.key]
  id       = each.value
}
```

### Passo 6: Gerar Configuracao Automaticamente

```bash
terraform plan -generate-config-out=generated_resources.tf
```

Este comando:
1. Le os import blocks
2. Consulta a AWS para obter o estado atual de cada recurso
3. Gera automaticamente o arquivo `generated_resources.tf` com todo o HCL

### Passo 7: Revisar e Refatorar o Codigo Gerado

O codigo gerado pelo Terraform e funcional mas **nao segue padroes de equipe**. Nesta etapa:

1. **Revise o `generated_resources.tf`** - Remova atributos desnecessarios (IDs computados, ARNs, etc.)
2. **Organize em arquivos por servico** - Mova recursos de `generated_resources.tf` para arquivos dedicados (`ec2.tf`, `glue.tf`, `s3.tf`, etc.)
3. **Extraia variaveis** - Substitua valores hardcoded por `var.xxx`
4. **Aplique nomeacao padrao** - Renomeie recursos para seguir a convencao da equipe
5. **Use o Cursor Agent** para acelerar a refatoracao (veja [secao 9](#9-refatoracao-com-ia-cursor-agent))

### Passo 8: Validar

```bash
# O plan deve mostrar ZERO changes se o import foi correto
terraform plan
```

**Resultado esperado:**
```
No changes. Your infrastructure matches the configuration.
```

Se aparecerem changes, significa que o codigo gerado diverge da realidade. Ajuste o HCL ate o plan ficar limpo.

### Passo 9: Aplicar e Persistir o State

```bash
terraform apply
```

O state sera **automaticamente salvo no S3** com encriptacao e locking. Nao e necessario nenhum upload manual.

### Passo 10: Limpar Import Blocks

Apos a importacao bem-sucedida, **remova os arquivos de import blocks** (eles so sao necessarios durante o import):

```bash
rm -rf imports/
# ou mova para um diretorio de historico
mv imports/ .imports-done/
```

Commite a remocao:
```bash
git add -A && git commit -m "chore: remove import blocks apos importacao bem-sucedida"
```

---

## 6. Exemplos Praticos por Servico AWS

### 6.1 AWS Glue

O Glue e o servico mais "fora da curva" da nossa infra. Aqui estao os imports e exemplos de HCL esperado:

#### Import Blocks

```hcl
# imports/glue.tf

# Catalog Database
import {
  to = aws_glue_catalog_database.main
  id = "<ACCOUNT_ID>:nome_do_database"
}

# Crawlers
import {
  to = aws_glue_crawler.events
  id = "events-crawler"
}

# Jobs
import {
  to = aws_glue_job.etl_vendas
  id = "etl-vendas"
}

# Triggers
import {
  to = aws_glue_trigger.daily_etl
  id = "daily-etl-trigger"
}
```

#### Exemplo de HCL Gerado (apos refatoracao)

```hcl
# glue.tf

resource "aws_glue_catalog_database" "main" {
  name = var.glue_database_name

  tags = var.common_tags
}

resource "aws_glue_crawler" "events" {
  database_name = aws_glue_catalog_database.main.name
  name          = "${var.project_name}-events-crawler-${var.environment}"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${var.data_lake_bucket}/raw/events/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
    Version = 1
  })

  tags = var.common_tags
}

resource "aws_glue_job" "etl_vendas" {
  name              = "${var.project_name}-etl-vendas-${var.environment}"
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "4.0"
  max_retries       = 1
  timeout           = 2880
  number_of_workers = 2
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.glue_scripts_bucket}/jobs/etl_vendas.py"
    name            = "glueetl"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = ""
    "--TempDir"                          = "s3://${var.glue_temp_bucket}/temp/"
  }

  tags = var.common_tags
}

resource "aws_glue_trigger" "daily_etl" {
  name     = "${var.project_name}-daily-etl-${var.environment}"
  type     = "SCHEDULED"
  schedule = "cron(0 3 * * ? *)"

  actions {
    job_name = aws_glue_job.etl_vendas.name
  }

  tags = var.common_tags
}
```

### 6.2 EC2 + Security Groups + ALB

#### Import Blocks

```hcl
# imports/ec2.tf
import {
  to = aws_instance.app
  id = "i-0abc123def456789"
}

import {
  to = aws_security_group.app
  id = "sg-0abc123def456789"
}

import {
  to = aws_lb.app
  id = "arn:aws:elasticloadbalancing:us-east-1:<ACCOUNT_ID>:loadbalancer/app/app-alb/abc123"
}

import {
  to = aws_lb_target_group.app
  id = "arn:aws:elasticloadbalancing:us-east-1:<ACCOUNT_ID>:targetgroup/app-tg/abc123"
}

import {
  to = aws_lb_listener.https
  id = "arn:aws:elasticloadbalancing:us-east-1:<ACCOUNT_ID>:listener/app/app-alb/abc123/def456"
}
```

### 6.3 S3 (Bulk Import com for_each)

```hcl
# imports/s3.tf
locals {
  s3_buckets = {
    data_lake  = "empresa-data-lake-prod"
    logs       = "empresa-logs-prod"
    artifacts  = "empresa-artifacts-prod"
    scripts    = "empresa-glue-scripts-prod"
    temp       = "empresa-glue-temp-prod"
  }
}

import {
  for_each = local.s3_buckets
  to       = aws_s3_bucket.this[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "this" {
  for_each = local.s3_buckets
  bucket   = each.value
}
```

### 6.4 RDS

```hcl
# imports/rds.tf
import {
  to = aws_db_instance.main
  id = "nome-da-instancia-rds"
}

import {
  to = aws_db_subnet_group.main
  id = "nome-do-subnet-group"
}

import {
  to = aws_db_parameter_group.main
  id = "nome-do-parameter-group"
}
```

### 6.5 VPC e Networking

```hcl
# imports/vpc.tf
import {
  to = aws_vpc.main
  id = "vpc-0abc123def456789"
}

import {
  to = aws_subnet.private_a
  id = "subnet-0abc123"
}

import {
  to = aws_subnet.private_b
  id = "subnet-0def456"
}

import {
  to = aws_subnet.public_a
  id = "subnet-0ghi789"
}

import {
  to = aws_internet_gateway.main
  id = "igw-0abc123"
}

import {
  to = aws_nat_gateway.main
  id = "nat-0abc123"
}

import {
  to = aws_route_table.private
  id = "rtb-0abc123"
}

import {
  to = aws_route_table.public
  id = "rtb-0def456"
}
```

### 6.6 IAM

```hcl
# imports/iam.tf
import {
  to = aws_iam_role.glue_role
  id = "GlueServiceRole"
}

import {
  to = aws_iam_role_policy_attachment.glue_service
  id = "GlueServiceRole/arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

import {
  to = aws_iam_role.ec2_role
  id = "EC2AppRole"
}
```

### 6.7 Route53

```hcl
# imports/route53.tf
import {
  to = aws_route53_zone.main
  id = "Z0123456789ABCDEF"
}

import {
  to = aws_route53_record.app
  id = "Z0123456789ABCDEF_app.empresa.com.br_A"
}
```

### 6.8 CloudWatch

```hcl
# imports/cloudwatch.tf
import {
  to = aws_cloudwatch_log_group.app
  id = "/app/production"
}

import {
  to = aws_cloudwatch_metric_alarm.cpu_high
  id = "app-cpu-high-alarm"
}
```

---

## 7. Estrutura de Repositorio Sugerida

```
terraform-aws-infra/
├── README.md
├── environments/
│   ├── prod/
│   │   ├── backend.tf          # Backend S3 config (key unica por ambiente)
│   │   ├── provider.tf         # Provider config
│   │   ├── variables.tf        # Variaveis do ambiente
│   │   ├── terraform.tfvars    # Valores das variaveis (NAO versionar secrets)
│   │   ├── outputs.tf          # Outputs
│   │   ├── vpc.tf              # Recursos de rede
│   │   ├── ec2.tf              # Instancias e ASG
│   │   ├── alb.tf              # Load Balancers
│   │   ├── rds.tf              # Bancos de dados
│   │   ├── s3.tf               # Buckets
│   │   ├── iam.tf              # Roles e policies
│   │   ├── glue.tf             # AWS Glue (jobs, crawlers, databases)
│   │   ├── route53.tf          # DNS
│   │   ├── cloudwatch.tf       # Monitoramento e alarmes
│   │   └── imports/            # (temporario - remover apos import)
│   │       ├── glue.tf
│   │       ├── ec2.tf
│   │       ├── s3.tf
│   │       ├── vpc.tf
│   │       ├── iam.tf
│   │       └── ...
│   ├── staging/
│   │   └── ...                 # Mesma estrutura
│   └── dev/
│       └── ...                 # Mesma estrutura
├── modules/                    # (futuro - pos-importacao)
│   ├── glue-job/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2-app/
│   └── ...
├── scripts/
│   ├── inventory/              # Scripts de inventario AWS CLI
│   │   ├── run_all.sh
│   │   ├── glue.sh
│   │   ├── ec2.sh
│   │   ├── s3.sh
│   │   ├── vpc.sh
│   │   ├── rds.sh
│   │   ├── iam.sh
│   │   └── route53.sh
│   └── helpers/
│       └── generate_import_blocks.sh
├── .gitignore
└── .terraform.lock.hcl
```

### .gitignore Recomendado

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Arquivos gerados pelo import (commitar apos refatoracao)
generated_resources.tf

# Secrets
*.tfvars
!terraform.tfvars.example

# OS
.DS_Store
```

---

## 8. Scripts de Inventario AWS

Scripts para listar IDs de recursos existentes na AWS. Estes scripts alimentam a criacao dos import blocks.

### 8.1 Script Principal (run_all.sh)

```bash
#!/bin/bash
# scripts/inventory/run_all.sh
# Executa todos os scripts de inventario e gera um relatorio consolidado

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SCRIPTS_DIR}/output"

mkdir -p "$OUTPUT_DIR"

echo "=================================================="
echo " Inventario AWS - Regiao: $REGION"
echo " Data: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=================================================="

for script in "$SCRIPTS_DIR"/*.sh; do
  name=$(basename "$script" .sh)
  [ "$name" = "run_all" ] && continue

  echo ""
  echo "--- Inventariando: $name ---"
  bash "$script" "$REGION" 2>/dev/null | tee "$OUTPUT_DIR/${name}.txt" || echo "  WARN: Falha parcial em $name"
done

echo ""
echo "=================================================="
echo " Inventario completo. Resultados em: $OUTPUT_DIR/"
echo "=================================================="
```

### 8.2 Glue

```bash
#!/bin/bash
# scripts/inventory/glue.sh
REGION="${1:-us-east-1}"

echo "# AWS Glue - Catalog Databases"
aws glue get-databases --region "$REGION" \
  --query 'DatabaseList[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r db; do
  echo "  database: $db"
done

echo ""
echo "# AWS Glue - Crawlers"
aws glue get-crawlers --region "$REGION" \
  --query 'Crawlers[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  echo "  crawler: $name"
done

echo ""
echo "# AWS Glue - Jobs"
aws glue get-jobs --region "$REGION" \
  --query 'Jobs[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  echo "  job: $name"
done

echo ""
echo "# AWS Glue - Triggers"
aws glue get-triggers --region "$REGION" \
  --query 'Triggers[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  echo "  trigger: $name"
done
```

### 8.3 EC2

```bash
#!/bin/bash
# scripts/inventory/ec2.sh
REGION="${1:-us-east-1}"

echo "# EC2 Instances"
aws ec2 describe-instances --region "$REGION" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output text 2>/dev/null | while read -r id name state; do
  echo "  instance: $id  name=$name  state=$state"
done

echo ""
echo "# Security Groups"
aws ec2 describe-security-groups --region "$REGION" \
  --query 'SecurityGroups[].[GroupId,GroupName]' \
  --output text 2>/dev/null | while read -r id name; do
  echo "  sg: $id  name=$name"
done

echo ""
echo "# ELBv2 (ALB/NLB)"
aws elbv2 describe-load-balancers --region "$REGION" \
  --query 'LoadBalancers[].[LoadBalancerArn,LoadBalancerName,Type]' \
  --output text 2>/dev/null | while read -r arn name type; do
  echo "  lb: $arn  name=$name  type=$type"
done
```

### 8.4 S3

```bash
#!/bin/bash
# scripts/inventory/s3.sh
# S3 e global, nao usa --region

echo "# S3 Buckets"
aws s3api list-buckets \
  --query 'Buckets[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  echo "  bucket: $name"
done
```

### 8.5 VPC

```bash
#!/bin/bash
# scripts/inventory/vpc.sh
REGION="${1:-us-east-1}"

echo "# VPCs"
aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' \
  --output text 2>/dev/null | while read -r id name cidr; do
  echo "  vpc: $id  name=$name  cidr=$cidr"
done

echo ""
echo "# Subnets"
aws ec2 describe-subnets --region "$REGION" \
  --query 'Subnets[].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone]' \
  --output text 2>/dev/null | while read -r id name cidr az; do
  echo "  subnet: $id  name=$name  cidr=$cidr  az=$az"
done

echo ""
echo "# Internet Gateways"
aws ec2 describe-internet-gateways --region "$REGION" \
  --query 'InternetGateways[].[InternetGatewayId,Tags[?Key==`Name`].Value|[0]]' \
  --output text 2>/dev/null | while read -r id name; do
  echo "  igw: $id  name=$name"
done

echo ""
echo "# NAT Gateways"
aws ec2 describe-nat-gateways --region "$REGION" \
  --query 'NatGateways[].[NatGatewayId,Tags[?Key==`Name`].Value|[0],State]' \
  --output text 2>/dev/null | while read -r id name state; do
  echo "  nat: $id  name=$name  state=$state"
done

echo ""
echo "# Route Tables"
aws ec2 describe-route-tables --region "$REGION" \
  --query 'RouteTables[].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output text 2>/dev/null | while read -r id name; do
  echo "  rtb: $id  name=$name"
done
```

### 8.6 RDS

```bash
#!/bin/bash
# scripts/inventory/rds.sh
REGION="${1:-us-east-1}"

echo "# RDS Instances"
aws rds describe-db-instances --region "$REGION" \
  --query 'DBInstances[].[DBInstanceIdentifier,Engine,DBInstanceClass,DBInstanceStatus]' \
  --output text 2>/dev/null | while read -r id engine class status; do
  echo "  rds: $id  engine=$engine  class=$class  status=$status"
done

echo ""
echo "# RDS Subnet Groups"
aws rds describe-db-subnet-groups --region "$REGION" \
  --query 'DBSubnetGroups[].DBSubnetGroupName' \
  --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  echo "  subnet-group: $name"
done

echo ""
echo "# RDS Parameter Groups"
aws rds describe-db-parameter-groups --region "$REGION" \
  --query 'DBParameterGroups[].[DBParameterGroupName,DBParameterGroupFamily]' \
  --output text 2>/dev/null | while read -r name family; do
  echo "  param-group: $name  family=$family"
done
```

### 8.7 IAM

```bash
#!/bin/bash
# scripts/inventory/iam.sh
# IAM e global, nao usa --region

echo "# IAM Roles"
aws iam list-roles \
  --query 'Roles[?starts_with(RoleName, `AWS`) == `false`].[RoleName,Path]' \
  --output text 2>/dev/null | while read -r name path; do
  echo "  role: $name  path=$path"
done

echo ""
echo "# IAM Policies (custom)"
aws iam list-policies --scope Local \
  --query 'Policies[].[PolicyName,Arn]' \
  --output text 2>/dev/null | while read -r name arn; do
  echo "  policy: $name  arn=$arn"
done
```

### 8.8 Route53

```bash
#!/bin/bash
# scripts/inventory/route53.sh
# Route53 e global

echo "# Route53 Hosted Zones"
aws route53 list-hosted-zones \
  --query 'HostedZones[].[Id,Name,Config.PrivateZone]' \
  --output text 2>/dev/null | while read -r id name private; do
  zone_id=$(echo "$id" | sed 's|/hostedzone/||')
  echo "  zone: $zone_id  name=$name  private=$private"
done
```

---

## 9. Refatoracao com IA (Cursor Agent)

### 9.1 O que e "Chavear o Model"

No Cursor IDE, o modo **Agent** (`Cmd+I` / `Ctrl+I`) permite usar IA para gerar e refatorar codigo. O **seletor de modelo** permite trocar entre diferentes modelos de IA:

- **Atalho**: `Cmd+/` (Mac) ou `Ctrl+/` (Windows/Linux) - cicla entre modelos
- **Modelos disponiveis**: Claude Opus, Claude Sonnet, GPT-4o, entre outros
- **Dica**: Claude Opus/Sonnet costuma gerar HCL mais limpo; GPT-4o pode ser mais verboso

### 9.2 Workflow de Refatoracao

Apos gerar o `generated_resources.tf`:

1. Abra o arquivo no Cursor
2. Acione o Agent (`Cmd+I`)
3. Use prompts como:

```
Refatore este codigo Terraform:
- Separe em arquivos por servico (ec2.tf, glue.tf, s3.tf, etc.)
- Extraia valores hardcoded para variables.tf
- Aplique nomeacao padrao: {projeto}-{recurso}-{ambiente}
- Remova atributos computados (id, arn) que nao devem estar no codigo
- Adicione default_tags via provider
- Agrupe security group rules por protocolo
```

4. Se o resultado nao for satisfatorio, troque o modelo (`Cmd+/`) e repita
5. Valide com `terraform plan` apos cada iteracao

### 9.3 O que a IA faz bem e o que requer revisao manual

| Tarefa | IA (Agent) | Revisao Manual |
|--------|:----------:|:--------------:|
| Extrair variaveis | Excelente | - |
| Renomear recursos | Bom | Verificar dependencias |
| Remover atributos computados | Bom | Validar com plan |
| Organizar em arquivos | Excelente | - |
| Criar modulos | Bom | Revisar interface |
| Definir lifecycle rules | Ruim | **Sempre revisar** |
| Entender logica de negocio | Ruim | **Sempre revisar** |

---

## 10. Riscos e Mitigacoes

| # | Risco | Impacto | Mitigacao |
|---|-------|---------|-----------|
| 1 | Recurso AWS nao suportado pelo provider Terraform | Import falha | Verificar documentacao do provider antes. Recurso nao suportado pode ser gerenciado via `aws_cloudformation_stack` como escape hatch |
| 2 | State e codigo divergem apos import | Terraform tenta alterar/destruir recursos | **Sempre** rodar `terraform plan` antes de `apply`. Plan deve mostrar zero changes |
| 3 | Atributos sensiveis no state (senhas, tokens) | Exposicao de secrets | Habilitar encriptacao no bucket S3. Usar `sensitive = true` em variaveis. Considerar Terraform Cloud para mascarar secrets no state |
| 4 | Import parcial - alguns recursos ficam fora | Drift entre IaC e realidade | Manter inventario atualizado. Usar AWS Config para detectar recursos nao gerenciados |
| 5 | Codigo gerado muito grande e dificil de manter | Manutencao inviavel | Importar por servico, refatorar antes de ir para o proximo. Modularizar pos-import |
| 6 | Lock do state em operacoes concorrentes | Corrupcao de state | Usar `use_lockfile = true` (>= 1.11) para locking nativo S3 |
| 7 | Alguem altera recurso manualmente apos import | Drift | Implementar alertas de drift com `terraform plan` periodico em CI/CD |

---

## 11. Criterios de Sucesso da POC

A POC sera considerada bem-sucedida quando:

- [ ] **Backend S3 funcional** - Bucket criado, versionado, encriptado, com locking nativo
- [ ] **Import de pelo menos 3 servicos** - Minimo: VPC, EC2, Glue (o mais critico)
- [ ] **State remoto no S3** - State armazenado e acessivel no bucket
- [ ] **Plan limpo** - `terraform plan` mostra zero changes para todos os recursos importados
- [ ] **Codigo organizado** - HCL separado por servico, com variaveis extraidas
- [ ] **Reproducivel** - Outro membro do time consegue clonar o repo, rodar `terraform init` e `terraform plan` com sucesso
- [ ] **Documentado** - README com instrucoes de setup e uso

### Escopo da POC

| Servico | Recursos a importar | Prioridade |
|---------|---------------------|------------|
| **VPC** | VPC, Subnets, IGW, NAT, Route Tables | Alta |
| **EC2** | Instances, Security Groups | Alta |
| **Glue** | Catalog DB, Crawlers, Jobs, Triggers | **Critica** |
| **S3** | Buckets principais | Alta |
| **IAM** | Roles usadas pelos servicos acima | Alta |
| **RDS** | Instancias (se existirem) | Media |
| **Route53** | Zonas e records | Media |
| **CloudWatch** | Log groups, Alarms | Baixa |

---

## 12. Proximos Passos

### Imediato (POC)

1. Garantir acesso AWS CLI com permissoes de leitura em todos os servicos
2. Instalar Terraform >= 1.11
3. Criar bucket S3 para state (bootstrap manual)
4. Executar scripts de inventario
5. Iniciar import pelo servico mais critico: **AWS Glue**
6. Validar com `terraform plan` a cada servico importado

### Pos-POC

1. Importar todos os servicos restantes
2. Modularizar o codigo (criar modulos reutilizaveis)
3. Implementar pipeline CI/CD para Terraform (plan em PR, apply em merge)
4. Configurar drift detection periodico
5. Definir politica de "no clickops" - toda alteracao via Terraform
6. Treinar equipe no workflow

### Sobre o Repositorio de IaC Existente

> Para analisar a estrutura atual do repositorio de IaC da equipe e sugerir a melhor forma de integrar os imports, **envie o arquivo em qualquer formato** (`.tar.gz` ou `.zip`). Ambos sao suportados e serao extraidos e analisados sem problema.

---

*Documento versao 2.0 | Atualizado em Marco/2026 | Ferramenta anterior (Terraformer) substituida por Terraform Nativo devido ao arquivamento do projeto*
