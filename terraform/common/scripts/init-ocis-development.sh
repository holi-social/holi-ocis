#! /bin/bash

# Install ownCloud Infinite Scale
if [[ ! -d "/etc/ocis/" ]]; then
  # Install OpsAgent for collecting logs (and metrics)
  curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  sudo bash add-google-cloud-ops-agent-repo.sh --also-install

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
  client_max_body_size 100M;
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
  sudo bash -c 'cat > /etc/ocis/ocis.env' <<'EOF'
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
# activate s3ng storage driver for blobs
STORAGE_USERS_DRIVER=s3ng
# keep system data on ocis storage since this are only small files atm
STORAGE_SYSTEM_DRIVER=ocis
STORAGE_USERS_S3NG_ENDPOINT=https://storage.googleapis.com
STORAGE_USERS_S3NG_ACCESS_KEY=${storage_access_id}
STORAGE_USERS_S3NG_SECRET_KEY=${storage_access_secret}
STORAGE_USERS_S3NG_BUCKET=${storage_bucket}
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

fi

# Install WOPI Server
if [[ ! -d "/etc/wopiserver/" ]]; then
  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip openssl

  # Generate certificates
  sudo certbot certonly --nginx -n --agree-tos -m ${cert_email} -d ${wopiserver_url}

  # Create Nginx configuration file
  sudo bash -c 'cat > /etc/nginx/sites-available/${wopiserver_url}' <<EOF
server {
    listen 80;
    server_name ${wopiserver_url};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${wopiserver_url};

    ssl_certificate /etc/letsencrypt/live/${wopiserver_url}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${wopiserver_url}/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8880;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  # Create a symbolic link to enable the site
  sudo ln -s /etc/nginx/sites-available/${wopiserver_url} /etc/nginx/sites-enabled/

  # Restart Nginx
  sudo service nginx restart

  # Download and extract CS3 WOPI server
  wget https://github.com/cs3org/wopiserver/archive/refs/tags/v10.0.0sciencemesh.tar.gz
  sudo mkdir -p /etc/wopiserver
  sudo tar -xzf v10.0.0sciencemesh.tar.gz -C /etc/wopiserver --strip-components=1
  rm v10.0.0sciencemesh.tar.gz

  # Add log file directory
  sudo mkdir -p /var/log/wopi/
  sudo chmod a+rwx /var/log/wopi

  # Create the folder for the wopi config
  sudo mkdir -p /etc/wopi/
  sudo chmod a+rwx /etc/wopi

  # Create recovery folder
  sudo mkdir -p /var/spool/wopirecovery
  sudo chmod a+rwx /var/spool/wopirecovery

  # Create local storage folder
  sudo mkdir -p /var/wopi_local_storage
  sudo chmod a+rwx /var/wopi_local_storage

  # Create the files iopsecret and wopiscret in the folder /etc/wopi/
  sudo sh -c "echo ${iopsecret} > /etc/wopi/iopsecret"
  sudo sh -c "echo ${wopisecret} > /etc/wopi/wopisecret"

  # Navigate to the WOPI server folder
  cd /etc/wopiserver

  # Install requirements
  pip install -r requirements.txt

  # Copy the provided wopiserver.conf to /etc/wopi/wopiserver.defaults.conf
  sudo cp wopiserver.conf /etc/wopi/wopiserver.defaults.conf

  # Generate the host certificate and private key
  sudo openssl genpkey -algorithm RSA -out /etc/grid-security/host.key
  sudo chmod 400 /etc/grid-security/host.key
  sudo openssl req -new -key /etc/grid-security/host.key -out /etc/grid-security/host.csr -nodes -subj "/C=DE/ST=Hamburg/L=Hamburg/O=Holi Moli GmbH/CN=holi.social"
  sudo chmod 444 /etc/grid-security/host.crt

  # Create a config file /etc/wopi/wopiserver.conf
  sudo bash -c 'cat > /etc/wopi/wopiserver.conf' <<EOF
# This config is based on https://github.com/owncloud/ocis/blob/master/deployments/examples/ocis_wopi/config/wopiserver/wopiserver.conf.dist

[general]
# Storage access layer to be loaded in order to operate this WOPI server
# only "cs3" is supported with oCIS
storagetype = cs3

# Port where to listen for WOPI requests
port = 8880

# Logging level. Debug enables the Flask debug mode as well.
# Valid values are: Debug, Info, Warning, Error.
loglevel = Error
loghandler = stream
logdest = stdout

# URL of your WOPI server or your HA proxy in front of it
wopiurl = ${wopiserver_url}

# URL for direct download of files. The complete URL that is sent
# to clients will include the access_token argument
downloadurl = ${wopiserver_url}/wopi/cbox/download

# The internal server engine to use (defaults to flask).
# Set to waitress for production installations.
internalserver = waitress

# List of file extensions deemed incompatible with LibreOffice:
# interoperable locking will be disabled for such files
nonofficetypes = .md .zmd .txt .epd

# List of file extensions to be supported by Collabora (deprecated)
codeofficetypes = .odt .ott .ods .ots .odp .otp .odg .otg .doc .dot .xls .xlt .xlm .ppt .pot .pps .vsd .dxf .wmf .cdr .pages .number .key

# WOPI access token expiration time [seconds]
tokenvalidity = 86400

# WOPI lock expiration time [seconds]
wopilockexpiration = 3600

# WOPI lock strict check: if True, WOPI locks will be compared according to specs,
# that is their representation must match. False (default) allows for a more relaxed
# comparison, which compensates incorrect lock requests from Microsoft Office Online
# on-premise setups.
wopilockstrictcheck = False

# Enable support of rename operations from WOPI apps. This is currently
# disabled by default as it has been observed that both MS Office and Collabora
# Online do not play well with this feature.
# Not supported with oCIS, must always be set to "False"
enablerename = False

# Detection of external Microsoft Office or LibreOffice locks. By default, lock files
# compatible with Office for Desktop applications are detected, assuming that the
# underlying storage can be mounted as a remote filesystem: in this case, WOPI GetLock
# and SetLock operations return such locks and prevent online apps from entering edit mode.
# This feature can be disabled in order to operate a pure WOPI server for online apps.
# Not supported with oCIS, must always be set to "False"
detectexternallocks = False

[security]
# Location of the secret files. Requires a restart of the
# WOPI server when either the files or their content change.
wopisecretfile = /etc/wopi/wopisecret

# Use https as opposed to http (requires certificate)
usehttps = yes

# Certificate and key for https. Requires a restart
# to apply a change.
wopicert = /etc/grid-security/host.crt
wopikey = /etc/grid-security/host.key

[bridge]
# SSL certificate check for the connected apps
sslverify = True

# Minimal time interval between two consecutive save operations [seconds]
#saveinterval = 200

# Minimal time interval before a closed file is WOPI-unlocked [seconds]
#unlockinterval = 90

# CodiMD: disable creating zipped bundles when files contain pictures
#disablezip = False

[io]
# Size used for buffered reads [bytes]
chunksize = 4194304

# Path to a recovery space in case of I/O errors when reaching to the remote storage.
# This is expected to be a local path, and it is provided in order to ease user support.
# Defaults to the indicated spool folder.
recoverypath = /var/spool/wopirecovery

[cs3]
# Host and port of the Reva(-like) CS3-compliant GRPC gateway endpoint
revagateway = 127.0.0.1:9142

# Reva/gRPC authentication token expiration time [seconds]
# The default value matches Reva's default
authtokenvalidity = 3600

# SSL certificate check for Reva
sslverify = True

EOF

  # Create systemd service for WOPI Server
  sudo bash -c 'cat > /etc/systemd/system/wopiserver.service' <<EOF
[Unit]
Description=WOPI Server
After=syslog.target

[Service]
Type=simple
WorkingDirectory=/etc/wopiserver
ExecStart=/usr/bin/python3 /etc/wopiserver/src/wopiserver.py
StandardError=syslog

[Install]
WantedBy=default.target
EOF

  # Append WOPI environment variables to ocis.env
  {
    echo "GATEWAY_GRPC_ADDR=127.0.0.1:9142"
    echo "REVA_GATEWAY=127.0.0.1:9142"
    echo "APP_PROVIDER_GRPC_ADDR=0.0.0.0:9164"
    echo "APP_PROVIDER_EXTERNAL_ADDR=0.0.0.0:9164"
    echo "APP_PROVIDER_DRIVER=wopi"
    echo "APP_PROVIDER_WOPI_FOLDER_URL_BASE_URL=https://${ocis_url}"
    echo "APP_PROVIDER_WOPI_WOPI_SERVER_EXTERNAL_URL=https://${wopiserver_url}"
    echo "APP_PROVIDER_WOPI_INSECURE=false"
    echo "APP_PROVIDER_WOPI_WOPI_SERVER_IOP_SECRET=${iopsecret}"
    echo "OCIS_JWT_SECRET=${ocis_jwt_secret}"
  } | sudo tee -a /etc/ocis/ocis.env

  # Enable and start the WOPI Server service
  sudo systemctl daemon-reload
  sudo systemctl enable wopiserver
  sudo systemctl start wopiserver

  # Restart ownCloud
  sudo systemctl restart ocis
fi

# Install ONLYOFFICE Docs Community Edition
if [[ ! -d "/etc/onlyoffice/" ]]; then
  # Install dependencies
  sudo apt-get install -y postgresql rabbitmq-server nginx-extras

  # Change the ONLYOFFICE default port
  onlyoffice_port=9201
  echo "onlyoffice-documentserver onlyoffice/ds-port select $onlyoffice_port" | sudo debconf-set-selections

  # Set PostgreSQL database options
  echo "onlyoffice-documentserver onlyoffice/db-host string ${onlyoffice_db_host}" | sudo debconf-set-selections
  echo "onlyoffice-documentserver onlyoffice/db-user string ${onlyoffice_db_user}" | sudo debconf-set-selections
  echo "onlyoffice-documentserver onlyoffice/db-pwd password ${onlyoffice_db_password}" | sudo debconf-set-selections
  echo "onlyoffice-documentserver onlyoffice/db-name string ${onlyoffice_db_name}" | sudo debconf-set-selections

  # Set JWT options
  echo "onlyoffice-documentserver onlyoffice/jwt-enabled boolean true" | sudo debconf-set-selections
  echo "onlyoffice-documentserver onlyoffice/jwt-secret password ${onlyoffice_jwt_secret}" | sudo debconf-set-selections

  # Add GPG key
  mkdir -p -m 700 ~/.gnupg
  curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --import
  chmod 644 /tmp/onlyoffice.gpg
  sudo chown root:root /tmp/onlyoffice.gpg
  sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg

  # Add ONLYOFFICE Docs repository
  echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list

  # Add contrib to /etc/apt/sources.list
  sudo sed -i 's/main$/main contrib/' /etc/apt/sources.list

  # Update package manager cache
  sudo apt-get update

  # Install mscorefonts
  sudo apt-get install -y ttf-mscorefonts-installer

  # Install ONLYOFFICE Docs
  sudo apt-get install -y onlyoffice-documentserver

  # Switching ONLYOFFICE Docs to HTTPS using certbot
  onlyoffice_nginx_https_config_template="/etc/onlyoffice/documentserver/nginx/ds-ssl.conf.tmpl"
  sudo sed -i "s/80/$onlyoffice_port/g" "$onlyoffice_nginx_https_config_template"
  sudo bash /usr/bin/documentserver-letsencrypt.sh ${cert_email} ${onlyoffice_url}

  # Restart Nginx
  sudo service nginx restart

  # Update local.json config to enable WOPI server
  onlyoffice_nginx_config_path="/etc/nginx/conf.d/ds.conf"
  onlyoffice_config_path="/etc/onlyoffice/documentserver/local.json"
  onlyoffice_fs_secret=$(grep -m 1 -oP '(?<=set \$secure_link_secret ).*' "$onlyoffice_nginx_config_path" | rev | cut -c 2- | rev)

  onlyoffice_config='{
  "wopi": {
    "enable": true
  },
  "storage": {
    "fs": {
      "secretString": "'"$onlyoffice_fs_secret"'"
    }
  },
  "services": {
    "CoAuthoring": {
      "sql": {
        "type": "postgres",
        "dbHost": "'"${onlyoffice_db_host}"'",
        "dbPort": "5432",
        "dbName":  "'"${onlyoffice_db_name}"'",
        "dbUser":  "'"${onlyoffice_db_user}"'",
        "dbPass":  "'"${onlyoffice_db_password}"'"
      },
      "token": {
        "enable": {
          "request": {
            "inbox": true,
            "outbox": true
          },
          "browser": true
        },
        "inbox": {
          "header": "Authorization"
        },
        "outbox": {
          "header": "Authorization"
        }
      },
      "secret": {
        "inbox": {
          "string": "'"${onlyoffice_jwt_secret}"'"
        },
        "outbox": {
          "string": "'"${onlyoffice_jwt_secret}"'"
        },
        "session": {
          "string": "'"${onlyoffice_jwt_secret}"'"
        }
      }
    }
  }
}'

  sudo truncate -s 0 "$onlyoffice_config_path"
  echo "$onlyoffice_config" | sudo tee "$onlyoffice_config_path" >/dev/null

  # Append ONLYOFFICE environment variables to ocis.env
  {
    echo "APP_PROVIDER_WOPI_APP_NAME=OnlyOffice"
    echo "APP_PROVIDER_WOPI_APP_URL=https://${onlyoffice_url}"
    echo "APP_PROVIDER_WOPI_APP_ICON_URI=https://${onlyoffice_url}/web-apps/apps/documenteditor/main/resources/img/favicon.ico"
  } | sudo tee -a /etc/ocis/ocis.env

  # Create oCIS app-registry.yaml for ONLYOFFICE
  sudo bash -c 'cat > /etc/ocis/config/app-registry.yaml' <<EOF
# Supported mime types
app_registry:
  mimetypes:
    - mime_type: application/vnd.openxmlformats-officedocument.wordprocessingml.document
      extension: docx
      name: Microsoft Word
      description: Microsoft Word document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
    - mime_type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      extension: xlsx
      name: Microsoft Excel
      description: Microsoft Excel document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
    - mime_type: application/vnd.openxmlformats-officedocument.presentationml.presentation
      extension: pptx
      name: Microsoft PowerPoint
      description: Microsoft PowerPoint document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
    - mime_type: application/vnd.oasis.opendocument.text
      extension: odt
      name: OpenDocument
      description: OpenDocument text document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
    - mime_type: application/vnd.oasis.opendocument.spreadsheet
      extension: ods
      name: OpenSpreadsheet
      description: OpenDocument spreadsheet document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
    - mime_type: application/vnd.oasis.opendocument.presentation
      extension: odp
      name: OpenPresentation
      description: OpenDocument presentation document
      icon: ""
      default_app: OnlyOffice
      allow_creation: true
EOF

  # Restart ONLYOFFICE services
  sudo systemctl daemon-reload
  sudo systemctl restart ds-*

  # Restart ownCloud
  sudo systemctl restart ocis
fi
