-- ============================================================
--  Transformación: raw_prices -> modelo estrella
--  Idempotente (ON CONFLICT): se puede correr en cada ejecución
--  del pipeline sin duplicar datos.
--  Ejecutar con:  psql -U postgres -d market_data -f sql/03_transform.sql
-- ============================================================

-- 1) dim_asset: los símbolos presentes en la capa cruda
INSERT INTO dim_asset (symbol, asset_type)
SELECT DISTINCT payload ->> 'symbol', 'crypto'
FROM raw_prices
ON CONFLICT (symbol) DO NOTHING;

-- 2) fact_daily_price: desanida las velas del JSON y las carga
INSERT INTO fact_daily_price (asset_id, date_id, open_price, high_price, low_price, close_price, volume)
SELECT
    a.asset_id,
    TO_CHAR(to_timestamp((kline ->> 0)::bigint / 1000) AT TIME ZONE 'UTC', 'YYYYMMDD')::int,
    (kline ->> 1)::numeric,
    (kline ->> 2)::numeric,
    (kline ->> 3)::numeric,
    (kline ->> 4)::numeric,
    (kline ->> 5)::numeric
FROM raw_prices r
CROSS JOIN LATERAL jsonb_array_elements(r.payload -> 'klines') AS kline
JOIN dim_asset a ON a.symbol = r.payload ->> 'symbol'
ON CONFLICT (asset_id, date_id) DO UPDATE SET
    open_price  = EXCLUDED.open_price,
    high_price  = EXCLUDED.high_price,
    low_price   = EXCLUDED.low_price,
    close_price = EXCLUDED.close_price,
    volume      = EXCLUDED.volume;
