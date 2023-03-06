FROM owncloud/ocis:latest

ARG OCIS_OIDC_ISSUER
ARG OCIS_OIDC_CLIENT_ID
ARG OCIS_DOMAIN
ARG OCIS_INSECURE

ENV PROXY_AUTOPROVISION_ACCOUNTS="true"
ENV PROXY_OIDC_REWRITE_WELLKNOWN="true"
ENV OCIS_OIDC_ISSUER="https://${OCIS_OIDC_ISSUER}"
ENV WEB_OIDC_CLIENT_ID="${OCIS_OIDC_CLIENT_ID}"
ENV OCIS_URL="https://${OCIS_DOMAIN}"
ENV OCIS_LOG_DRIVER="local"
ENV OCIS_LOG_LEVEL="info"
ENV OCIS_LOG_COLOR="false"
ENV OCIS_INSECURE="${OCIS_INSECURE}"

# Set fallback mount directory
ENV MNT_DIR /mnt/nfs/filestore

ENV OCIS_BASE_DATA_PATH="${MNT_DIR}"

# Install system dependencies
USER root

RUN addgroup -S app && adduser -S -G app app

RUN apk update && apk add --no-cache tini nfs-utils

# ENTRYPOINT ["/bin/sh", "-c", "ocis init || true; ocis server"]
# mount -o nolock $FILESTORE_IP_ADDRESS:/$FILE_SHARE_NAME $MNT_DIR

EXPOSE 9200

# Copy local code to the container image.
WORKDIR /app
COPY ./app ./app

USER app

# Use tini to manage zombie processes and signal forwarding
# https://github.com/krallin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Pass the startup script as arguments to tini
CMD ["/app/run.sh"]
