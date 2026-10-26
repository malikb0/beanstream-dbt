#!/usr/bin/env python3
"""Load the synthetic BeanStream OLTP CSVs into PostgreSQL raw_beanstream.

This is the extract/load boundary. dbt owns everything after this schema.
"""
from __future__ import annotations

import csv
import os
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "raw"


def connect():
    return psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=int(os.getenv("PGPORT", "5434")),
        user=os.getenv("PGUSER", "learner"),
        password=os.getenv("PGPASSWORD", "learner"),
        dbname=os.getenv("PGDATABASE", "warehouse"),
        connect_timeout=5,
    )


def read_csv(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


SCHEMA = """
DROP SCHEMA IF EXISTS raw_beanstream CASCADE;
CREATE SCHEMA raw_beanstream;

CREATE TABLE raw_beanstream.customers (
    customer_id INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    city        TEXT NOT NULL,
    country     TEXT NOT NULL,
    signup_date DATE NOT NULL,
    _loaded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE raw_beanstream.products (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    active       BOOLEAN NOT NULL,
    _loaded_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE raw_beanstream.orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES raw_beanstream.customers(customer_id),
    order_date  DATE NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('completed','shipped','pending','cancelled')),
    channel     TEXT NOT NULL CHECK (channel IN ('web','app','retail','partner')),
    _loaded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE raw_beanstream.order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES raw_beanstream.orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES raw_beanstream.products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    _loaded_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
"""


def main() -> int:
    customers = read_csv("customers.csv")
    products = read_csv("products.csv")
    orders = read_csv("orders.csv")
    items = read_csv("order_items.csv")

    with connect() as conn, conn.cursor() as cur:
        cur.execute(SCHEMA)

        execute_values(
            cur,
            "INSERT INTO raw_beanstream.customers "
            "(customer_id, first_name, last_name, email, city, country, signup_date) VALUES %s",
            [
                (
                    int(r["customer_id"]),
                    r["first_name"],
                    r["last_name"],
                    r["email"],
                    r["city"],
                    r["country"],
                    r["signup_date"],
                )
                for r in customers
            ],
        )
        execute_values(
            cur,
            "INSERT INTO raw_beanstream.products "
            "(product_id, product_name, category, unit_price, active) VALUES %s",
            [
                (
                    int(r["product_id"]),
                    r["product_name"],
                    r["category"],
                    r["unit_price"],
                    r["active"].strip().lower() == "true",
                )
                for r in products
            ],
        )
        execute_values(
            cur,
            "INSERT INTO raw_beanstream.orders "
            "(order_id, customer_id, order_date, status, channel) VALUES %s",
            [
                (int(r["order_id"]), int(r["customer_id"]), r["order_date"], r["status"], r["channel"])
                for r in orders
            ],
        )
        execute_values(
            cur,
            "INSERT INTO raw_beanstream.order_items "
            "(order_item_id, order_id, product_id, quantity, unit_price) VALUES %s",
            [
                (
                    int(r["order_item_id"]),
                    int(r["order_id"]),
                    int(r["product_id"]),
                    int(r["quantity"]),
                    r["unit_price"],
                )
                for r in items
            ],
        )

        cur.execute(
            """
            SELECT 'customers', COUNT(*) FROM raw_beanstream.customers
            UNION ALL SELECT 'products', COUNT(*) FROM raw_beanstream.products
            UNION ALL SELECT 'orders', COUNT(*) FROM raw_beanstream.orders
            UNION ALL SELECT 'order_items', COUNT(*) FROM raw_beanstream.order_items
            ORDER BY 1
            """
        )
        counts = cur.fetchall()

    for name, count in counts:
        print(f"{name}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
