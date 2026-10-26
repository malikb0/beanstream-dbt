# Data

Start with the [project README](../README.md) and the [operator's guide](../docs/guide.md).

The four CSVs in `raw/` are the synthetic BeanStream source extracts. They are copied from the
MIT-licensed upstream platform repo so this project is runnable on its own.

| File | Rows | Grain |
|---|---:|---|
| `customers.csv` | 40 | one customer |
| `products.csv` | 12 | one product |
| `orders.csv` | 120 | one order |
| `order_items.csv` | 270 | one order line |

- Seed 42, 2024 only.
- `scripts/load_raw.py` loads them into `raw_beanstream`.
- The upstream source of truth is
  [ecommerce-data-platform-practice-project](https://github.com/malikb0/ecommerce-data-platform-practice-project).
- Provenance and licence: [`../NOTICE.md`](../NOTICE.md).

Target warehouse totals: **$7,261.50** non-cancelled revenue, **99** orders, **448** units.
