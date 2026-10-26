# BeanStream dbt — Operator guide

BeanStream is a fictional coffee-subscription retailer. This is the runbook for the learning lab:
setup, commands, reset, and troubleshooting. For the next task, use [STATUS](../STATUS.md) and the
active card; this guide does not repeat the task contracts.

## 🚀 First run

```bash
cd ~/projects/beanstream-dbt
make setup
make up
make raw
```

Expected raw counts:

```text
customers: 40
order_items: 270
orders: 120
products: 12
```

The lab may have no models at Task 1 and several later models after Task 2. That is normal. Check
[STATUS](../STATUS.md) before assuming the project is empty.

## 🧰 Everyday commands

| Command | Use |
|---|---|
| `.venv/bin/dbt parse --profiles-dir .` | Check project syntax |
| `.venv/bin/dbt run --profiles-dir . --select stg_customers` | Run one model |
| `.venv/bin/dbt test --profiles-dir . --select stg_customers` | Test one model |
| `.venv/bin/dbt build --profiles-dir .` | Run everything you have built |
| `make full-refresh` | Rebuild the incremental fact |
| `make docs` | Generate the dbt catalog |

Use dbt commands directly while learning. `make build` is only a shortcut once you understand what it
runs.

### Which command for which task

| Active task | Command |
|---|---|
| Task 1 | `dbt run --select stg_customers` |
| Task 2 | `dbt run --select staging` |
| Task 3 | `dbt run --select dim_customer dim_product dim_channel dim_date` |
| Task 4 | `dbt run --select fct_sales` |
| Tasks 5–6 | `dbt build` |
| Task 7 | `dbt build` and `dbt docs generate` |

`dbt` here means `.venv/bin/dbt --profiles-dir .`. Need a definition? Use the
[glossary](glossary.md).

## 🧹 Reset

Stop the database but keep its data:

```bash
make down
```

Drop the dbt schemas and start over:

```bash
docker compose exec postgres psql -U learner -d warehouse \
  -c 'drop schema if exists staging cascade; drop schema if exists marts cascade; drop schema if exists seeds cascade;'
```

Reload raw data:

```bash
make raw
```

`make raw` only replaces `raw_beanstream`; it does not touch your dbt schemas.

## 🧯 Troubleshooting

| Symptom | Check |
|---|---|
| `dbt: command not found` | `make setup`; use `.venv/bin/dbt` |
| connection refused | `make up`; confirm port `5434` |
| `relation does not exist` | Run the model that creates it first |
| test fails | Read the first failing row, then inspect the model grain |
| duplicate key | Check the join or the `group by` |

## 🧭 Review

When a task is done, post:

1. the model file,
2. the command output,
3. one sentence explaining the grain and key.

Then stop and wait for review.
