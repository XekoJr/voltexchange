#!/bin/sh
# Gera o config.js com a URL do backend a partir da env var API_BASE_URL —
# a mesma imagem construída serve qualquer ambiente sem rebuild
set -e

envsubst '${API_BASE_URL}' \
  < /usr/share/nginx/html/config.js.template \
  > /usr/share/nginx/html/config.js

echo "config.js gerado com API_BASE_URL=${API_BASE_URL}"
