# **SRE Challenge - Java Application on AWS EKS**

Este repositório contém uma aplicação **Java Spring Boot** configurada para rodar em um ambiente **AWS EKS** com deploy automatizado via **GitHub Actions** e monitoramento com **AWS CloudWatch**. O objetivo desse projeto é demonstrar **boas práticas de SRE** em **containerização, deploy automatizado e observabilidade**.

---

## 📂 Estrutura do Projeto

```bash
.
├── app                          # Código da aplicação Java
│   ├── mvnw                     # Wrapper do Maven
│   ├── mvnw.cmd                 # Wrapper do Maven (Windows)
│   ├── pom.xml                  # Arquivo de configuração do Maven
│   ├── src                      # Código-fonte da aplicação
│   │   ├── main
│   │   │   ├── java/com/example/app
│   │   │   │   ├── AppAController.java
│   │   │   │   ├── AppApplication.java
│   │   │   └── resources
│   │   │       ├── application.properties  # Configuração da aplicação
│   │   └── test/java/com/example/app
│   │       ├── AppApplicationTests.java    # Testes da aplicação
│   ├── target                              # Artefatos gerados pelo Maven
│       ├── app-0.0.1-SNAPSHOT.jar
│       ├── app-0.0.1-SNAPSHOT.jar.original
│       ├── classes
│       │   ├── application.properties
│       │   └── com/example/app
│       │       ├── AppAController.class
│       │       ├── AppApplication.class
│       ├── generated-sources/annotations
│       ├── generated-test-sources/test-annotations
│       ├── maven-archiver/pom.properties
│       ├── maven-status/maven-compiler-plugin
│       │   ├── compile/default-compile
│       │   │   ├── createdFiles.lst
│       │   │   ├── inputFiles.lst
│       │   ├── testCompile/default-testCompile
│       │       ├── createdFiles.lst
│       │       ├── inputFiles.lst
│       └── test-classes/com/example/app
│           ├── AppApplicationTests.class
├── Dockerfile                        # Configuração da imagem Docker
├── README.md                         # Documentação do projeto
├── sre-challenge-java                 # Helm Chart para deploy no Kubernetes
│   ├── Chart.yaml                     # Definições do Helm Chart
│   ├── values.yaml                     # Configurações do Helm Chart
│   ├── templates                      # Manifestos Kubernetes
│   │   ├── deployment.yaml             # Configuração do Deployment no Kubernetes
│   │   ├── service.yaml                # Configuração do Service no Kubernetes
│   │   ├── ingress.yaml                # Configuração do Ingress (opcional)
│   │   ├── namespace.yaml              # Namespace da aplicação
│   │   ├── hpa.yaml                    # Configuração do Autoscaler
│   │   ├── serviceaccount.yaml         # Configuração da Service Account
│   │   ├── _helpers.tpl                # Helpers do Helm
│   │   ├── tests/test-connection.yaml  # Testes do Helm
└── terraform-eks                      # Infraestrutura como código (IaC) para criar o cluster EKS
    ├── eks.tf                          # Configuração do EKS
    ├── provider.tf                      # Configuração do Provider AWS
    ├── security_groups.tf               # Regras de firewall do cluster
    ├── nodegroup.tf                     # Configuração do grupo de nós
    ├── network.tf                       # Configuração de rede
    ├── elb.tf                           # Configuração do Load Balancer
    ├── iam.tf                           # Permissões IAM
    ├── outputs.tf                        # Saídas do Terraform
    ├── variables.tf                      # Variáveis do Terraform
```

## **🛠️ Tecnologias Utilizadas**
A stack do projeto foi construída com as seguintes tecnologias:

### **📌 Backend**
- Java 17 com **Spring Boot**
- API REST simples (Hello World)

### **📌 Infraestrutura**
- **Docker** para containerizar a aplicação
- **Helm** para gerenciar os manifestos do Kubernetes
- **AWS EKS** como orquestrador de containers
- **AWS CloudWatch** para monitoramento do cluster
- **AWS SNS** para notificações de eventos críticos

### **📌 CI/CD**
- **GitHub Actions** para build e push da imagem Docker
- **Helm Chart** para deploy no Kubernetes

---

## **🚀 Como Funciona**
### **1️⃣ Build e Push da Imagem Docker**
A pipeline **GitHub Actions** é acionada quando há um **commit na branch `develop`**. O workflow realiza os seguintes passos:
1. Faz **build da imagem** da aplicação Java.
2. Faz **push da imagem** para o **Docker Hub**.
3. Envia um log de sucesso.


```yaml
name: Build and Push to DockerHub
on:
  push:
    branches:
      - develop
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do código
        uses: actions/checkout@v3
      - name: Build da Imagem Docker
        run: docker build -t usuario/sre-challenge-java:v1.0 .
      - name: Push da Imagem para o DockerHub
        run: docker push usuario/sre-challenge-java:v1.0
```

### 2️⃣ Deploy Automatizado no Kubernetes
Após o build, o **Helm** faz o deploy da nova versão no **EKS**:

- Atualiza a configuração do cluster via **kubectl**.
- Aplica os manifestos do **Helm** (`deployment.yaml`, `service.yaml`, etc.).
- Confirma se os **pods** foram criados corretamente.


```yaml
name: Deploy Java App on EKS
on:
  push:
    branches:
      - develop
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Configurar kubectl
        run: aws eks update-kubeconfig --name sre-challenge-eks --region us-east-1
      - name: Deploy no Kubernetes via Helm
        run: |
          helm upgrade --install java-app ./sre-challenge-java \
          --namespace sre-challenge-java --create-namespace \
          --set image.repository=usuario/sre-challenge-java \
          --set image.tag=v1.0
```

---

### 3️⃣ Monitoramento com AWS CloudWatch
O monitoramento da aplicação ocorre via **CloudWatch Alarms**, configurado para:

- **Detectar** novos pods rodando no cluster.
- **Enviar alertas** via e-mail (**SNS**).
- **Monitorar falhas** no cluster.


## 📢 Configuração de Alerta via AWS SNS e CloudWatch

### 1️⃣ Criar um **SNS Topic** para receber alertas
O **AWS SNS (Simple Notification Service)** será usado para enviar notificações por e-mail quando um evento for acionado.

```bash
aws sns create-topic --name EKSClusterAlerts
```

Saída esperada:
```json
{
    "TopicArn": "arn:aws:sns:us-east-1:123456789012:EKSClusterAlerts"
}
```
**Copie o TopicArn** retornado para usá-lo no próximo passo.

### 2️⃣ Criar uma assinatura no SNS Topic para envio de e-mail
Agora, cadastre um endereço de e-mail que receberá as notificações:
```bash
aws sns subscribe --topic-arn arn:aws:sns:us-east-1:123456789012:EKSClusterAlerts \
    --protocol email \
    --notification-endpoint seuemail@example.com
```

# 📌 Nota:

*Substitua **seuemail@example.com** pelo seu e-mail real.
*Um **e-mail de confirmação** será enviado para o endereço cadastrado.
*Você precisa abrir o e-mail e **confirmar** a assinatura.    


### 3️⃣ Criar um alarme do CloudWatch para enviar notificações
Agora, criamos um alarme no CloudWatch para monitorar o cluster EKS e enviar alertas via SNS.
```bash
aws cloudwatch put-metric-alarm \
    --alarm-name "NewEKSResourceCreated" \
    --metric-name "RunningPodCount" \
    --namespace "ContainerInsights" \
    --statistic Maximum \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 1.0 \
    --comparison-operator GreaterThanThreshold \
    --alarm-actions arn:aws:sns:us-east-1:xxxxx:EKSClusterAlerts    
```

# 📌 Explicação:

- O alarme monitora a métrica **RunningPodCount**.
- Se houver **mais de 1 pod rodando**, o alarme dispara.
- A notificação será enviada para o **SNS Topic** configurado.

## 🚀 Testando o alerta
Se quiser testar manualmente o disparo do alerta e se está sendo encaminhado para o e-mail desejado corretamente, use:

```bash
aws cloudwatch set-alarm-state --alarm-name "NewEKSResourceCreated" \
    --state-value ALARM \
    --state-reason "Testando envio de alerta"
```

---

## 📌 Como Rodar o Projeto

## 🔹 Requisitos
- Conta na AWS (com EKS e CloudWatch ativados)
- Kubectl configurado para acessar o cluster
- Helm instalado para gerenciar o deploy

## 1️⃣ Clonar o Repositório
```bash
git clone git@github.com:thiagoduffs/sre-challenge-java.git
cd sre-challenge-java
```

## 2️⃣ Criar e Configurar o Cluster EKS
Se precisar subir um novo cluster:

```bash
cd terraform-eks
terraform init
terraform plan
terraform apply 
```

## 3️⃣ Fazer Deploy da Aplicação
```bash
kubectl create namespace sre-challenge-java
helm upgrade --install java-app ./sre-challenge-java --namespace sre-challenge-java
```

## 4️⃣ Testar a Aplicação
Verifique se os pods estão rodando:

```bash
kubectl get pods -n sre-challenge-java
```

Pegue o endereço do LoadBalancer da aplicação e faça um teste local:

```bash
kubectl get svc -n sre-challenge-java
```

```bash
curl http://<ELB_DNS>:8080
```

## 📊 Monitoramento
Para verificar logs e eventos no CloudWatch:

```bash
aws cloudwatch describe-alarms --alarm-names "NewEKSResourceCreated"
aws logs tail /aws/eks/sre-challenge-eks/cluster --follow
```

**Se o alerta for acionado, você receberá um e-mail de notificação pelo SNS.**

## 📌 Conclusão
Este projeto demonstra um fluxo completo de CI/CD no Kubernetes usando AWS EKS, cobrindo desde o build da aplicação até o deploy automatizado e monitoramento. Foi configurado para ser eficiente, escalável e seguro dentro dos limites do AWS Free Tier.
