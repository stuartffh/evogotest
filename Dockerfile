# Stage de Build
FROM golang:1.24.0-alpine as builder

# Instalar dependências de build necessárias
RUN apk update && apk add --no-cache \
    git \
    build-base \
    libjpeg-turbo-dev \
    libwebp-dev \
    ffmpeg-dev

WORKDIR /app

# Copiar os arquivos de código e módulos
# ATENÇÃO: O EasyPanel deve ser configurado para usar o diretório RAIZ do repositório evolution-go
# como contexto de build, onde este Dockerfile e o código-fonte estão localizados.
COPY go.mod go.sum ./
COPY . .

# Fazer o download das dependências (com replace funcionando)
RUN go mod download

# Compilar o binário
# O binário final será 'server'
RUN CGO_ENABLED=0 go build -o server ./cmd/evolution-go

# Stage Final (Imagem de Produção)
FROM alpine:3.19.1 as final

# Instalar dependências de runtime
# tzdata para fuso horário, ffmpeg e libjpeg-turbo para manipulação de mídia
RUN apk update && apk add --no-cache \
    tzdata \
    ffmpeg \
    libjpeg-turbo

WORKDIR /app

# Copiar o binário compilado do stage de build
COPY --from=builder /app/server /app/server

# Copiar o arquivo .env.example (que o usuário deve fornecer) para o container como um guia
# O EasyPanel deve injetar as variáveis de ambiente corretas
COPY .env.example /app/.env.example

# Definir fuso horário para São Paulo
ENV TZ=America/Sao_Paulo

# Porta de exposição (padrão 4000)
EXPOSE 4000

# Comando de execução
ENTRYPOINT ["/app/server"]
