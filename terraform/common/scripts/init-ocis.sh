#! /bin/bash
# Install necessary dependencies
sudo apt update
sudo apt install -y nginx snapd ldap-utils wget

# Install certbot for signing domain with letsencrypt
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
# Create certificates
sudo certbot certonly --nginx -n --agree-tos -m ${cert_email} -d ${ocis_url}

# Configure nginx as reverse proxy
sudo bash -c 'cat > /etc/nginx/sites-available/${ocis_url}' <<EOF
server {
  root /var/www/html;
  server_name ${ocis_url}; # managed by Certbot

  location / {
    proxy_pass http://127.0.0.1:9200;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  listen [::]:443 ssl ipv6only=on; # managed by Certbot
  listen 443 ssl; # managed by Certbot
  ssl_certificate /etc/letsencrypt/live/${ocis_url}/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/${ocis_url}/privkey.pem; # managed by Certbot
  include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
  if (\$host = ${ocis_url}) {
    return 301 https://\$host\$request_uri;
  } # managed by Certbot
  listen 80 ;
  listen [::]:80 ;
  server_name ${ocis_url};
  return 404; # managed by Certbot
}
EOF
sudo ln -s /etc/nginx/sites-available/${ocis_url} /etc/nginx/sites-enabled/${ocis_url}
sudo systemctl reload nginx

# Install OwnCloud (OCIS)
sudo wget -O /usr/local/bin/ocis https://download.owncloud.com/ocis/ocis/stable/2.0.0/ocis-2.0.0-linux-amd64
sudo chmod +x /usr/local/bin/ocis

# Create initial OCIS config
sudo mkdir -p /etc/ocis/config
IDM_ADMIN_PASSWORD='${ocis_admin_password}' ocis init --insecure true --config-path /etc/ocis/config

# Create user for running OCIS
sudo useradd --system --no-create-home --shell=/sbin/nologin ocis
sudo chown -R ocis:ocis /etc/ocis

# Create environment
sudo bash -c 'cat > /etc/ocis/ocis.env' <<EOF
PROXY_HTTP_ADDR=127.0.0.1:9200
PROXY_AUTOPROVISION_ACCOUNTS=true
PROXY_OIDC_REWRITE_WELLKNOWN=true
PROXY_TLS=false
PROXY_ENABLE_BASIC_AUTH=true
WEB_OIDC_CLIENT_ID=${ory_client_id}
OCIS_OIDC_ISSUER=${ory_url}
OCIS_URL=https://${ocis_url}
OCIS_CONFIG_DIR=/etc/ocis/config
OCIS_BASE_DATA_PATH=/etc/ocis
OCIS_INSECURE=true
OCIS_LOG_LEVEL=error
OCIS_LOG_COLOR=true
IDM_ADMIN_PASSWORD=${ocis_admin_password}
EOF

# Create systemd service to run OCIS
sudo bash -c 'cat > /etc/systemd/system/ocis.service' <<EOF
[Unit]
Description=OCIS server

[Service]
Type=simple
User=ocis
Group=ocis
EnvironmentFile=/etc/ocis/ocis.env
ExecStart=/usr/local/bin/ocis server
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start OCIS service
sudo systemctl daemon-reload
sudo systemctl enable --now ocis
