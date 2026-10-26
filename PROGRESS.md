# BeanStream dbt — Progress

> **Agent handoff — read this first.** This file is the project-local session state. Do not scan the
> CV workspace or unrelated project directories while working on this dbt project.
>
> `STATUS.md` remains the user-facing source of truth. This file keeps the same gate state plus the
> commands and review details needed to resume quickly.

**Last updated:** 2026-10-26
**Active gate:** Complete — published
**Docs check:** `PROJECT DOCS: OK` (screenshot warning only)

## 🚦 Current state

| Area | State |
|---|---|
| Task 1 — sources + `stg_customers` | ✅ passed |
| Task 2 — staging views | ✅ passed; 28/28 tests |
| Task 3 — four dimensions | ✅ passed; tests run |
| Task 4 — `fct_sales` | ✅ passed; 16/16 fact tests |
| Task 5 — KPI tests | ✅ passed; 95/95 checks |
| Task 6 — incremental | ✅ passed; idempotent 270 rows |
| Task 7 — evidence + publication | ✅ passed; public repo + green CI |

## ✅ Verified evidence

- Staging row counts: **40 / 12 / 120 / 270 / 4**.
- `stg_channels`: **1=app, 2=partner, 3=retail, 4=web**.
- Dimensions: **40 / 12 / 4 / 362**.
- `dim_date`: **2024-01-01** to **2024-12-27**; IDs **20240101–20241227**.
- `fct_sales`: **270 rows / 270 line keys / 120 orders**.
- Non-cancelled: **230 lines / 99 orders / 448 units / $7,261.50**.
- Cancelled: **40 lines / 21 orders**, retained in the fact.
- Missing dimension keys: **0** for date, customer, product, and channel.
- Direct KPI query: **$7,261.50 / 99 orders / 448 units**; AOV **$73.35**; cancellation **17.5%**.
- `dbt build`: **PASS=95** — 1 seed + 10 models + 84 tests.
- `fct_sales` is incremental (`delete+insert`, `unique_key=order_item_id`).
- Full refresh → 270 rows; two normal runs → `INSERT 0 0` each; final **270 / 270 / max 270**.
- KPI reconciliation covers all five seed metrics; AOV 73.35, cancellation 17.5%, customers with orders 39.
- Temporary failure-drill test is absent; positive-quantity test passes.
- Three screenshots captured: lineage, model detail, KPI query.
- Public repo and CI green: https://github.com/malikb0/beanstream-dbt
- No deprecation warnings.

## 🚧 Open cleanup

None. Task 7 is complete and published.

## ▶️ Next session

1. Extend CI with a schedule and dependency cache.
2. Add model contracts/exposures and a late-arriving correction test.
3. Keep the README, screenshots, and CI badge current.

## 🧪 Useful commands

```bash
# Staging
.venv/bin/dbt test --profiles-dir . --select staging --no-partial-parse

# All marts
.venv/bin/dbt test --profiles-dir . --select marts

# Full suite
.venv/bin/dbt test --profiles-dir . --no-partial-parse

# Fact grain
docker compose exec -T postgres psql -U learner -d warehouse \
  -c "select count(*) rows, count(distinct order_item_id) keys, count(distinct order_id) orders from marts.fct_sales;"

# Project docs only
python3 tools/check_project_docs.py .
```

## 📚 Read next

- `STATUS.md` — current gate and user-facing next action.
- `TASKS.md#task-7` — completed task card.
- `docs/data-dictionary.md` — KPI formulas and source contract.

Do not read CV-wide plans, trackers, or other projects unless the owner explicitly asks.

## 🕓 Progress log

| Date | Change |
|---|---|
| 2026-10-22 | Staging task cards rebuilt; Task 1 passed; Task 2 channel IDs corrected. |
| 2026-10-26 | Task 2 passed: 28/28 staging tests, no deprecation warning. |
| 2026-10-26 | Task 3 dimensions built; test YAML typo leaves them untested. |
| 2026-10-26 | Task 4 data verified: 270 lines, correct KPI totals; cleanup requested. |
| 2026-10-26 | Progress file created for project-local session handoff. |
| 2026-10-26 | Task 3–4 cleanup verified: 65/65 tests pass; Tasks 3–4 passed. |
| 2026-10-26 | Task 5 review: KPI test and source FKs registered; 90/95 checks; five KPI checks remain. |
| 2026-10-26 | Task 5 passed: 95/95 checks; all KPI assertions pass. |
| 2026-10-26 | Task 6 passed: incremental fact; two reruns idempotent at 270; 95/95 build. |
| 2026-10-26 | Task 7 passed: screenshots, README/case study, public repo, green CI. |
