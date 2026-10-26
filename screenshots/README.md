# Screenshots — capture contract and record

**Project:** BeanStream dbt
**Record date:** 2026-10-26
**Scope:** exactly three evidence images in this folder: `01-lineage.png`, `02-model-detail.png`, `03-kpi-query.png`.

A screenshot is evidence only when the command, page, and caption below match the committed file. No placeholder images are committed. If a file is not present when you read this, its entry is a **capture command**, not proof that the shot was taken.

## 📐 Capture rules

- Start from a clean build: `make build` must end with `PASS=95 WARN=0 ERROR=0` and `TOTAL=95`.
- Generate and serve the docs: `make docs`, then `make serve`.
- Capture the relevant panel only; crop browser chrome where it adds nothing.
- Use a readable desktop width (the captured 01 image is **1760×1160**).
- Do not include local absolute paths, secrets, personal data, or unrelated windows.
- Re-capture after a change that alters the model graph, column list, tests, or KPI numbers.
- Store the caption beside the image in the README; keep the file name exactly as listed.

## 🧭 01 — `screenshots/01-lineage.png`

| Field | Record |
|---|---|
| **Date** | 2026-10-26 |
| **Status** | ✅ Captured on 2026-10-26. The file is the dbt lineage graph filtered to `+fct_sales+`. |
| **Page** | dbt docs → Lineage Graph → filter `+fct_sales+` |
| **Capture command** | `make build && make docs && make serve`, open `http://localhost:8080`, select `fct_sales`, open the Lineage Graph, and filter `+fct_sales+` |
| **Caption** | The dbt lineage graph for `fct_sales`: raw order and order-item sources through staging and dimensions into the incremental fact, with KPI tests downstream. |
| **File check** | PNG, 1760×1160, 125,897 bytes |

## 🧱 02 — `screenshots/02-model-detail.png`

| Field | Record |
|---|---|
| **Date** | 2026-10-26 |
| **Status** | ✅ Captured on 2026-10-26. |
| **Page** | dbt docs → `fct_sales` → Columns and Data Tests |
| **Capture command** | `make build && make docs && make serve`, open `http://localhost:8080`, search `fct_sales`, open the Columns and Data Tests panels, and capture the model detail view |
| **Caption** | `fct_sales` model detail: column descriptions and the data tests attached to the fact table. |
| **File check** | PNG, 1800×1600, 185,314 bytes |

## 📊 03 — `screenshots/03-kpi-query.png`

| Field | Record |
|---|---|
| **Date** | 2026-10-26 |
| **Status** | ✅ Captured on 2026-10-26 from the real `psql --html` result. Non-cancelled revenue `7261.50`, orders `99`, units `448`, AOV `73.35`, cancellation `17.50`. |
| **Page** | KPI query result card (`psql` result) |
| **Capture command** | `docker compose exec -T postgres psql -U learner -d warehouse -c "select round(sum(line_amount) filter (where order_status <> 'cancelled'), 2) as revenue, count(distinct order_id) filter (where order_status <> 'cancelled') as orders, sum(quantity) filter (where order_status <> 'cancelled') as units from marts.fct_sales;"` |
| **Caption** | KPI query result: non-cancelled revenue **$7,261.50**, **99** orders, **448** units, **$73.35** AOV, and **17.5%** cancellation. |
| **File check** | PNG, 2100×720, 50,469 bytes |

## 🔗 README use

The three files are embedded in the root [`README.md`](../README.md#screenshots) with relative paths and captions. Keep the README, this record, and the actual files in sync; a caption that describes a different model or number is stale evidence.
