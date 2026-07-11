FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Injeta a URL do backend em runtime (config.js gerado a partir do template)
COPY docker-entrypoint.sh /docker-entrypoint.d/30-inject-api-url.sh
RUN chmod +x /docker-entrypoint.d/30-inject-api-url.sh

EXPOSE 80
