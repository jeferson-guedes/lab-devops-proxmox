# Etapa 1: build estático
FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/api-server .

# Etapa 2: runtime distroless (sem shell, sem package manager).
# Compatível com runAsNonRoot e readOnlyRootFilesystem do Pod.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/api-server /api-server
EXPOSE 8080
ENTRYPOINT ["/api-server"]
