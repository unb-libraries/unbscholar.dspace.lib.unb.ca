# Scheduled jobs

DSpace maintenance jobs run as **Kubernetes CronJobs** in the prod cluster,
not as in-container cron. There is no longer a cron daemon in this image and
no `build/scripts/dspace_cron` file — both were removed when the schedule
moved to Kubernetes.

## Canonical source

The schedule lives in the `kubernetes-metadata` repo:

```
services/unbscholar.lib.unb.ca/03_backend/unbscholar.dspace.lib.unb.ca.Values.prod.yaml
```

To add, remove, or reschedule a job, edit `additionalCronJobs:` in that file
and `helm upgrade`. Do not add a crontab here.

## Current schedule

| Schedule (UTC) | Command | Purpose |
|---|---|---|
| `1,16,31,46 * * * *` | `dspace filter-media` | media filtering, every 15 min |
| `6,21,36,51 * * * *` | `dspace index-authority` | authority index, every 15 min |
| `11,26,41,56 * * * *` | `dspace index-discovery` | incremental Solr reindex, every 15 min |
| `0 1 1 * *` | `dspace cleanup` | monthly DB cleanup |
| `10 4 * * *` | `dspace generate-sitemaps` | nightly sitemap (output on shared NFS) |
| `10 4 * * *` | `dspace oai import` | nightly OAI harvest |
| `10 5 * * *` | `dspace stats-util -i` | nightly stats init |
| `10 6 * * *` | `dspace subscription-send -f D` | daily email digest |
| `0 3 * * 0` | `dspace subscription-send -f W` | weekly email digest |
| `0 2 1 * *` | `dspace subscription-send -f M` | monthly email digest |
| `0 4 * * 0` | `dspace index-discovery --build` | weekly full Solr rebuild |
| `0 5 * * 0` | `dspace index-discovery --clean` | weekly Solr cleanup |

The staggered :01/:06/:11 cadence on the three 15-minute jobs is intentional
(commit `0758d57`) — keep that pattern if adding new every-15-minute jobs.

## How a cron pod runs

Each CronJob reuses the DSpace image and invokes
`build/scripts/cron-entrypoint.sh`, which:

1. Runs `pre-init.d/40_wait_for_postgres.sh` (waits for Postgres).
2. Runs `pre-init.d/50_update_dspace_config.sh` (substitutes env-var
   placeholders in `local.cfg`).
3. `exec`s `/dspace/bin/dspace "$@"` with the subcommand from the
   CronJob's `args:`.

JAVA_OPTS is overridden per job in the values file (cron pods don't need
the webapp's 6 GiB heap).

## Operational notes

- **Logs**: `kubectl logs job/<name>` captures the CLI's stdout/stderr.
  DSpace's log4j2 file output goes to `/dspace/log/` inside the cron pod
  and is discarded when the pod exits — don't look for `dspace.log`
  files in cron pods.
- **Sitemaps**: written to `/dspace/sitemaps/`, which is a shared NFS RWX
  volume so the webapp deployment can serve them at `/sitemap_index.xml`.
  If sitemaps disappear, check the volume.
- **Deploy windows**: a cron pod that fires while a webapp upgrade is
  running may see a half-migrated DB and exit non-zero.
  `startingDeadlineSeconds: 300` keeps K8s from backfilling more than
  one missed run.
