# BeanStream dbt — case study

BeanStream is a synthetic coffee-subscription retailer: 40 customers, 12 products, 120 orders, 270 order lines, four channels, and 2024-only data with seed 42. The design brief started with a working hand-written Python ETL and asked for the same warehouse in dbt, with the published KPIs preserved.

The interesting part was not the SQL. It was deciding what a row means, which rows belong in a revenue number, and how to make a second run safe.

## 🎯 The problem

The original transform worked, but its logic lived in one script and one person's memory. There was no lineage from a published KPI back to a source column, no declared grain, and no test that would fail when a business rule changed. A small edit could move revenue without anyone noticing until a report looked wrong.

The replacement had to preserve five numbers: revenue **$7,261.50**, orders **99**, units **448**, average order value **$73.35**, and an order cancellation rate of **17.5%**. It also had to make the path from four CSV files to those numbers visible and repeatable.

The dataset is deliberately small. That removes the excuse of scale and exposes the decisions that matter: grain, cancellation semantics, key integrity, and incremental correctness.

## 🧱 The constraint

The project had to run from a clean clone with Docker, `make`, and Python. PostgreSQL 16 runs locally on port `5434`; dbt connects with a copied profile. There was no cloud warehouse, no orchestrator, and no production traffic to hide behind.

The source is also incomplete in useful ways. There is no raw `channels` table, so the channel dimension has to be derived from distinct order values. One of the 40 customers never places an order. Order dates span only 2024-01-01 to 2024-12-27, so the date dimension has 362 rows rather than a full year. None of these are defects; they are the conditions the model has to respect.

## 🧠 Decisions

**Grain first.** `fct_sales` is one row per order line, keyed by `order_item_id`. That is the finest level the source provides and the only level at which quantity, unit price, and line amount are all additive. `order_id` stays in the fact as a degenerate dimension because the order header adds no useful separate attributes.

**Keep cancellations in the fact.** The fact contains all **270** lines, including **40 cancelled lines across 21 cancelled orders**. Deleting them during transformation would have made the cancellation rate impossible to audit and would have thrown away order history. Instead, the KPI layer filters `order_status <> 'cancelled'`. This is a deliberate trade-off: every downstream consumer has to apply that filter, and the tests guard it.

**Measure cancellation at order grain.** The published rate is **21 cancelled orders ÷ 120 orders = 17.5%**, not the share of cancelled lines. A line-share would move with basket size and answer a different question: what share of lines was cancelled. For orders, both numerator and denominator are distinct orders.

**Make identifiers deterministic.** `stg_channels` derives four channels from the orders and assigns IDs by alphabetical order: `app=1`, `partner=2`, `retail=3`, `web=4`. No hidden lookup table, no random surrogate key: the same source produces the same dimension on every rebuild.

**Bound the date spine to the data.** `dim_date` is generated from the minimum and maximum order dates, giving **362** rows and IDs in `YYYYMMDD` form. The text month and day names depend on the PostgreSQL locale, so numeric fields are the stable ones for logic.

**Test at three levels.** Source tests protect keys, foreign keys, and accepted values. Model tests protect dimension uniqueness and fact relationships. Singular tests protect line arithmetic, positive quantity, customer counts, and the five-metric KPI reconciliation. The final build is **95/95**: one seed, ten models, and 84 data tests.

**Keep the incremental path simple, and name its limit.** `fct_sales` is incremental with `delete+insert` on `order_item_id`. The filter is a high-water mark: `order_item_id > max(order_item_id)` in the target. Two normal reruns inserted **0** rows each and left **270 rows / 270 keys / max ID 270**; a full refresh returned **270** rows. This is correct for new lines, not for a corrected quantity or price on an existing line; that still requires `make full-refresh`.

## 📊 The result

Five staging views pass **28/28** tests. The dimensions have **40 / 12 / 4 / 362** rows. `fct_sales` has **270** rows, **270** unique order-item keys, and **120** orders. The non-cancelled subset has **230** lines, **99** orders, and **448** units. **39** of the 40 customers have at least one order.

`dbt build` completes with `PASS=95 WARN=0 ERROR=0`. The seeded KPI reconciliation passes. The GitHub Actions workflow starts PostgreSQL 16, loads the raw CSVs, and runs the same build. The [public run is green](https://github.com/malikb0/beanstream-dbt/actions/workflows/dbt-ci.yml).

## 🪞 The lesson

Most of the trust in this pipeline comes from decisions made before the tests were written. Naming the grain made the keys testable. Deciding that cancellations stay in the fact made the KPI filter explicit. Choosing order-grain cancellation made the metric match the question. The tests confirm those choices; they cannot rescue an ambiguous model.

The second lesson is that “idempotent” and “correct for every change” are different claims. The reruns are idempotent, but the high-water filter is only correct for append-only data. Naming that limit is part of the engineering.

## 🔧 What I would change

The next version would add an `updated_at` column to the source contract and change the fact to a merge or a bounded lookback window, so a corrected line is applied exactly once without a full refresh. I would also add model contracts and exposures for the KPI columns, then generate a larger synthetic feed and a correction batch to demonstrate the incremental limit instead of only documenting it.

The small-data choices were appropriate for this project. They are not a claim that the same design would handle a production feed without revisiting the incremental strategy, freshness checks, and orchestration.
