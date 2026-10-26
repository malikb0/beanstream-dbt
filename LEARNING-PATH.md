# BeanStream dbt — Learning path

> Seven stages from raw CSVs to a tested, published dbt project. Each stage has a review gate. Do not
> skip a gate to “get it finished.”
>
> This page is the **map**. Read the card for your active task only: Task 1 is in
> [`START-HERE.md`](START-HERE.md); Tasks 2–7 are in [`TASKS.md`](TASKS.md). Each card states its
> starting state, so you do not need to read the whole map or every earlier card first.
>
> **Live state:** [STATUS.md](STATUS.md) · **Terms:** [glossary](docs/glossary.md).

**Rule:** you write the substantive work. The agent reviews, hints, and unblocks.

---

## 🪜 Task 1 — Sources + `stg_customers`

**Start:** [Task 1 card](START-HERE.md).

**Build:** `_beanstream__sources.yml`, `stg_customers.sql`, `_beanstream__models.yml`.

**Run:** `dbt run --select stg_customers` and its tests.

**Gate:** 40 rows; unique, non-null customer key; clean column names and types.

**Practice:** source declarations, grain, renaming, casting, testing the key.

---

<a id="task-2"></a>

## 🪜 Task 2 — Remaining staging views

**Card:** [Task 2](TASKS.md#task-2).

**Build:** `stg_products`, `stg_orders`, `stg_order_items`, `stg_channels` (this brings the staging
layer to five views including `stg_customers`).

**Run:** `dbt run --select staging` and `dbt test --select staging`.

**Gate:** 12 products, 120 orders, 270 lines, 4 channels; no duplicate keys.

**Practice:** reusable cleaning, status/channel vocabularies, line amount calculation.

---

## 🪜 Task 3 — Four dimensions

**Card:** [Task 3](TASKS.md#task-3).

**Build:** `dim_customer`, `dim_product`, `dim_channel`, `dim_date`.

**Run:** `dbt run --select dim_customer dim_product dim_channel dim_date` and the same selection for
`dbt test`.

**Gate:** 40 / 12 / 4 / 362 rows; unique keys; no nulls; date spine covers the order range.

**Practice:** star-schema design, deterministic keys, date spine.

**Review question:** why is `dim_date` derived from orders rather than hardcoded?

---

## 🪜 Task 4 — `fct_sales`

**Card:** [Task 4](TASKS.md#task-4).

**Build:** one row per order line, joined to all four dimensions.

**Run:** `dbt run --select fct_sales`.

**Gate:** 270 rows; every dimension key resolves; cancelled orders remain in the fact.

**Practice:** fact grain, join correctness, degenerate dimensions.

---

## 🪜 Task 5 — Tests + KPI reconciliation

**Card:** [Task 5](TASKS.md#task-5).

**Build:** source tests, model tests, relationship tests, and the KPI seed check.

**Run:** `dbt build`.

**Gate:** 95 checks pass; revenue 7,261.50, orders 99, units 448, AOV 73.35.

**Practice:** testing contracts, not just writing SQL.

---

## 🪜 Task 6 — Incremental behaviour + failure drill

**Card:** [Task 6](TASKS.md#task-6).

**Build:** make the fact incremental with a safe unique key and filter.

**Run:** `dbt build`, run it again, then `dbt build --full-refresh`.

**Gate:** row count stays 270 after a second run; full refresh also returns 270.

**Failure drill:** deliberately break one test, read the first error, fix it, and record what happened.

**Practice:** idempotency, incremental logic, debugging from evidence.

---

## 🪜 Task 7 — Evidence + publication

**Card:** [Task 7](TASKS.md#task-7).

**Build:** final README results, screenshots, case study, CI, public repo.

**Gate:** every claim links to a verified result; CI is green; repo is public.

**Practice:** showing the work, not just doing it.

---

## 🧭 Review protocol

1. You finish a task and paste the command output.
2. The agent reviews the model, tests, and reasoning.
3. The agent gives one of: pass, targeted hint, or revision request.
4. Only then do you start the next task.

The reference implementation is at `~/projects/beanstream-dbt-reference`. It opens after Task 7, or
earlier only if the agent explicitly says to compare.
