-- ============================================================
--  market-data-pipeline · Esquema
--  Capa RAW + modelo estrella (dimensiones + hecho)
--
--  Idempotente: se puede ejecutar varias veces y siempre deja
--  el esquema en el mismo estado (DROP IF EXISTS + CREATE).
--  Ejecutar con:  psql -U postgres -d market_data -f sql/01_schema.sql
-- ============================================================

-- Limpieza previa (orden inverso a las dependencias)
DROP TABLE IF EXISTS fact_daily_price CASCADE;
DROP TABLE IF EXISTS dim_asset        CASCADE;
DROP TABLE IF EXISTS dim_date         CASCADE;
DROP TABLE IF EXISTS raw_prices       CASCADE;

-- ------------------------------------------------------------
--  Capa RAW: datos crudos tal como llegan de la API
-- ------------------------------------------------------------
CREATE TABLE raw_prices (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source       TEXT        NOT NULL,
    payload      JSONB       NOT NULL,
    ingested_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
--  Dimensión: activo (una fila por instrumento)
-- ------------------------------------------------------------
CREATE TABLE dim_asset (
    asset_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol      TEXT NOT NULL UNIQUE,
    name        TEXT,
    asset_type  TEXT
);

-- ------------------------------------------------------------
--  Dimensión: calendario (una fila por día)
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_id      INT      PRIMARY KEY,   -- YYYYMMDD
    full_date    DATE     NOT NULL UNIQUE,
    year         SMALLINT NOT NULL,
    month        SMALLINT NOT NULL,
    day          SMALLINT NOT NULL,
    day_of_week  SMALLINT NOT NULL,      -- 1=lunes .. 7=domingo (ISO)
    is_weekend   BOOLEAN  NOT NULL
);

-- ------------------------------------------------------------
--  Hecho: precio diario (grano = un activo por día)
-- ------------------------------------------------------------
CREATE TABLE fact_daily_price (
    asset_id     INT           NOT NULL REFERENCES dim_asset(asset_id),
    date_id      INT           NOT NULL REFERENCES dim_date(date_id),
    open_price   NUMERIC(20,8),
    high_price   NUMERIC(20,8),
    low_price    NUMERIC(20,8),
    close_price  NUMERIC(20,8) NOT NULL,
    volume       NUMERIC(30,8),
    PRIMARY KEY (asset_id, date_id)
);
