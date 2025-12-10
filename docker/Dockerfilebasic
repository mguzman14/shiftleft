FROM alpine:3.20

# Metadades útils
LABEL org.opencontainers.image.description="Imatge bàsica per provar GitHub Actions + Trivy"
LABEL org.opencontainers.image.licenses="MIT"

# Instal·la un paquet senzill per tenir alguna cosa a escanejar
RUN apk add --no-cache curl

# Defineix un script d'entrada directament dins el Dockerfile
CMD echo "Hola! Aquesta és una imatge de prova per a GitHub Actions + Trivy." && curl --version
