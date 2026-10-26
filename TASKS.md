# BeanStream dbt — Task cards

> **Tasks 2–7, in order.** Task 1 is in [`START-HERE.md`](START-HERE.md). Each card here is a
> standalone runbook: it states what must already exist, what this task adds, and the exact checks.
> **Live state:** [`STATUS.md`](STATUS.md). Do not infer your starting point from a card; run its
> **What must already exist** check.

## 🧭 How to use this file

- Open **only the card for your current task**. Do not read ahead to “get the idea.”
- Every card starts with **Where you are** and **What must already exist**.
- Run the prerequisite checks before writing SQL. If one fails, stop and fix it; do not guess.
- The cards use `source()` for raw tables and `ref()` for models. Terms are in
  [`docs/glossary.md`](docs/glossary.md).
- You write the models, YAML, tests, and commands. The reference is an answer key, not a shortcut.
- Run every command from `~/projects/beanstream-dbt`.
- If a file already exists, inspect it against the card before changing it. Keep the correct parts and
  fix only the deviation; never create a second version.
- Stop at each gate and post the handoff. Do not start the next card early.

## 🗺️ Card map

| Card | Adds | The previous card’s output must include | Gate |
|---|---|---|---|
| [Task 2](#task-2) | Four staging views | Four declared sources + `stg_customers` | 12 / 120 / 270 / 4 |
| [Task 3](#task-3) | Four dimensions | All five staging views running | 40 / 12 / 4 / 362 |
| [Task 4](#task-4) | `fct_sales` | Four dimensions passing tests | 270 lines |
| [Task 5](#task-5) | Tests + KPI seed | Fact + dimensions built | 95 checks; 7,261.50 / 99 / 448 |
| [Task 6](#task-6) | Incremental fact | Full build green | 270 after reruns |
| [Task 7](#task-7) | Evidence + publication | Incremental fact green | Public repo + green CI |

---

<a id="task-2"></a>
## 🪜 Task 2 — Remaining staging views

**Outcome:** add the other four staging views. No dimensions, fact, or marts yet.
**Timebox:** 45–60 minutes · **Prerequisite:** the Task 1 checks below must pass · **Review gate:** yes

### 📍 Where you are

Task 1 declared the four raw sources and built `stg_customers`. This card adds `stg_products`,
`stg_orders`, `stg_order_items`, and `stg_channels`. It does **not** add dimensions or the fact.
There is no raw `channels` table; the channel view is derived from `orders`.

### ✅ What must already exist

| Path | Must contain |
|---|---|
| `models/staging/beanstream/_beanstream__sources.yml` | Sources `customers`, `products`, `orders`, `order_items`; no `channels` |
| `models/staging/beanstream/stg_customers.sql` | A working customer staging model |
| `models/staging/beanstream/_beanstream__models.yml` | A `stg_customers` block |

Check the files and the customer model:

```bash
for f in models/staging/beanstream/_beanstream__sources.yml models/staging/beanstream/stg_customers.sql models/staging/beanstream/_beanstream__models.yml; do test -f "$f" || { echo "MISSING: $f"; exit 1; }; done
grep -n "name: customers\|name: products\|name: orders\|name: order_items" models/staging/beanstream/_beanstream__sources.yml
.venv/bin/dbt run --profiles-dir . --select stg_customers
docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_customers;"
```

**Expected:** the three files exist, the grep shows four source names, the model succeeds, and the count
is `40`. If any check fails, stop and return to [`START-HERE.md`](START-HERE.md); do not build Task 2 on
a broken Task 1.

### 🚦 Before you start

```bash
cd ~/projects/beanstream-dbt
.venv/bin/dbt debug --profiles-dir .
```

**Expected:** `All checks passed!`. If not, fix the environment before writing code.

### 🗂️ What to create

| Path | Purpose |
|---|---|
| `models/staging/beanstream/stg_products.sql` | Clean product extract |
| `models/staging/beanstream/stg_orders.sql` | Clean order header |
| `models/staging/beanstream/stg_order_items.sql` | Clean order lines + line amount |
| `models/staging/beanstream/stg_channels.sql` | Distinct channel list with IDs |
| `models/staging/beanstream/_beanstream__models.yml` | Add descriptions and tests for the four new models |

If any of these files already exist, compare them with the contracts below and fix only the
differences. Do not create a second models YAML.

### 📥 Input contract

Use `source('beanstream_raw', '<table>')` for every **raw table**. There is no raw `channels`
table and no channels CSV: `stg_channels` is derived from the `orders` source.

| Source table | Grain | Rows | Key columns |
|---|---|---:|---|
| `products` | one product | 12 | `product_id` |
| `orders` | one order header | 120 | `order_id`, FK `customer_id` |
| `order_items` | one order line | 270 | `order_item_id`, FKs `order_id`, `product_id` |

**Naming rule:** `orders.channel` means the `channel` column of the **source table** `orders`. After
staging, write `stg_orders.channel`. Never write a bare `channel = channel` join, and never declare a
`channels` source.

Raw columns:

- `products`: `product_id`, `product_name`, `category`, `unit_price`, `active`, `_loaded_at`
- `orders`: `order_id`, `customer_id`, `order_date`, `status`, `channel`, `_loaded_at`
- `order_items`: `order_item_id`, `order_id`, `product_id`, `quantity`, `unit_price`, `_loaded_at`

Do not include `_loaded_at` in any staging model.

### 📤 Output contract

**`stg_products`** — 12 rows, one per product:

| Column | Type | Rule |
|---|---|---|
| `product_id` | integer | Cast to integer |
| `product_name` | text | Trim whitespace |
| `category` | text | Trim whitespace |
| `unit_price` | numeric(10,2) | Cast |
| `active` | boolean | Unchanged |

**`stg_orders`** — 120 rows, one per order:

| Column | Type | Rule |
|---|---|---|
| `order_id` | integer | Cast to integer |
| `customer_id` | integer | Cast to integer |
| `order_date` | date | Cast to date |
| `order_status` | text | `status`, trimmed then lowercased |
| `channel` | text | Trimmed then lowercased |

**`stg_order_items`** — 270 rows, one per order line:

| Column | Type | Rule |
|---|---|---|
| `order_item_id` | integer | Cast to integer |
| `order_id` | integer | Cast to integer |
| `product_id` | integer | Cast to integer |
| `quantity` | integer | Cast to integer |
| `unit_price` | numeric(10,2) | Cast |
| `line_amount` | numeric | `round(quantity * unit_price, 2)` |

**`stg_channels`** — 4 rows, one per distinct `orders.channel` value (no source table):

| Column | Type | Rule |
|---|---|---|
| `channel_id` | integer | `row_number()` ordered by `channel`, cast to integer |
| `channel` | text | Distinct channel value, trimmed/lowercased |

Expected IDs: `app=1`, `partner=2`, `retail=3`, `web=4`. Do not hardcode them; derive them
alphabetically so the result is deterministic.

Do not filter cancelled orders. Do not join `order_items` to `orders` or `products`; that belongs in
the fact.

### 🔒 Rules

- Every model starts from its source CTE; no `select *` in the final select.
- Keep the declared column order.
- `stg_channels` is the only staging model that derives rows rather than cleaning them.
- It reads `source('beanstream_raw', 'orders')`; do not add a `channels` source.
- Update the existing `_beanstream__models.yml`; add a one-line description for each model.

### 🧪 Test contract — add in step 6

In `_beanstream__models.yml`:

- `stg_products`: `product_id` not null + unique; `unit_price` and `active` not null.
- `stg_orders`: `order_id` not null + unique; `customer_id` not null; `order_status` accepted values
  `completed`, `shipped`, `pending`, `cancelled`; `channel` accepted values `web`, `app`, `retail`,
  `partner`.
- `stg_order_items`: `order_item_id` not null + unique; `order_id`, `product_id`, `quantity`,
  `unit_price`, `line_amount` not null.
- `stg_channels`: `channel_id` not null + unique; `channel` not null + unique.

Use `data_tests`, not the deprecated `tests` key. On dbt 1.10+, put generic-test arguments under
`arguments:`; otherwise dbt 1.12 warns with `MissingArgumentsPropertyInGenericTestDeprecation`:

```yaml
- accepted_values:
    arguments:
      values: ["web", "app", "retail", "partner"]
      quote: true
```

If `quote: true` is present, it must move under `arguments:` too. Leaving either key at the top level
keeps the dbt 1.12 deprecation warning.

### 🪜 Steps

1. Inspect the three raw tables before writing SQL:

   ```bash
   head -n 4 data/raw/products.csv
   head -n 4 data/raw/orders.csv
   head -n 4 data/raw/order_items.csv
   docker compose exec -T postgres psql -U learner -d warehouse -c "select 'products' as table, count(*) from raw_beanstream.products union all select 'orders', count(*) from raw_beanstream.orders union all select 'order_items', count(*) from raw_beanstream.order_items;"
   ```

   **Expected:** headers match the contract; counts are 12 / 120 / 270.

2. Build `stg_products.sql`, then run and count it:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select stg_products
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_products;"
   ```

   **Expected:** run succeeds; count `12`.

3. Build `stg_orders.sql`, then run and count it:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select stg_orders
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_orders;"
   ```

   **Expected:** run succeeds; count `120`.

4. Build `stg_order_items.sql`, then run and count it:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select stg_order_items
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_order_items;"
   ```

   **Expected:** run succeeds; count `270`.

5. Build `stg_channels.sql`: in one CTE select **distinct** `trim(lower(channel))` from
   `source('beanstream_raw', 'orders')`; in a **separate** final select assign
   `row_number() over (order by channel)::integer` as `channel_id`. Do not put `distinct` and
   `row_number()` in the same `select`: the window function is evaluated before `distinct`, so every
   order row gets a different number and the model returns 120 rows instead of 4. Run and count it:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select stg_channels
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_channels;"
   ```

   **Expected:** run succeeds; count `4`. If it fails because `beanstream_raw.channels` is missing,
   the source is wrong: use the `orders` source.

6. Add the four model blocks and the tests from the test contract to `_beanstream__models.yml`.
7. Run the staging layer:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select staging
   .venv/bin/dbt test --profiles-dir . --select staging
   ```

   **Expected:** `Completed successfully`; tests show `ERROR=0`.

8. Prove the row counts and the channel IDs:

   ```bash
   docker compose exec -T postgres psql -U learner -d warehouse -c "select 'products' as model, count(*) from staging.stg_products union all select 'orders', count(*) from staging.stg_orders union all select 'order_items', count(*) from staging.stg_order_items union all select 'channels', count(*) from staging.stg_channels;"
   docker compose exec -T postgres psql -U learner -d warehouse -c "select channel_id, channel from staging.stg_channels order by channel_id;"
   ```

   **Expected counts:** `products=12`, `orders=120`, `order_items=270`, `channels=4`.
   **Expected channels:** `1|app`, `2|partner`, `3|retail`, `4|web`.

### 🏁 Definition of done

- [ ] Four model files exist and use `source()`.
- [ ] `staging` models run and all staging tests pass with `ERROR=0`.
- [ ] Counts are 12 / 120 / 270 / 4.
- [ ] Channel IDs are deterministic and match the expected order.
- [ ] `line_amount` is rounded to 2 decimals and is not null.
- [ ] You can explain why the channel IDs are derived, not hardcoded.

### 🛑 Stop conditions

Stop if any count differs, any key is duplicated, any test fails without a clear first error, or you
are about to add a dimension or fact. Do not continue to Task 3.

### 📬 Handoff

Post the four model files, the YAML changes, the run/test output, the count table, the channel-ID table,
and one sentence explaining why `line_amount` belongs in staging.

**Next:** [Task 3](TASKS.md#task-3), locked until this gate passes.

---

<a id="task-3"></a>
## 🪜 Task 3 — Four dimensions

**Outcome:** build `dim_customer`, `dim_product`, `dim_channel`, and `dim_date`.
**Timebox:** 45–60 minutes · **Prerequisite:** the Task 2 checks below must pass · **Review gate:** yes

### 📍 Where you are

Task 2 produced the five staging views: `stg_customers`, `stg_products`, `stg_orders`,
`stg_order_items`, and `stg_channels`. This card turns them into four dimensions. It does **not**
build `fct_sales` or add KPI tests.

### ✅ What must already exist

| Path | Must contain |
|---|---|
| `models/staging/beanstream/stg_customers.sql` | Customer staging view |
| `models/staging/beanstream/stg_products.sql` | Product staging view |
| `models/staging/beanstream/stg_orders.sql` | Order-header staging view |
| `models/staging/beanstream/stg_order_items.sql` | Order-line staging view |
| `models/staging/beanstream/stg_channels.sql` | Derived channel view |

Check the staging layer:

```bash
.venv/bin/dbt run --profiles-dir . --select staging
docker compose exec -T postgres psql -U learner -d warehouse -c "select 'customers' as model, count(*) from staging.stg_customers union all select 'products', count(*) from staging.stg_products union all select 'orders', count(*) from staging.stg_orders union all select 'order_items', count(*) from staging.stg_order_items union all select 'channels', count(*) from staging.stg_channels;"
```

**Expected:** all five models run; counts are `40 / 12 / 120 / 270 / 4`. If `stg_channels` fails,
fix the Task 2 source before continuing.

### 🚦 Before you start

```bash
.venv/bin/dbt debug --profiles-dir .
```

**Expected:** `All checks passed!`.

### 🗂️ What to create

| Path | Purpose |
|---|---|
| `models/marts/dim_customer.sql` | Customer dimension |
| `models/marts/dim_product.sql` | Product dimension |
| `models/marts/dim_channel.sql` | Channel dimension |
| `models/marts/dim_date.sql` | Calendar dimension |
| `models/marts/_marts__models.yml` | Descriptions and tests |

### 📥 Input contract

| Model | Input | Grain | Rows |
|---|---|---|---:|
| `dim_customer` | `ref('stg_customers')` | one customer | 40 |
| `dim_product` | `ref('stg_products')` | one product | 12 |
| `dim_channel` | `ref('stg_channels')` | one channel | 4 |
| `dim_date` | `ref('stg_orders')` | one day in the order range | 362 |

### 📤 Output contract

**`dim_customer`** — one row per customer:

| Column | Type | Rule |
|---|---|---|
| `customer_id` | integer | From staging |
| `full_name` | text | `first_name || ' ' || last_name` |
| `email` | text | From staging |
| `city` | text | From staging |
| `country` | text | From staging |
| `signup_date` | date | From staging |

**`dim_product`** — one row per product:

| Column | Type | Rule |
|---|---|---|
| `product_id` | integer | From staging |
| `product_name` | text | From staging |
| `category` | text | From staging |
| `unit_price` | numeric(10,2) | Current catalog price, from staging |

**`dim_channel`** — one row per channel:

| Column | Type | Rule |
|---|---|---|
| `channel_id` | integer | From `stg_channels` |
| `channel` | text | From `stg_channels` |

**`dim_date`** — one row per day:

| Column | Type | Rule |
|---|---|---|
| `date_id` | integer | `YYYYMMDD` |
| `full_date` | date | Calendar date |
| `year` | integer | Calendar year |
| `quarter` | integer | 1–4 |
| `month` | integer | 1–12 |
| `month_name` | text | `FMMonth` |
| `day` | integer | Day of month |
| `day_of_week` | integer | ISO: Monday=1, Sunday=7 |
| `day_name` | text | `FMDay` |
| `is_weekend` | boolean | ISO day 6 or 7 |
| `month_start` | date | First day of the month |

`dim_date` must derive its bounds from `min(order_date)` and `max(order_date)` in `stg_orders`. Do not
hardcode the range.

### 🪜 Steps

1. Build `dim_customer.sql`: select from `ref('stg_customers')`; concatenate the name.
2. Build `dim_product.sql` and `dim_channel.sql`: pass through the staged columns; do not re-clean.
3. Build `dim_date.sql`:
   - CTE `bounds`: min/max `order_date` from `stg_orders`.
   - CTE `days`: `generate_series(min_date, max_date, interval '1 day')::date`.
   - Final select: derive every date field from `full_date`.
4. Add `_marts__models.yml` with descriptions and tests. Use `data_tests` with an underscore;
   `data-tests` with a hyphen is silently ignored by dbt and produces **zero** tests:
   - customer: `customer_id` not null + unique; `full_name`, `email`, `signup_date` not null.
   - product: `product_id` not null + unique; `product_name`, `category`, `unit_price` not null.
   - channel: `channel_id` not null + unique; `channel` not null + unique.
   - date: `date_id` not null + unique; `full_date` not null + unique; `month_start` not null.
5. Run and test only the dimensions:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select dim_customer dim_product dim_channel dim_date
   .venv/bin/dbt test --profiles-dir . --select dim_customer dim_product dim_channel dim_date
   ```

   **Expected:** `Completed successfully`; `ERROR=0`.

6. Prove counts and the date range:

   ```bash
   docker compose exec -T postgres psql -U learner -d warehouse -c "select 'dim_customer' as model, count(*) from marts.dim_customer union all select 'dim_product', count(*) from marts.dim_product union all select 'dim_channel', count(*) from marts.dim_channel union all select 'dim_date', count(*) from marts.dim_date;"
   docker compose exec -T postgres psql -U learner -d warehouse -c "select min(full_date), max(full_date), min(date_id), max(date_id), count(distinct date_id) from marts.dim_date;"
   ```

   **Expected counts:** 40 / 12 / 4 / 362.
   **Expected range:** `2024-01-01` to `2024-12-27`; `date_id` 20240101 to 20241227; 362 distinct IDs.

### 🏁 Definition of done

- [ ] Four dimension files exist and use `ref()`.
- [ ] All dimension tests pass with `ERROR=0`.
- [ ] Counts are 40 / 12 / 4 / 362.
- [ ] `dim_date` is derived from order dates, not a hardcoded list.
- [ ] You can explain why `dim_product.unit_price` is not the historical line price.

### 🛑 Stop conditions

Stop if the date range is wrong, a key is duplicated, a count differs, or you are about to build
`fct_sales`. Do not continue to Task 4.

### 📬 Handoff

Post the four models, the YAML, the test output, the count table, the date-range output, and one
sentence explaining the grain of each dimension.

**Next:** [Task 4](TASKS.md#task-4), locked until this gate passes.

---

<a id="task-4"></a>
## 🪜 Task 4 — `fct_sales`

**Outcome:** build one fact table at order-line grain, joined to the dimensions.
**Timebox:** 45–60 minutes · **Prerequisite:** the Task 3 checks below must pass · **Review gate:** yes

### 📍 Where you are

The staging views and four dimensions exist. This card adds one table, `fct_sales`, at one row per
order line. It does **not** add KPI tests or change the materialisation to incremental.

### ✅ What must already exist

| Model | Expected rows |
|---|---:|
| `staging.stg_order_items` | 270 |
| `staging.stg_orders` | 120 |
| `marts.dim_date` | 362 |
| `marts.dim_channel` | 4 |

Check the dimensions:

```bash
.venv/bin/dbt run --profiles-dir . --select dim_customer dim_product dim_channel dim_date
docker compose exec -T postgres psql -U learner -d warehouse -c "select 'dim_customer' as model, count(*) from marts.dim_customer union all select 'dim_product', count(*) from marts.dim_product union all select 'dim_channel', count(*) from marts.dim_channel union all select 'dim_date', count(*) from marts.dim_date;"
```

**Expected:** `40 / 12 / 4 / 362`. If a dimension is missing or has the wrong count, stop and finish
Task 3 first.

### 🚦 Before you start

```bash
.venv/bin/dbt debug --profiles-dir .
```

**Expected:** connection passes.

### 🗂️ What to create

| Path | Purpose |
|---|---|
| `models/marts/fct_sales.sql` | Sales fact, one row per order line |
| `models/marts/_marts__models.yml` | Add the fact description and tests |

### 📥 Input contract

| Input | Grain | Use |
|---|---|---|
| `ref('stg_order_items')` | one order line | Fact grain and measures |
| `ref('stg_orders')` | one order header | Date, customer, channel, status |
| `ref('dim_date')` | one day | Resolve `date_id` |
| `ref('dim_channel')` | one channel | Resolve `channel_id` |

Join line to order on `order_id`; date on `dim_date.full_date = stg_orders.order_date`; channel on
`dim_channel.channel = stg_orders.channel`. Never use the bare `channel = channel` join.

### 📤 Output contract

`marts.fct_sales` — **270 rows**, one row per order line:

| Column | Type | Rule |
|---|---|---|
| `order_item_id` | integer | Primary key |
| `order_id` | integer | Degenerate dimension |
| `date_id` | integer | FK to `dim_date` |
| `customer_id` | integer | FK to `dim_customer` |
| `product_id` | integer | FK to `dim_product` |
| `channel_id` | integer | FK to `dim_channel` |
| `order_status` | text | From the order header |
| `quantity` | integer | From the line |
| `unit_price` | numeric(10,2) | Price charged on the line |
| `line_amount` | numeric | Rounded line value |

Rules:

- Keep cancelled orders in the fact. Do not add a status filter.
- Do not aggregate. One row per `order_item_id`.
- Do not join `dim_customer` or `dim_product` just to copy names; use their keys.
- Materialisation for this task is the project default (`table`). Incremental is Task 6.

### 🧪 Test contract — add in step 2

In `_marts__models.yml`:

- `order_item_id`: not null + unique.
- `order_id`: not null.
- `date_id`, `customer_id`, `product_id`, `channel_id`: not null + `relationships` to their
  dimensions. Put `to` and `field` under `arguments:`:
  ```yaml
  - relationships:
      arguments:
        to: ref('dim_date')
        field: date_id
  ```
- `order_status`: accepted values `completed`, `shipped`, `pending`, `cancelled`.
- `quantity`, `unit_price`, `line_amount`: not null.

### 🪜 Steps

1. Build `fct_sales.sql`:
   - CTE `order_lines`: line joined to order header, carrying date, customer, channel, status, and
     measures.
   - CTE `final`: join `dim_date` and `dim_channel`; select the contract columns.
   - Final `select` from `final`.
2. Add the fact block and tests to `_marts__models.yml`.
3. Run and test the fact:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select fct_sales
   .venv/bin/dbt test --profiles-dir . --select fct_sales+
   ```

   **Expected:** `Completed successfully`; 16/16 tests pass. The trailing `+` is required because the
   tests are children of `fct_sales`; `--select fct_sales` alone selects no tests.

4. Prove the grain and cancellation rule:

   ```bash
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) as fact_rows, count(distinct order_item_id) as distinct_lines, count(distinct order_id) as orders from marts.fct_sales;"
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(distinct order_id) from marts.fct_sales where order_status = 'cancelled';"
   ```

   **Expected:** 270 fact rows, 270 distinct lines, 120 distinct orders, 21 cancelled orders.
   **Expected null check:** `select count(*) from marts.fct_sales where date_id is null or channel_id is null;` returns `0`.

### 🏁 Definition of done

- [ ] `fct_sales` has exactly 270 rows and 270 distinct `order_item_id`.
- [ ] All four dimension keys resolve; no null `date_id` or `channel_id`.
- [ ] Cancelled orders remain in the fact.
- [ ] Fact tests pass with `ERROR=0` when selected as `fct_sales+`.
- [ ] The final `select` lists columns; no `select *`.
- [ ] You can explain why `order_id` is a degenerate dimension.

### 🛑 Stop conditions

Stop if the row count changes, a dimension key is null, a relationship test fails, or you are about to
add KPI tests. Do not continue to Task 5.

### 📬 Handoff

Post the fact model, the YAML, the run/test output, the grain query, the cancellation query, and one
sentence explaining why the fact has 270 rows but only 99 non-cancelled orders.

**Next:** [Task 5](TASKS.md#task-5), locked until this gate passes.

---

<a id="task-5"></a>
## 🪜 Task 5 — Tests + KPI reconciliation

**Outcome:** prove the warehouse matches the published KPIs with tests, not inspection.
**Timebox:** 45–60 minutes · **Prerequisite:** the Task 4 checks below must pass · **Review gate:** yes

### 📍 Where you are

`fct_sales` exists at 270 order lines and the four dimensions exist. This card adds the KPI seed,
three singular tests, and the missing foreign-key/vocabulary tests. It does **not** make the fact
incremental.

### ✅ What must already exist

| Model | Expected rows |
|---|---:|
| `marts.fct_sales` | 270 |
| `marts.dim_customer` | 40 |
| `marts.dim_product` | 12 |

Check the current build:

```bash
.venv/bin/dbt build --profiles-dir .
docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from marts.fct_sales;"
```

**Expected:** `ERROR=0`; the count is `270`. If this fails, stop and finish Task 4 first.

### 🚦 Before you start

No extra environment check; the build above is the check.

### 🗂️ What to create

| Path | Purpose |
|---|---|
| `seeds/expected_kpis.csv` | Published KPI targets |
| `tests/assert_kpi_reconciliation.sql` | Compares actuals to the seed |
| `tests/assert_line_amount.sql` | Recomputes every line amount |
| `tests/assert_positive_quantity.sql` | Rejects zero/negative units |
| `models/staging/beanstream/_beanstream__sources.yml` | Add FK and vocabulary tests |
| `models/marts/_marts__models.yml` | Add any missing fact tests |

### 📥 Input contract

- `marts.fct_sales`: 270 rows at order-line grain; cancelled orders included.
- `marts.dim_customer`: 40 rows; `marts.dim_product`: 12 rows.
- Published KPI targets: revenue 7261.50, orders 99, units 448, customers 40, products 12.

### 📤 Output contract

- `seeds.expected_kpis`: 5 rows, one per metric.
- Three singular tests plus the key/vocabulary tests pass.
- Each singular test returns **zero rows** on success.
- `dbt build` reports `ERROR=0`.

### 🌱 Seed contract

`seeds/expected_kpis.csv` must contain exactly:

```csv
metric,expected
revenue,7261.50
orders,99
units,448
customers,40
products,12
```

`schema.yml` for the seed is optional; the seed values must remain numeric-compatible.

### 📊 KPI contract

Revenue, orders, and units use `where order_status <> 'cancelled'`.

| Metric | Definition | Target |
|---|---|---:|
| Revenue | `round(sum(line_amount), 2)` | 7261.50 |
| Orders | `count(distinct order_id)` | 99 |
| Units | `sum(quantity)` | 448 |
| Customers | `count(*)` from `dim_customer` | 40 |
| Products | `count(*)` from `dim_product` | 12 |

Derived checks, not seed rows — add assertions for these; the seed reconciliation does not cover them:

| Metric | Definition | Target |
|---|---|---:|
| AOV | revenue / orders | 73.35 |
| Cancellation rate | cancelled orders / all orders | 17.5% |
| Customers with orders | distinct customers in fact | 39 |

### 🧪 Test contract — create in steps 1–3

1. **KPI reconciliation** — `tests/assert_kpi_reconciliation.sql`:
   - `actual` CTE: one row per **seed metric** — revenue, orders, units, customers, products. A
     `case` over only revenue/orders/units makes customers/products compare `NULL`, which does not
     fail the test.
   - `expected` CTE: read `ref('expected_kpis')` — **not** `ref('seeds.expected_kpis')`;
     that form does not register the test.
   - Final select returns only mismatches where `abs(actual - expected) > 0.01`.
   - Passing means **zero rows**.
2. **Line amount** — `tests/assert_line_amount.sql`:
   - Select lines where `abs(line_amount - (quantity * unit_price)) > 0.01`.
   - Passing means zero rows.
3. **Positive quantity** — `tests/assert_positive_quantity.sql`:
   - Select rows where `quantity <= 0`.
   - Passing means zero rows.
4. **Foreign keys** — in source YAML, add `relationships` tests. Use `source(...)` for source-to-source
   references, not `ref('customers')`; a `ref()` to a non-model relation does not create a test:
   ```yaml
   - relationships:
       arguments:
         to: source('beanstream_raw', 'customers')
         field: customer_id
   ```
   - `orders.customer_id` → `customers.customer_id`
   - `order_items.order_id` → `orders.order_id`
   - `order_items.product_id` → `products.product_id`
   Do **not** add `orders.product_id`; the raw orders table has no such column.
5. **Vocabularies** — source or model YAML:
   - order status in `completed`, `shipped`, `pending`, `cancelled`
   - channel in `web`, `app`, `retail`, `partner`

Use `data_tests`, not `tests`, and put arguments under `arguments:` (for example
`relationships: {arguments: {to: ..., field: ...}}`). This project runs dbt 1.12, where top-level
generic-test arguments produce a deprecation warning.

### 🪜 Steps

1. Create the seed CSV exactly as above.
2. Create the three singular tests.
3. Add the relationship and vocabulary tests.
4. Build everything:

   ```bash
   .venv/bin/dbt build --profiles-dir .
   ```

   **Expected:** `Completed successfully`; `ERROR=0`. With the full test set, expect `PASS=95`; if your
   count differs, list the changed tests before claiming the gate.

5. Prove the KPI query directly:

   ```bash
   docker compose exec -T postgres psql -U learner -d warehouse -c "select round(sum(line_amount), 2) as revenue, count(distinct order_id) as orders, sum(quantity) as units from marts.fct_sales where order_status <> 'cancelled';"
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from seeds.expected_kpis;"
   ```

   **Expected:** `7261.50 | 99 | 448` and 5 seed rows.

6. Confirm the KPI test returns no rows:

   ```bash
   .venv/bin/dbt test --profiles-dir . --select assert_kpi_reconciliation
   ```

   **Expected:** `PASS`.

### 🏁 Definition of done

- [ ] Seed has the five required metrics and targets.
- [ ] Three singular tests exist and pass.
- [ ] Foreign-key and vocabulary tests exist.
- [ ] `dbt build` finishes with `ERROR=0`.
- [ ] Revenue / orders / units are 7261.50 / 99 / 448.
- [ ] The reconciliation test returns zero rows.

### 🛑 Stop conditions

Stop if a KPI differs, a relationship test fails, the seed has different values, or you are tempted to
“fix” the expected CSV to match a wrong result. Do not continue to Task 6.

### 📬 Handoff

Post the seed, all test files, the YAML changes, the `dbt build` summary, the KPI query, and one
sentence naming the business rule that makes the order count 99, not 120.

**Next:** [Task 6](TASKS.md#task-6), locked until this gate passes.

---

<a id="task-6"></a>
## 🪜 Task 6 — Incremental behaviour + failure drill

**Outcome:** make `fct_sales` incremental, prove idempotency, and debug one deliberate failure.
**Timebox:** 45–60 minutes · **Prerequisite:** the Task 5 checks below must pass · **Review gate:** yes

### 📍 Where you are

The full build is green, including the KPI reconciliation, and `fct_sales` is a table with 270 rows.
This card changes only its materialisation and adds a temporary failure drill. It does **not** change
the grain, columns, or cancellation rule.

### ✅ What must already exist

| Item | Expected |
|---|---|
| `marts.fct_sales` | 270 rows, table materialisation |
| `tests/assert_kpi_reconciliation.sql` | Present and passing |
| `seeds/expected_kpis.csv` | 5 metric rows |

Check the starting build:

```bash
.venv/bin/dbt build --profiles-dir .
docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from marts.fct_sales;"
```

**Expected:** `ERROR=0`; `270` rows. If KPI tests fail, stop and finish Task 5 first.

### 🚦 Before you start

The `dbt build` above is the environment check; there is no separate command.

### 🗂️ What to create or change

| Path | Change |
|---|---|
| `models/marts/fct_sales.sql` | Add incremental config and filter |
| `tests/assert_failure_drill.sql` | Temporary failure test for the drill |

### 📥 Input contract

- Existing `marts.fct_sales`: table materialisation, 270 rows, one per order line.
- Stable key: `order_item_id`; max ID 270.
- No changes to columns, grain, tests, or the cancellation rule.

### 📤 Output contract

- `fct_sales` becomes incremental with `delete+insert` on `order_item_id`.
- First rebuild: 270 rows. Second and third runs: still 270, no duplicates.
- `--full-refresh`: still 270.
- The deliberate failure is observed, diagnosed, and removed.

### ⚙️ Required config

Add to the top of `fct_sales.sql`:

```jinja
{{ config(
    materialized='incremental',
    unique_key='order_item_id',
    incremental_strategy='delete+insert',
    on_schema_change='append_new_columns'
) }}
```

Add at the end:

```jinja
{% if is_incremental() %}
where order_item_id > (select coalesce(max(order_item_id), 0) from {{ this }})
{% endif %}
```

Rules:

- The grain stays one row per order line.
- The filter appends only new line IDs.
- Do not drop cancelled rows.
- Do not change the fact columns.

### 🪜 Steps

1. Add the config and filter.
2. Seed the new materialisation once:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select fct_sales --full-refresh
   ```

   **Expected:** table rebuilt; 270 rows.

3. Run it twice normally:

   ```bash
   .venv/bin/dbt run --profiles-dir . --select fct_sales
   .venv/bin/dbt run --profiles-dir . --select fct_sales
   ```

   **Expected:** both runs succeed; the count stays 270.

4. Prove idempotency:

   ```bash
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) as rows, count(distinct order_item_id) as distinct_lines, max(order_item_id) as max_id from marts.fct_sales;"
   ```

   **Expected:** 270 rows, 270 distinct lines, max ID 270.

5. Run the failure drill:
   - Create `tests/assert_failure_drill.sql` containing:

     ```sql
     select *
     from {{ ref('fct_sales') }}
     where quantity > 0
     ```

   - Run:

     ```bash
     .venv/bin/dbt test --profiles-dir . --select assert_failure_drill
     ```

     **Expected:** the test **fails** and reports rows. Read the first error line; note the test name,
     the model, and the failing condition.
   - Delete `tests/assert_failure_drill.sql`.
   - Rerun `dbt test --profiles-dir . --select assert_positive_quantity`.
   - **Expected:** pass.

6. Rebuild the full project and check the count again:

   ```bash
   .venv/bin/dbt build --profiles-dir .
   .venv/bin/dbt build --profiles-dir . --full-refresh
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from marts.fct_sales;"
   ```

   **Expected:** both builds pass; count remains 270.

### 🏁 Definition of done

- [ ] `fct_sales` is incremental with the required config and filter.
- [ ] Two normal runs keep the count at 270; no duplicate line IDs.
- [ ] `--full-refresh` also returns 270.
- [ ] The deliberate failure was observed, read, and removed.
- [ ] `dbt build` still passes with `ERROR=0`.
- [ ] You can explain why `delete+insert` is safe here and what a late-arriving correction needs.

### 🛑 Stop conditions

Stop if the second run doubles the table, if a normal run changes the 270-row contract, if a correction
is silently dropped, or if you leave the failure-drill test in place. Do not continue to Task 7.

### 📬 Handoff

Post the final model, the two-run counts, the full-refresh count, the failure-drill output, and one
paragraph explaining the failure you caused and how you diagnosed it.

**Next:** [Task 7](TASKS.md#task-7), locked until this gate passes.

---

<a id="task-7"></a>
## 🪜 Task 7 — Evidence + publication

**Outcome:** make the project publicly verifiable: real screenshots, green CI, accurate README, public
repo.
**Timebox:** 60–90 minutes · **Prerequisite:** the Task 6 checks below must pass · **Review gate:** yes

### 📍 Where you are

The project builds and tests cleanly, and `fct_sales` is incremental and idempotent. This card adds the
public evidence: screenshots, CI, case study, README results, and the public repository. It does **not**
change the model grain or KPI logic.

### ✅ What must already exist

| Item | Expected |
|---|---|
| Local build | `dbt build` passes with 95 checks |
| Fact | 270 rows after two incremental runs |
| Docs site | `dbt docs generate` succeeds |
| Screenshots folder | `screenshots/README.md` exists |

Check the starting point:

```bash
.venv/bin/dbt build --profiles-dir .
.venv/bin/dbt docs generate --profiles-dir .
docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from marts.fct_sales;"
```

**Expected:** `ERROR=0`; docs generate; `270` rows. If the build is red, stop and finish Task 6 first.

### 🚦 Before you start

The build and docs commands above are the environment check; there is no separate command.

### 🗂️ What to create or update

| Path | Action |
|---|---|
| `README.md` | Replace pending targets with verified results; add real evidence |
| `STATUS.md` | Record build, CI, screenshots, publication |
| `screenshots/01-lineage.png` | Lineage graph |
| `screenshots/02-model-detail.png` | `fct_sales` model detail |
| `screenshots/03-kpi-query.png` | KPI query result |
| `screenshots/README.md` | Capture date, command, page, caption |
| `.github/workflows/dbt-ci.yml` | Clean-build CI |
| `CASE-STUDY.md` | Problem → decision → result → lesson |
| Public repo | GitHub repository |

### 📥 Input contract

- A verified local build: `dbt build` with `ERROR=0` and the Task 5 KPI values.
- A generated docs site: `dbt docs generate` and `make serve`.
- No pending screenshots or claims in the README.

### 📤 Output contract

- Public repository URL that resolves.
- Green CI run URL.
- Three real screenshots with captions and capture records.
- README, STATUS, and case study agreeing on the same verified numbers.
- No secrets, `.venv`, `target`, `logs`, or `profiles.yml` in the published repo.

### 📸 Screenshot contract

Capture only after the build passes:

1. `make docs` then `make serve`; open `http://localhost:8080`.
2. Capture the lineage graph from raw to marts as `01-lineage.png`.
3. Open `fct_sales`; capture columns, descriptions, and tests as `02-model-detail.png`.
4. Run the KPI query in `psql`; capture the result grid as `03-kpi-query.png`.
5. Crop out desktop clutter, secrets, personal data, and absolute local paths.
6. Record date, command, page, and caption in `screenshots/README.md`.

Terminal output is better as text. Put the `dbt build` summary and KPI query in fenced code blocks, not
screenshots.

### 🧪 CI contract

Create `.github/workflows/dbt-ci.yml` that:

- runs on push and pull request;
- starts PostgreSQL 16 with user `learner`, password `learner`, database `warehouse`;
- waits for the database health check;
- installs Python 3.10 and `requirements.txt`;
- runs `python scripts/load_raw.py`;
- copies `profiles.example.yml` to `profiles.yml`;
- runs `dbt build --profiles-dir .`;
- fails the job on any model or test failure.

Use this file as the starting point; adapt paths only if the project moved:

```yaml
name: dbt CI

on:
  push:
  pull_request:

jobs:
  dbt:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: learner
          POSTGRES_PASSWORD: learner
          POSTGRES_DB: warehouse
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U learner -d warehouse"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 12
    env:
      PGHOST: localhost
      PGPORT: 5432
      PGUSER: learner
      PGPASSWORD: learner
      PGDATABASE: warehouse
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.10"
      - run: pip install -r requirements.txt
      - run: python scripts/load_raw.py
      - run: |
          cp profiles.example.yml profiles.yml
          dbt build --profiles-dir .
```

Do not add a CI badge until a run is actually green.

### 🚀 Publication steps

1. Update `README.md` with the actual verified counts and KPI table; do not keep “pending” claims.
2. Update `STATUS.md` with build, screenshots, CI, and publication state.
3. Write `CASE-STUDY.md`: context, constraint, decisions, result, what you would change.
4. Add the three screenshots and captions.
5. Initialize git in the project root, review `git status`, and commit only source, data, docs, and
   screenshots:

   ```bash
   git init
   git add .
   git status
   git commit -m "Build BeanStream dbt transformation layer"
   ```

   Do not commit `.venv/`, `target/`, `logs/`, `profiles.yml`, or secrets.
6. Publish the working copy through the Windows mirror, excluding local artifacts:

   ```bash
   rsync -a --exclude '.venv/' --exclude 'target/' --exclude 'logs/' --exclude 'profiles.yml' \
     <project-root>/ <publish-copy>/
   ```

   If `rsync` is unavailable, copy the folder in Explorer and remove those four items manually.
7. Create the public GitHub repository named **`beanstream-dbt`** under the `malikb0` account. Expected
   URL: `https://github.com/malikb0/beanstream-dbt`.
8. From the published copy, add the remote and push:

   ```bash
   git remote add origin https://github.com/malikb0/beanstream-dbt.git
   git branch -M main
   git push -u origin main
   ```

9. Wait for the GitHub Actions run. Fix failures until it is green.
10. Record the public URL and CI run URL.

### 🏁 Definition of done

- [ ] README numbers match a fresh `dbt build`; no target is presented as a result.
- [ ] Three real screenshots exist, are captioned, and are linked.
- [ ] `screenshots/README.md` records the capture details.
- [ ] CI is green on the public repository.
- [ ] `CASE-STUDY.md` exists and is accurate.
- [ ] Public URL resolves and contains no secrets or local paths.
- [ ] `STATUS.md` and README agree on status.
- [ ] The repo can be cloned and built from the README without your local files.

### 🛑 Stop conditions

Stop if a claim has no evidence, a screenshot is stale or fake, CI is red, the repo contains
`.venv`/`target`/`profiles.yml`, or the public README still says “pending.” Do not call it published
until the URL and CI both resolve.

### 📬 Handoff

Post the public URL, the green CI run URL, the README result table, the three screenshot paths, and one
paragraph on the hardest decision you made in the project. Then the agent reviews publication and
updates the CV evidence ledger.
