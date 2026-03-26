#!/bin/bash
set -euo pipefail

# Gera import blocks a partir da saida dos scripts de inventario.
# Uso: ./generate_import_blocks.sh <servico> <arquivo_inventario>
# Exemplo: ./generate_import_blocks.sh glue scripts/inventory/output/glue.txt

SERVICE="${1:?Uso: $0 <servico> <arquivo_inventario>}"
INPUT_FILE="${2:?Uso: $0 <servico> <arquivo_inventario>}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERRO: Arquivo nao encontrado: $INPUT_FILE"
  exit 1
fi

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

echo "# Import blocks gerados automaticamente para: $SERVICE"
echo "# Data: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "# Arquivo fonte: $INPUT_FILE"
echo "# REVISE antes de usar - nomes de recursos podem precisar de ajuste"
echo ""

case "$SERVICE" in
  glue)
    while IFS= read -r line; do
      if echo "$line" | grep -q "database:"; then
        id=$(echo "$line" | sed 's/.*database: *//' | xargs)
        name=$(sanitize_name "$id")
        echo "import {"
        echo "  to = aws_glue_catalog_database.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "crawler:"; then
        id=$(echo "$line" | sed 's/.*crawler: *//' | xargs)
        name=$(sanitize_name "$id")
        echo "import {"
        echo "  to = aws_glue_crawler.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "job:"; then
        id=$(echo "$line" | sed 's/.*job: *//' | xargs)
        name=$(sanitize_name "$id")
        echo "import {"
        echo "  to = aws_glue_job.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "trigger:"; then
        id=$(echo "$line" | sed 's/.*trigger: *//' | xargs)
        name=$(sanitize_name "$id")
        echo "import {"
        echo "  to = aws_glue_trigger.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      fi
    done < "$INPUT_FILE"
    ;;

  ec2)
    while IFS= read -r line; do
      if echo "$line" | grep -q "instance:"; then
        id=$(echo "$line" | sed 's/.*instance: *//' | awk '{print $1}')
        raw_name=$(echo "$line" | sed 's/.*name=//' | awk '{print $1}')
        name=$(sanitize_name "${raw_name:-$id}")
        echo "import {"
        echo "  to = aws_instance.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "sg:"; then
        id=$(echo "$line" | sed 's/.*sg: *//' | awk '{print $1}')
        raw_name=$(echo "$line" | sed 's/.*name=//' | awk '{print $1}')
        name=$(sanitize_name "${raw_name:-$id}")
        echo "import {"
        echo "  to = aws_security_group.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      fi
    done < "$INPUT_FILE"
    ;;

  s3)
    while IFS= read -r line; do
      if echo "$line" | grep -q "bucket:"; then
        id=$(echo "$line" | sed 's/.*bucket: *//' | awk '{print $1}')
        name=$(sanitize_name "$id")
        echo "import {"
        echo "  to = aws_s3_bucket.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      fi
    done < "$INPUT_FILE"
    ;;

  vpc)
    while IFS= read -r line; do
      if echo "$line" | grep -q "  vpc:"; then
        id=$(echo "$line" | sed 's/.*vpc: *//' | awk '{print $1}')
        raw_name=$(echo "$line" | sed 's/.*name=//' | awk '{print $1}')
        name=$(sanitize_name "${raw_name:-$id}")
        echo "import {"
        echo "  to = aws_vpc.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "subnet:"; then
        id=$(echo "$line" | sed 's/.*subnet: *//' | awk '{print $1}')
        raw_name=$(echo "$line" | sed 's/.*name=//' | awk '{print $1}')
        name=$(sanitize_name "${raw_name:-$id}")
        echo "import {"
        echo "  to = aws_subnet.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "igw:"; then
        id=$(echo "$line" | sed 's/.*igw: *//' | awk '{print $1}')
        name=$(sanitize_name "${id}")
        echo "import {"
        echo "  to = aws_internet_gateway.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "nat:"; then
        id=$(echo "$line" | sed 's/.*nat: *//' | awk '{print $1}')
        name=$(sanitize_name "${id}")
        echo "import {"
        echo "  to = aws_nat_gateway.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      elif echo "$line" | grep -q "rtb:"; then
        id=$(echo "$line" | sed 's/.*rtb: *//' | awk '{print $1}')
        raw_name=$(echo "$line" | sed 's/.*name=//' | awk '{print $1}')
        name=$(sanitize_name "${raw_name:-$id}")
        echo "import {"
        echo "  to = aws_route_table.${name}"
        echo "  id = \"${id}\""
        echo "}"
        echo ""
      fi
    done < "$INPUT_FILE"
    ;;

  *)
    echo "ERRO: Servico nao suportado: $SERVICE"
    echo "Servicos suportados: glue, ec2, s3, vpc"
    exit 1
    ;;
esac
