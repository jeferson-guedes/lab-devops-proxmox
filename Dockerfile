# Etapa 1: Build
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copia os arquivos do projeto
COPY go.mod ./
COPY main.go ./

# Compila o binário estático
RUN CGO_ENABLED=0 GOOS=linux go build -o api-server main.go

# Etapa 2: Execução (Imagem muito menor, apenas com o binário)
FROM alpine:latest

WORKDIR /root/

# Copia o binário compilado da etapa anterior
COPY --from=builder /app/api-server .

EXPOSE 8080

CMD ["./api-server"]
