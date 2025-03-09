# Etapa 1: Build da aplicação
FROM openjdk:17-jdk-slim AS build

WORKDIR /app

# Copiar o código-fonte para dentro do container
COPY app /app

# Dar permissão ao script do Maven Wrapper (caso necessário)
RUN chmod +x mvnw

# Construir a aplicação e gerar o JAR
RUN ./mvnw clean package -DskipTests

# Etapa 2: Criar uma imagem final otimizada para rodar o JAR
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copiar o JAR gerado na etapa anterior
COPY --from=build /app/target/*.jar app.jar

# Expor a porta 8080 (padrão do Spring Boot)
EXPOSE 8080

# Comando para rodar a aplicação
CMD ["java", "-jar", "app.jar"]
