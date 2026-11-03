FROM golang:1.27-alpine AS build

RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

COPY . .

# FIX GTR (Client outdated 405): atualiza o whatsmeow para a revisão de 02/11/2026,
# que inclui as correções de handshake do fim de outubro/2026 e o protocolo atual.
ARG WHATSMEOW_REV=54038813c47f3f351eb6fcaafab0e1b99d676850
RUN go get go.mau.fi/whatsmeow@${WHATSMEOW_REV} && go mod tidy

ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

FROM alpine:3.19.1 AS final

# poppler-utils provides pdftoppm, used to rasterize PDF page 1 for /send/media document thumbnails
RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp poppler-utils

WORKDIR /app

COPY --from=build /build/server .
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION

ENV TZ=America/Sao_Paulo

ENTRYPOINT ["/app/server"]
