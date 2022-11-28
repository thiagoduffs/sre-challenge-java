## Sobre o Desafio: 

Esse é um teste feito para conhecer um pouco mais de cada candidato. Não é um teste objetivo e não há apenas uma solução que consideramos correta, o intuito é ser um estudo de caso com o propósito de conhecer o seu modo de trabalhar.

## Introdução

Temos neste repositório uma aplicação em Java com uma API REST que responde um Hello World quando recebe um GET na porta 8080. (ex: curl http://localhost:8080/)

## Tarefas: 

* Containerize essa aplicação
* Crie um Helm chart contendo todos os componentes necessários para essa aplicação rodar em um cluster de Kubernetes
* Crie um repositório no AWS CodeCommit e habilite o Mirror com o repositório no Github.
* Crie uma pipeline com AWS CodePipeline para esse chart ser aplicado em um cluster de Kubernetes (pode usar o AWS EKS ou ECS)
* Provisione uma infraestrutura na AWS com terraform ou cloudformation para subir essa aplicação containerizada (Lembre-se de utilizar ELB, ASG, Route53 entre outros serviços da AWS )

Tarefa bônus - não obrigatória - apenas será um diferencial na sua entrega.
* Crie um alerta com AWS CloudWatch para validar se algum step do AWS CodePipeline falhar e enviar um e-mail.

## Alguma dicas que podem ser importantes:
* Qualidade da documentacão
* Utilizar boas práticas
* Organização do código
* Ser eficiente e simples

## Entrega do desafio:
Clone esse repositório e commite todas as modificações, depois que terminar, compacte o repositorio e nos envie, queremos analisar seus commits.
