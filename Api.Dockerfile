# infra/docker/api.Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY ./apps/api /app
RUN npm ci
RUN npm run build

FROM node:18-alpine
WORKDIR /app
RUN addgroup -S apz && adduser -S apz -G apz
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/prisma /app/prisma
RUN chown -R apz:apz /app
USER apz
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/server.js"]
