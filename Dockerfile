FROM node:20-alpine AS builder
RUN apk update && apk add --no-cache git
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:stable-alpine

RUN apk update && apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R appuser:appgroup /var/run/nginx.pid
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 8080
USER appuser
CMD ["nginx", "-g", "daemon off;"]
