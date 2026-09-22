-- ============================================================
--  Seed de la dimensión calendario (2020-2030)
--  Idempotente: ON CONFLICT evita duplicar si se corre de nuevo.
--  Ejecutar con:  psql -U postgres -d market_data -f sql/02_seed_dim_date.sql
-- ============================================================

INSERT INTO dim_date (date_id, full_date, year, month, day, day_of_week, is_weekend)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d::date,
    EXTRACT(YEAR   FROM d),
    EXTRACT(MONTH  FROM d),
    EXTRACT(DAY    FROM d),
    EXTRACT(ISODOW FROM d),
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2020-01-01'::timestamp,
                     '2030-12-31'::timestamp,
                     '1 day'::interval) AS d
ON CONFLICT (date_id) DO NOTHING;
