# BeanStream dbt — Start here

> **Your first assignment:** declare the four raw sources and build one staging model. Stop there.
> **Timebox:** 30–45 minutes · **Review gate:** yes · **Reference:** locked until the gate

## 🎬 Scenario

BeanStream is a fictional coffee-subscription retailer. Its Python ETL works, but no one else can
safely change it. You are rebuilding the transform in dbt so another analyst can trace, test, and
change it.

You have no prior context for this project. Everything you need for Task 1 is on this page.
Terms are defined in the [glossary](docs/glossary.md).

## 📍 Where you are

This is the **Task 1** card, kept as the starting point. If [STATUS.md](STATUS.md) says Task 1 is
done, do not restart it; open [`TASKS.md#task-2`](TASKS.md#task-2). If Tasks 2–6 are also passed,
open [`TASKS.md#task-7`](TASKS.md#task-7) for the active work. If a file already exists, compare it
with the contract instead of overwriting it blindly.

## ✅ What must already exist

- The four CSVs are in `data/raw/`.
- PostgreSQL is running and loaded with `raw_beanstream`.
- The dbt virtual environment exists at `.venv/`.

The checks in **Before you start** prove all three. If a check fails, stop and fix it before writing
SQL.

## 🧩 Problem

The raw tables are usable but not analyst-ready: names have stray spaces, email casing varies, and
nothing declares the grain or keys. Build the first trusted layer without changing the published
numbers.

## 🚦 Before you start

1. Open a terminal in the project root:

   ```bash
   cd ~/projects/beanstream-dbt
   pwd
   ```

   **Expected:** the repository root you cloned.

2. Check that Postgres is running and the raw data is loaded:

   ```bash
   docker compose ps
   docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from raw_beanstream.customers;"
   ```

   **Expected:** the `postgres` service is `Up`, and the count is `40`.

3. Check that dbt can connect:

   ```bash
   .venv/bin/dbt debug --profiles-dir .
   ```

   **Expected:** `All checks passed!`.

If a check fails, run `make up` and then `make raw`, and repeat the checks. If it still fails, stop and
post the full error. Do not start the task with a broken environment.

## 🎯 Your task

Declare the four raw sources and build **one** model: `stg_customers`.

Build only `stg_customers`. Do **not** create the other staging models, dimensions, fact table, tests
for later stages, or CI yet.

## 🗂️ What to create

| Path | Purpose |
|---|---|
| `models/staging/beanstream/_beanstream__sources.yml` | Declares the four raw tables and their first tests |
| `models/staging/beanstream/stg_customers.sql` | Cleans the customer extract |
| `models/staging/beanstream/_beanstream__models.yml` | Documents and tests `stg_customers` |

The folders may not exist yet. Create them with the files.

## 📥 Input contract

- **Source name:** `beanstream_raw`
- **Schema:** `raw_beanstream`
- **Table:** `customers`
- **Grain:** one row per customer
- **Note:** there is no `channels` table in this project; do not declare one.
- **Primary key:** `customer_id`
- **Rows:** 40

| Input column | Type | Rule |
|---|---|---|
| `customer_id` | integer | Primary key, not null |
| `first_name` | text | Not null |
| `last_name` | text | Not null |
| `email` | text | Not null |
| `city` | text | Not null |
| `country` | text | Not null |
| `signup_date` | date | Not null |
| `_loaded_at` | timestamptz | Load metadata; exclude from the model |

## 📤 Output contract

`staging.stg_customers` must have exactly these columns, in this order:

| Output column | Type | Rule |
|---|---|---|
| `customer_id` | integer | Cast to integer |
| `first_name` | text | Trim whitespace |
| `last_name` | text | Trim whitespace |
| `email` | text | Trim, then lowercase |
| `city` | text | Trim whitespace |
| `country` | text | Trim whitespace |
| `signup_date` | date | Cast to date |

**Expected row count:** 40. **Expected grain:** one row per customer. Do not add `_loaded_at`, joins,
calculated segments, or extra columns.

## 🪜 Steps

### 1. Inspect the source

Run:

```bash
head -n 4 data/raw/customers.csv
```

You should see the seven business columns and no blank lines. The `_loaded_at` column exists only in
Postgres, not in the CSV.

### 2. Declare the sources

Create `models/staging/beanstream/_beanstream__sources.yml`.

Start from this shape and complete it:

```yaml
version: 2

sources:
  - name: beanstream_raw
    schema: raw_beanstream
    tables:
      - name: customers
        columns:
          - name: customer_id
```

Requirements:

- Declare all four tables: `customers`, `products`, `orders`, `order_items`.
- Use source name `beanstream_raw` exactly.
- Add a one-line description to each table that states its grain.
- On `customers.customer_id`, add `not_null` and `unique` tests.
- On `customers.email` and `customers.signup_date`, add `not_null` tests.
- Do not add tests to the other three tables yet.

Use `data_tests`, not the deprecated `tests` key.

**Checkpoint:**

```bash
.venv/bin/dbt parse --profiles-dir .
```

**Expected:** no error and no deprecation warning.

### 3. Write `stg_customers`

Create `models/staging/beanstream/stg_customers.sql`.

Requirements:

- Use `{{ source('beanstream_raw', 'customers') }}`; do not read `raw_beanstream.customers` directly.
- Use a CTE, then select from it.
- Explicitly cast `customer_id` to `integer` and `signup_date` to `date`.
- Trim names, city, and country; trim then lowercase email.
- Select only the seven output columns from the contract, in order.
- Do not use `select *`.
- Do not filter rows; all 40 customers must remain.

### 4. Add model tests

Create `models/staging/beanstream/_beanstream__models.yml`.

Add tests for `stg_customers`:

- `customer_id`: `not_null` and `unique`
- `email`: `not_null`
- `country`: `not_null`

Use `data_tests`, not `tests`. Add a one-line model description that states the grain.

### 5. Run and test

```bash
.venv/bin/dbt run --profiles-dir . --select stg_customers
.venv/bin/dbt test --profiles-dir . --select stg_customers
.venv/bin/dbt test --profiles-dir . --select source:beanstream_raw.customers
```

**Expected:** every command ends with `Completed successfully`; the test commands show `ERROR=0`.

### 6. Prove the result

```bash
docker compose exec -T postgres psql -U learner -d warehouse -c "select count(*) from staging.stg_customers;"
```

**Expected:** `40`.

## 🏁 Definition of done

- [ ] All three files exist at the exact paths above.
- [ ] `.venv/bin/dbt parse --profiles-dir .` passes without a deprecation warning.
- [ ] `.venv/bin/dbt run --profiles-dir . --select stg_customers` succeeds.
- [ ] Both test commands pass with `ERROR=0`.
- [ ] `staging.stg_customers` has exactly **40** rows and the seven contract columns in order.
- [ ] You can explain the grain, the key, and why each cleaned column was trimmed, lowered, or cast.

## 🛑 Stop conditions

Stop and ask for review if:

- `dbt debug` fails before you write code;
- the model returns anything other than 40 rows;
- `customer_id` has duplicates or nulls;
- a test fails and you cannot explain the first error;
- you are about to copy SQL from the reference;
- you are about to build another model.

## 📬 Handoff

Post:

1. the three file paths, plus the model SQL and both YAML files;
2. the full output of the three commands in Step 5;
3. the row-count result from Step 6;
4. one short paragraph answering: what is the grain, what is the key, and why did you clean the email
   and names the way you did?

Then wait for review. Do not start Task 2.

## 🧭 After review

If the gate passes, the next task is [Task 2 — remaining staging views](TASKS.md#task-2).
Every remaining task, command, and expected result is in [`TASKS.md`](TASKS.md); open only the card
whose prerequisite has passed.
