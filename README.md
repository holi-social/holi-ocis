# holi-ocis

oCIS ownCloud Infinite Scale

## Local execution

As Ory does not allow to redirect to localhost URLs, you have to add the following host entries to your `/etc/hosts`:

```sh
127.0.0.1 local.cloud.holi.social
127.0.0.1 local.traefik.holi.social
127.0.0.1 local.wopiserver.holi.social
127.0.0.1 local.onlyoffice.holi.social
```

Then you can run

```sh
docker compose up
```

to start OCIS locally and access it under `local.cloud.holi.social` (ignore invalid SSL certificates).
