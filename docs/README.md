# BeanStream dbt — Lab documentation

BeanStream is a fictional coffee-subscription retailer. This lab is where you build the dbt
transformation layer yourself; the agent reviews and unblocks.

## 🚀 Reading order

You do **not** need to read every document. Start with the active task, then open a reference only when
the card sends you there.

1. [PROGRESS](../PROGRESS.md) — agent session state; read this first when resuming work.
2. [STATUS](../STATUS.md) — what is done, what is blocked, and the active task.
3. [START-HERE](../START-HERE.md) — Task 1, if it is still the active task.
4. [TASKS](../TASKS.md) — the standalone card for Tasks 2–7.
5. [Glossary](glossary.md) — plain-English definitions of source, grain, dimension, fact, and key.
6. [Data dictionary](data-dictionary.md) — columns, grain, keys, and KPI formulas.
7. [Operator guide](guide.md) — setup, reset, and troubleshooting.
8. [LEARNING-PATH](../LEARNING-PATH.md) — the whole map, only when you want the overview.

## 🗂️ Document map

| Document | Use it when |
|---|---|
| [PROGRESS](../PROGRESS.md) | You are resuming an agent session and need the short handoff |
| [STATUS](../STATUS.md) | You need the current state and active task |
| [START-HERE](../START-HERE.md) | Task 1 is the active card |
| [TASKS](../TASKS.md) | Tasks 2–7; each card is standalone |
| [Glossary](glossary.md) | A term in a card is unfamiliar |
| [Data dictionary](data-dictionary.md) | You need the contract before writing SQL |
| [Operator guide](guide.md) | You need commands or a reset |
| [LEARNING-PATH](../LEARNING-PATH.md) | You want the overview, not the next action |
| [Reference](../../beanstream-dbt-reference) | A gate explicitly tells you to compare |

## ✅ What “done” means

- `dbt build` passes with **95 checks**.
- Revenue **7,261.50**, orders **99**, units **448**.
- `fct_sales` has **270** rows.
- A second build is idempotent.
- CI is green.
- Screenshots and claims match the verified result.
