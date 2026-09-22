# market-data-pipeline

Pipeline **ELT batch** de datos de mercado (financieros / cripto): extracción desde una API pública, carga cruda en PostgreSQL y transformación con SQL a un **modelo estrella**. Diseñado para ser **idempotente** y ejecutable de punta a punta.

## Stack
- Python 3.12
- PostgreSQL 18

## Estructura
- `extract/` — extracción desde la API y carga cruda en Postgres (la **E** y la **L**)
- `sql/` — DDL del esquema y transformaciones al modelo estrella (la **T**)

## Estado
🚧 En construcción.
