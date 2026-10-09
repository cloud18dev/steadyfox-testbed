# Scorecard

Fill in one row per tool. For scenario cells, record: **✅ / ❌**, time to alert, and a note on whether the alert was clear and whether a recovery notice came.

## Setup

| Tool | Plan used | Setup time | Config needed / friction | First impressions |
| --- | --- | --- | --- | --- |
| Healthchecks.io | | | | |
| Better Stack | | | | |
| Cronitor | | | | |
| Hyperping | | | | |
| UptimeRobot | | | | |

## Baseline (days 1–3): false alarms

| Tool | Job false alarms | Website false alarms | Notes |
| --- | --- | --- | --- |
| Healthchecks.io | | | |
| Better Stack | | | |
| Cronitor | | | |
| Hyperping | | | |
| UptimeRobot | n/a | | |

## Job scenarios

| Tool | `fail` | `hang` | `skip` | `slow` | `zero` |
| --- | --- | --- | --- | --- | --- |
| Healthchecks.io | | | | | |
| Better Stack | | | | | |
| Cronitor | | | | | |
| Hyperping | | | | | |

## Website modes

| Tool | `down` | `slow` | `flaky` | `eu-down` | `broken` | SSL (badssl) |
| --- | --- | --- | --- | --- | --- | --- |
| Healthchecks.io | n/a | n/a | n/a | n/a | n/a | n/a |
| Better Stack | | | | | | |
| Cronitor | | | | | | |
| Hyperping | | | | | | |
| UptimeRobot | | | | | | |

## Check frequency and regions (from `wrangler tail`)

Sample: 10 minutes on 9 Oct 2026, 13:12–13:22 UTC, default settings.

| Tool | Checks per hour | Regions seen | User agent |
| --- | --- | --- | --- |
| Better Stack | ~120 (20 in 10 min, 5 per region) | SG, AU, DE, US | `Better Stack Better Uptime Bot …`, GET |
| Cronitor | not identified in sample | | |
| Hyperping | ~120 (20 in 10 min) | US, IN, FR, KR, NL, CA, GB, SG, DE, JP (rotating) | `Hyperping/1.0`, GET |
| UptimeRobot | ~12 (every 5 min) | US only | `UptimeRobot/2.0`, **HEAD** (plain HTTP monitor, can't see page content) |

## Takeaways for Steadyfox

- What every tool does well (table stakes):
- What most tools miss (gaps to build on):
- Best onboarding moment worth copying:
- Worst friction worth avoiding:
