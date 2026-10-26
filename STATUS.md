# BeanStream dbt — Lab status

> **Authoritative lab status.** This page records the current state, the active task, and the exact
> blocker. It is updated after each gate; the task cards contain the instructions.

**Last updated:** 2026-10-26
**Owner:** Muhammad Awais Rasheed

## 🚦 At a glance

| Field | Value |
|---|---|
| Project | BeanStream dbt Learning Lab |
| Status | 🟢 **Task 6 passed** — Task 7 ready, not started |
| Stage | Task 7 — evidence + publication |
| Build | 95/95 checks; incremental reruns are idempotent |
| Models | Staging 5; dimensions 40 / 12 / 4 / 362; fact 270 |
| Tests | 84 data tests pass; failure drill observed and removed |
| Reference | `~/projects/beanstream-dbt-reference` (one-off, not a repeatable pattern) |
| Next action | Open Task 7; evidence and publication not started |

## ✅ Implemented / provided

- Four raw CSVs in `data/raw/`.
- Python loader: `scripts/load_raw.py`.
- PostgreSQL 16 Docker service.
- dbt project, profiles, dependencies, Makefile.
- Source contract, KPI targets, data dictionary, glossary.
- Seven task cards with standalone starting-state checks.
- A preserved reference implementation outside this repo.

## ⏳ Pending — your work

| Task | Status | Owner | Gate |
|---|---|---|---|
| 1. Sources + `stg_customers` | ✅ passed | You | 40 rows, clean key |
| 2. Remaining staging views | ✅ passed | You | 5 views, counts, 28 tests, YAML args |
| 3. Four dimensions | ✅ passed | You | unique keys, 362 dates |
| 4. `fct_sales` | ✅ passed | You | 270 lines |
| 5. Tests + KPI reconciliation | ✅ passed | You | 95 checks pass |
| 6. Incremental + failure drill | ✅ passed | You | idempotent second run |
| 7. Evidence + publication | ▶️ next — not started | You + agent | public repo, CI green |

## 🚧 Blockers

- **None.** Task 6 passed: incremental fact, idempotent reruns, **95/95** checks.
- Task 7 has not started; no public evidence or CI yet.

## 🔜 Next action

**Task 7 — evidence + publication.**

1. Read [`TASKS.md#task-7`](TASKS.md#task-7).
2. Capture the required screenshots, outputs, and CI evidence.
3. Prepare the public repo; publish only after owner approval.
4. Do not call it published before CI is green and the URL exists.

## ✅ Task 6 gate — passed

**Verified 2026-10-26.**

- `fct_sales`: incremental, `delete+insert`, `unique_key=order_item_id`.
- Full refresh → **270** rows.
- Two normal runs → `INSERT 0 0` each; **270 / 270 / max 270**.
- `dbt build` → **95/95**; `--full-refresh` → **95/95**.
- Failure-drill file removed; `assert_positive_quantity` passes.
- No deprecation warnings.

## 📊 Evidence

| Evidence | Where |
|---|---|
| Task ladder and gates | [`LEARNING-PATH.md`](LEARNING-PATH.md) |
| Active task card | [`TASKS.md#task-7`](TASKS.md#task-7) |
| Source contract | [`docs/data-dictionary.md`](docs/data-dictionary.md) |
| Terms | [`docs/glossary.md`](docs/glossary.md) |
| Runbook | [`docs/guide.md`](docs/guide.md) |
| Reference implementation | `~/projects/beanstream-dbt-reference` |

## 🕓 Status log

| Date | Change |
|---|---|
| 2026-10-21 | Agent-built implementation preserved as a reference. |
| 2026-10-21 | Working repo reset to a learning lab; model and test solutions removed. |
| 2026-10-21 | Full seven-task ladder added. |
| 2026-10-22 | Task 1 reported done; Task 2 staging files written. |
| 2026-10-22 | `stg_channels` blocked on a nonexistent source; task cards corrected and made standalone. |
| 2026-10-22 | Task 1 passed: 40 customers; 28/28 staging tests pass. |
| 2026-10-22 | Task 2 reviewed: counts pass; channel IDs hardcoded and ordered wrong — revision requested. |
| 2026-10-22 | Paused for today; resume with the channel-ID fix and YAML warning cleanup. |
| 2026-10-26 | Fresh check: channel model fixed; 5/5 run, 28/28 tests, IDs correct; YAML `arguments:` cleanup remains. |
| 2026-10-26 | YAML cleanup confirmed: `--no-partial-parse` 28/28 pass, no warning; Task 2 passed. |
| 2026-10-26 | Task 4 review: fact data/tests pass; dim tests bypassed by `data-tests`; relationships args + `select *` cleanup requested. |
| 2026-10-26 | Tasks 3–4 passed: 65/65 tests, no warnings; Task 5 next. |
| 2026-10-26 | Task 5 review: KPI test and source FKs registered; 90/95 checks; five KPI assertions remain. |
| 2026-10-26 | Task 5 passed: 95/95 checks; all KPI assertions pass; Task 6 next. |
| 2026-10-26 | Task 6 passed: incremental idempotency verified; 95/95 checks; Task 7 next. |
