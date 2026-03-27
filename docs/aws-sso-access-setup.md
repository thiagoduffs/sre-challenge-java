# Configuração de Acesso AWS SSO - Guia para SREs

## TL;DR

| Critério | Profiles Tradicionais (`aws configure`) | AWS SSO via CLI (`sso-session`) | AWS SSO Extender (Browser) |
|---|---|---|---|
| Segurança | Chaves estáticas (risco de vazamento) | Credenciais temporárias auto-rotacionadas | Credenciais temporárias via browser |
| Praticidade (7 contas) | Gerenciar 7 pares de chaves | **1 login, acesso a todas as 7 contas** | 1 clique para trocar de conta no browser |
| MFA/SSO | Manual por conta | Integrado ao Identity Center | Integrado ao Identity Center |
| CLI/Terminal | Sim | Sim | Não (apenas console web) |
| Terraform/IaC | Sim | Sim | Não |
| Renovação | Manual (rotacionar chaves) | Automática (token refresh) | Automática |

**Recomendação: Use os dois juntos.**

- **AWS CLI v2 com `sso-session`** para todo trabalho no terminal (CLI, Terraform, scripts, kubectl, etc.)
- **AWS SSO Extender** como complemento no browser para acesso rápido ao Console AWS

---

## Por que NÃO usar o método antigo de profiles com chaves estáticas

O método antigo (`aws configure --profile xxx`) exige que você armazene `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` em texto plano no `~/.aws/credentials`. Com 7 contas isso significa:

- 7 pares de chaves estáticas no disco (risco de segurança)
- Rotação manual periódica de cada par
- Se alguém acessar seu `~/.aws/credentials`, tem acesso a TODAS as 7 contas
- Não há integração nativa com MFA/SSO

**O AWS SSO via CLI resolve todos esses problemas.**

---

## Parte 1: Instalação do AWS CLI v2 no Linux Mint

### 1.1 Instalar o AWS CLI v2 (método oficial)

```bash
# Baixar o instalador oficial
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Descompactar
unzip awscliv2.zip

# Instalar
sudo ./aws/install

# Limpar arquivos de instalação
rm -rf aws awscliv2.zip

# Verificar a instalação
aws --version
# Deve retornar algo como: aws-cli/2.x.x Python/3.x.x Linux/...
```

> **Nota:** Se já tiver o AWS CLI v1 instalado, o comando acima instala o v2 em `/usr/local/bin/aws`. Verifique com `which aws` se está usando a versão correta.

### 1.2 Verificar a versão mínima

A funcionalidade `sso-session` (que permite login único para todas as contas) requer **AWS CLI v2.22.0+**. Confirme:

```bash
aws --version
# aws-cli/2.22.0 ou superior
```

---

## Parte 2: Configurar o AWS SSO via CLI (Terminal)

### 2.1 Configuração inicial interativa

Execute o comando abaixo para criar a primeira sessão SSO:

```bash
aws configure sso
```

O assistente vai pedir:
- **SSO session name:** `vexpenses` (nome que identifica sua organização)
- **SSO start URL:** `https://vexsso.awsapps.com/start`
- **SSO region:** A região onde o SSO está configurado (ex: `us-east-1`)
- **SSO registration scopes:** `sso:account:access` (permite acesso às contas)

Após isso, o browser abrirá para você autenticar. Após autenticar, o CLI mostra as contas disponíveis para você escolher.

### 2.2 Configuração manual completa (recomendado)

Depois de fazer a configuração inicial para descobrir o `sso_start_url` e `sso_region`, edite diretamente o arquivo `~/.aws/config` com todas as 7 contas de uma vez.

> O URL do portal SSO já está configurado: `https://vexsso.awsapps.com/start`

```bash
# Crie/edite o arquivo de configuração
mkdir -p ~/.aws
nano ~/.aws/config
```

Cole o conteúdo abaixo (ajustando o `sso_start_url` e `sso_region`):

```ini
# ===========================================================
# Sessão SSO compartilhada - um login para todas as contas
# ===========================================================
[sso-session vexpenses]
sso_start_url = https://vexsso.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access

# ===========================================================
# Contas AWS - todas compartilham a mesma sessão SSO
# ===========================================================

# --- Data - Development ---
[profile data-dev]
sso_session = vexpenses
sso_account_id = 816069169559
sso_role_name = sre-sr
region = us-east-1
output = json

# --- Data - Production ---
[profile data-prd]
sso_session = vexpenses
sso_account_id = 310777426584
sso_role_name = sre-sr
region = us-east-1
output = json

# --- DevStaging ---
[profile devstaging]
sso_session = vexpenses
sso_account_id = 902671150478
sso_role_name = sre-sr
region = us-east-1
output = json

# --- Marketing ---
[profile marketing]
sso_session = vexpenses
sso_account_id = 035858302639
sso_role_name = sre-sr
region = us-east-1
output = json

# --- Pay ---
[profile pay]
sso_session = vexpenses
sso_account_id = 140034130142
sso_role_name = sre-sr
region = us-east-1
output = json

# --- SharedServices ---
[profile sharedservices]
sso_session = vexpenses
sso_account_id = 237559827662
sso_role_name = sre-sr
region = us-east-1
output = json

# --- VExpenses (Principal) ---
[profile vexpenses]
sso_session = vexpenses
sso_account_id = 142992156239
sso_role_name = sre-sr
region = us-east-1
output = json
```

> **Nota:** Se a região padrão das suas contas for diferente (ex: `sa-east-1` para São Paulo), altere o campo `region` em cada profile.

### 2.3 Fazer login (uma única vez para todas as contas)

```bash
# Login único - abre o browser para autenticação
aws sso login --sso-session vexpenses
```

Isso abre o browser, você autentica **uma única vez**, e todas as 7 contas ficam acessíveis via CLI.

### 2.4 Usar os profiles no dia a dia

```bash
# Listar buckets S3 na conta de Data Development
aws s3 ls --profile data-dev

# Listar instâncias EC2 na conta de Produção
aws ec2 describe-instances --profile data-prd

# Ver clusters EKS na conta SharedServices
aws eks list-clusters --profile sharedservices

# Usar com Terraform
export AWS_PROFILE=devstaging
terraform plan

# Usar com kubectl (EKS)
aws eks update-kubeconfig --name meu-cluster --profile sharedservices
```

### 2.5 Atalhos úteis para o shell

Adicione ao arquivo de configuração do seu shell:

- **Zsh** (padrão em muitas distros): `~/.zshrc`
- **Bash**: `~/.bashrc`

```bash
nano ~/.zshrc   # ou ~/.bashrc se usar bash
```

Cole no final do arquivo:

```bash
# === AWS SSO Aliases ===
alias aws-login='aws sso login --sso-session vexpenses'
alias aws-data-dev='export AWS_PROFILE=data-dev && echo "-> Data - Development (816069169559)"'
alias aws-data-prd='export AWS_PROFILE=data-prd && echo "-> Data - Production (310777426584)"'
alias aws-devstaging='export AWS_PROFILE=devstaging && echo "-> DevStaging (902671150478)"'
alias aws-marketing='export AWS_PROFILE=marketing && echo "-> Marketing (035858302639)"'
alias aws-pay='export AWS_PROFILE=pay && echo "-> Pay (140034130142)"'
alias aws-shared='export AWS_PROFILE=sharedservices && echo "-> SharedServices (237559827662)"'
alias aws-vex='export AWS_PROFILE=vexpenses && echo "-> VExpenses (142992156239)"'
alias aws-whoami='aws sts get-caller-identity'
alias aws-profiles='aws configure list-profiles'
```

Depois de salvar, carregue as alterações:

```bash
source ~/.zshrc   # ou source ~/.bashrc se usar bash
```

Agora basta digitar, por exemplo:

```bash
aws-data-dev     # Muda para Data - Development
aws-whoami       # Confirma a identidade
aws s3 ls        # Já usa o profile correto
```

---

## Parte 3: Instalar o AWS SSO Extender (Browser)

O **AWS SSO Extender** é um complemento para o browser que facilita a navegação entre contas **no Console Web da AWS**. Ele não substitui a CLI, mas torna o acesso via browser muito mais rápido.

### 3.1 Instalar a extensão

Escolha seu browser:

- **Chrome/Chromium:** [Chrome Web Store](https://chrome.google.com/webstore/detail/aws-sso-extender/pojoaiboolahdaedebpjgnllehpofkep)
- **Firefox:** [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/aws-sso-extender/)
- **Edge:** [Edge Add-ons](https://microsoftedge.microsoft.com/addons/detail/aws-sso-extender/dbdbfcdnfbghdommmcichaiakhaoapkg)

### 3.2 Configurar a extensão

1. Após instalar, acesse o portal SSO da sua empresa no browser
2. Faça login normalmente
3. A extensão detecta automaticamente suas contas e roles
4. Clique no ícone da extensão para ver todas as contas

### 3.3 Funcionalidades úteis

- **Favoritos:** Marque as contas que você mais usa para acesso rápido
- **Cores:** Customize a cor do console por conta (ex: vermelho para produção, verde para dev) - isso ajuda a evitar executar comandos na conta errada
- **Renomear:** Renomeie as contas com nomes mais amigáveis
- **Busca:** Busque rapidamente entre as 7 contas
- **IAM Role Assumption:** Assuma roles IAM diretamente a partir dos profiles SSO

**Dica de segurança:** Configure a cor do console de **produção** como **vermelha** para sempre ter um indicador visual de que está em ambiente produtivo.

---

## Parte 4: Fluxo de trabalho diário recomendado

### Início do dia

```bash
# 1. Faça login SSO (uma vez por dia, dura ~8h dependendo da config)
aws-login

# 2. O browser abre, você autentica, pronto!
# Todas as 7 contas ficam acessíveis na CLI e no browser
```

### Durante o dia (Terminal)

```bash
# Troque entre contas conforme necessário
aws-data-dev
kubectl get pods

aws-data-prd
aws cloudwatch get-metric-statistics ...

aws-shared
terraform plan
```

### Durante o dia (Browser)

1. Clique no ícone do AWS SSO Extender
2. Selecione a conta desejada
3. O console abre direto na conta correta

### Se a sessão expirar

```bash
# Basta fazer login novamente
aws-login
```

---

## Parte 5: Dicas de segurança

1. **NUNCA** armazene chaves estáticas (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`) se SSO estiver disponível
2. **Configure cores diferentes** no Console para cada ambiente (especialmente produção)
3. **Verifique sempre** em qual conta você está antes de executar comandos destrutivos:
   ```bash
   aws-whoami
   ```
4. **Não compartilhe** sua sessão SSO ou cookies do browser
5. **Faça logout** ao final do dia se estiver em máquina compartilhada:
   ```bash
   aws sso logout
   ```

---

## Troubleshooting

### "The SSO session associated with this profile has expired"

```bash
aws sso login --sso-session vexpenses
```

### "Error loading SSO Token"

Limpe o cache e faça login novamente:

```bash
rm -rf ~/.aws/sso/cache/*
aws sso login --sso-session vexpenses
```

### "An error occurred (UnauthorizedAccountException)"

Verifique se o `sso_account_id` e `sso_role_name` estão corretos no `~/.aws/config`. Confirme com o SRE sênior quais roles você tem acesso.

### Profile não aparece no `aws configure list-profiles`

Verifique se o arquivo `~/.aws/config` está formatado corretamente (sem espaços extras, colchetes corretos).

### AWS SSO Extender não mostra as contas

1. Certifique-se de estar logado no portal SSO no browser
2. Recarregue a página do portal SSO
3. Clique novamente no ícone da extensão

---

## Referências

- [AWS CLI v2 - SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [AWS SSO Extender - GitHub](https://github.com/WTFender/aws-sso-extender)
- [AWS Identity Center (SSO)](https://aws.amazon.com/iam/identity-center/)
