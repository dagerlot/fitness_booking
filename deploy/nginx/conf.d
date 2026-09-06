server {
    listen 80;
    # TODO production domain
    server_name localhost
                127.0.0.1;

    # Security headers
    # The remaining headers are set by default by Django (SecurityMiddleware) - or in settings.py.
    # nosniff is duplicated here on purpose as django never sees /static/ and /media/, where uesr uploads land,
    # same value in nginx and Django so no conflict.
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    location /static/ {
        alias /var/www/static/;
        try_files $uri =404;
        # expires 5m; # enable together with hashed filenames
        access_log off;
    }

    location / {
        proxy_pass http://web:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;

        proxy_connect_timeout 5s;
    }
}