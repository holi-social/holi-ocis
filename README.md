# holi-ocis

oCIS ownCloud Infinite Scale

## Local execution

As Ory does not allow to redirect to localhost URLs, you have to add the following host entries to your `/etc/hosts`:

```sh
127.0.0.1 local.cloud.project-holi.org
127.0.0.1 traefik.cloud.project-holi.org
```

Then you can run

```sh
docker compose up
```

to start OCIS locally and access it under `local.cloud.project-holi.org` (ignore invalid SSL certificates).
