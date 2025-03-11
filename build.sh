#!/bin/bash

echo "🔨 Iniciando o build da aplicação..."

# Criar a imagem Docker
docker build -t thicarvalho/sre-challenge-java:v1.0 .

# Fazer login no DockerHub
echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin

# Fazer o push da imagem para o DockerHub
docker push thicarvalho/sre-challenge-java:v1.0

echo "✅ Build e push concluídos com sucesso!"
