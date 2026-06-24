# ValKey Fly.io deployment

## STAGING — echo-valkey-staging. Deploy with:  fly deploy -c fly.staging.toml

Sized for < 5000 simultaneous players; same durable posture as prod, smaller machine.

```bash
fly apps create echo-valkey-staging
fly volumes create valkey_staging_data --region fra --size 10 -a echo-valkey-staging
fly secrets set VALKEY_PASSWORD="$(openssl rand -base64 32)" -a echo-valkey-staging
fly deploy -c fly.staging.toml
```