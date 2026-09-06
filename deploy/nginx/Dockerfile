FROM nginx:1.30-alpine

COPY conf.d /etc/nginx/conf.d/default.conf
COPY --from=web /app/_static /var/www/static
