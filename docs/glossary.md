# BeanStream dbt — Glossary

BeanStream is a fictional coffee-subscription retailer. This page defines the words the task cards
use, so no card depends on prior conversation or prior reading.

## 🔤 Core terms

| Term | Meaning in this project |
|---|---|
| **Raw table** | A table loaded directly from a CSV into `raw_beanstream`; it is not a dbt model. |
| **Source** | A dbt declaration for a raw table. Read it with `source('beanstream_raw', 'orders')`. |
| **Model** | A SQL file in `models/` that dbt turns into a view or table. Read another model with `ref('stg_orders')`. |
| **Staging model** | A cleaning model. It renames, casts, trims, and lowercases; it does not join business entities or aggregate. |
| **Mart model** | A reporting model in `marts/`: dimensions and facts. |
| **Grain** | What one row represents. `stg_orders` has one row per order; `fct_sales` has one row per order line. |
| **Primary key** | The column(s) that identify one row. `stg_orders.order_id` is the order key. |
| **Foreign key** | A column that points to another model’s key. `fct_sales.customer_id` points to `dim_customer`. |
| **Surrogate key** | A generated integer key, such as `dim_channel.channel_id`. It is not a business code. |
| **Degenerate dimension** | An identifier kept in the fact with no separate dimension table, such as `fct_sales.order_id`. |
| **Dimension** | A descriptive table: customer, product, channel, or date. |
| **Fact** | A measurement table at a declared grain. `fct_sales` stores one line per order item. |
| **Star schema** | A fact table surrounded by dimension tables that it references by key. |
| **Date spine** | A generated row for every date in a range; here, one row per day from the first to the last order. |
| **CTE** | A named `with` block inside a SQL query. |
| **Join** | Combining rows from two tables on a matching key. Qualify both sides, e.g. `dim_channel.channel = stg_orders.channel`. |
| **Materialisation** | How dbt stores a model: `view`, `table`, or `incremental`. |
| **Incremental** | A model that adds or updates only changed rows instead of rebuilding everything. |
| **Idempotent** | Running the same command twice produces the same result, not duplicate rows. |
| **Seed** | A CSV in `seeds/` loaded as a table; `expected_kpis.csv` is the KPI target list. |
| **Generic test** | A reusable dbt test such as `not_null`, `unique`, `accepted_values`, or `relationships`. |
| **Singular test** | A one-off SQL test in `tests/`; it passes when it returns zero rows. |
| **KPI** | A published business number: revenue, orders, units, AOV, cancellation rate. |
| **AOV** | Average order value: revenue divided by non-cancelled orders. |

## 🧱 Project layers

| Layer | Schema | What it contains | Who writes it |
|---|---|---|---|
| Raw | `raw_beanstream` | Four loaded CSV tables | Provided loader |
| Staging | `staging` | Cleaned source-shaped views | You |
| Marts | `marts` | Dimensions and `fct_sales` | You |
| Seeds | `seeds` | Expected KPI targets | You |

There is no raw `channels` table. `stg_channels` is derived from distinct `orders.channel` values.

## ⌨️ Commands

| Command | What it does |
|---|---|
| `dbt debug --profiles-dir .` | Checks the database connection and project config. |
| `dbt parse --profiles-dir .` | Parses the project without running models. |
| `dbt run --profiles-dir . --select <model>` | Builds one model or a selection. |
| `dbt test --profiles-dir . --select <model>` | Runs tests for a model or selection. |
| `dbt build --profiles-dir .` | Runs seeds, models, and tests in dependency order. |
| `dbt docs generate --profiles-dir .` | Builds the documentation site data. |
| `dbt compile --profiles-dir . --select <model>` | Renders SQL without running it. |

In this lab, use `.venv/bin/dbt` so you do not depend on a global install.

## 🧭 Reading rule

You do **not** need to read every document to start a task. Open the card for the task you are doing;
its **Where you are** and **What must already exist** sections tell you the starting state. If a check
fails, stop and fix that prerequisite before writing SQL.
