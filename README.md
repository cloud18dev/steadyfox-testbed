# Steadyfox testbed

A controlled environment for comparing monitoring tools (Healthchecks.io, Better Stack, Cronitor, Hyperping, UptimeRobot) before building Steadyfox. Every tool watches the same fake job and the same fake website, and you decide what breaks. That means you always know what each tool *should* have caught.

- **Fake job**: a GitHub Actions workflow that runs every 15 minutes and reports to each tool's heartbeat URL ([`job.sh`](job.sh)).
- **Fake website**: a Cloudflare Worker whose behaviour you switch from the terminal ([`worker/`](worker/)).
- **Scorecard**: where results go ([`scorecard.md`](scorecard.md)).

## Setup

### 1. Alerts

Send every tool's alerts to **one place**, such as a single email address or a throwaway Slack channel, so alert times are easy to compare.

### 2. Cron monitors (fake job)

In each tool, create one cron/heartbeat monitor with the **same settings**: period **15 min**, grace **10 min**. Then add its ping URL as a repo secret:

| Tool | Secret | URL to use |
| --- | --- | --- |
| Healthchecks.io | `HC_URL` | `https://hc-ping.com/<uuid>` |
| Cronitor | `CRONITOR_URL` | Telemetry URL: `https://cronitor.link/p/<api-key>/<monitor-key>` |
| Better Stack | `BETTERSTACK_URL` | Heartbeat URL, e.g. `https://incidents.betterstack.com/api/v1/heartbeat/<token>` |
| Hyperping | `HYPERPING_URL` | Ping URL from the cron monitor's settings |
| UptimeRobot | — | Heartbeats likely need a paid plan, so use UptimeRobot for the uptime half only |

```bash
gh secret set HC_URL -R cloud18dev/steadyfox-testbed   # paste the URL when prompted
```

A tool without a secret is skipped. The URLs stay out of the code, so the repo can be public: Actions minutes are unlimited on public repos, while a private repo would use up the 2,000 free minutes in about a week.

### 3. Uptime monitors (fake website)

```bash
cd worker
npx wrangler login
npx wrangler kv namespace create STATE     # paste the printed id into wrangler.toml
npx wrangler deploy                        # prints the https://steadyfox-testbed.<you>.workers.dev URL
npx wrangler kv key put --binding=STATE mode up --remote
```

In every tool, add an HTTP monitor for the Worker URL with the same interval and timeout, plus a keyword check for `OK` where supported. For SSL alerts, also add [expired.badssl.com](https://expired.badssl.com) and [self-signed.badssl.com](https://self-signed.badssl.com).

## Running scenarios

### Job scenarios

```bash
gh variable set SCENARIO --body fail -R cloud18dev/steadyfox-testbed           # all scheduled runs
gh workflow run fake-job -R cloud18dev/steadyfox-testbed -f scenario=hang      # one run now
```

| Scenario | What happens | Tests |
| --- | --- | --- |
| `success` | start → 20–40 s → success with 100–199 records | Baseline. Any alert is a false alarm |
| `slow` | start → 4 min → success | Duration alerts (about 8× normal) |
| `zero` | start → success with 0 records | "Ran but did nothing" |
| `fail` | start → fail signal | Explicit failure |
| `hang` | start, never finishes | Started-but-not-completed detection |
| `skip` | no ping at all | Missed run |
| `random` | 70% success, plus a mix of the others | Realistic noise over days |

Each run writes `<timestamp> scenario=<name>` to its run summary in the Actions tab. That's your ground truth.

### Website modes

```bash
npx wrangler kv key put --binding=STATE mode down --remote   # from worker/
```

| Mode | Behaviour | Tests |
| --- | --- | --- |
| `up` | 200 with `OK` | Baseline |
| `down` | 500 | Basic outage |
| `slow` | 15 s delay | Timeouts and slow-response alerts |
| `flaky` | 30% of requests return 503 | False alarms vs confirmation |
| `eu-down` | 503 only for checks from Europe | Multi-region confirmation |
| `broken` | 200 with an error page | Keyword checks |

KV changes can take up to about 60 seconds to reach every region, so note the time you switched. `npx wrangler tail` shows each check's user agent and region, which tells you how often each tool really checks and from where.

## Plan (about 2 weekends)

| When | What |
| --- | --- |
| Days 1–3 | Everything on `success` / `up`. Any alert is a false alarm; tools also learn normal durations |
| Weekend 1 | One job scenario per 1–2 hours: `fail`, `hang`, `skip`, `slow`, `zero` |
| Weekend 2 | One website mode per hour: `down`, `slow`, `flaky`, `eu-down`, `broken` |
| Next week | `SCENARIO=random` and `flaky` in the background |

## Caveats

- GitHub delays scheduled runs under load, so expect occasional "late" alerts that are GitHub's fault. Check the run's start time before blaming the tool.
- `fail` exits 0 on purpose. A red workflow makes GitHub email you, which would mix GitHub's notifications into the comparison.
- GitHub disables scheduled workflows in public repos after 60 days without repository activity.
- Ping endpoints come from each tool's documentation at the time of writing. If a tool rejects a ping, check the warning in the run log.
