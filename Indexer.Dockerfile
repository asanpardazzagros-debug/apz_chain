# infra/docker/indexer.Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git python3 make g++
COPY ./indexer /app
RUN npm ci --unsafe-perm
RUN npm run build

FROM node:18-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json
RUN chown -R app:app /app
USER app
ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000
CMD ["node", "dist/index.js"]
