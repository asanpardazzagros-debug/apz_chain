# infra/docker/node.Dockerfile
FROM golang:1.20-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git build-base
COPY ./node-client /src
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/apz-node ./cmd/node

FROM alpine:3.18
RUN apk add --no-cache ca-certificates
COPY --from=builder /bin/apz-node /usr/local/bin/apz-node
ENV APZ_HOME=/var/lib/apz
VOLUME ["/var/lib/apz"]
EXPOSE 26656 26657 1317
ENTRYPOINT ["apz-node"]
CMD ["start"]
