import os
from pathlib import Path
import requests
import psycopg
from psycopg.types.json import Json
from dotenv import load_dotenv

load_dotenv()

# --- Configuración de la extracción ---
SYMBOL = "BTCUSDT"
INTERVAL = "1d"
LIMIT = 30

def fetch_klines(symbol, interval, limit):
    """Trae velas OHLCV diarias desde Binance."""
    url = "https://api.binance.com/api/v3/klines"
    params = {"symbol": symbol, "interval": interval, "limit": limit}
    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()
    return response.json()

def get_connection():
    """Abre una conexión a PostgreSQL usando el .env."""
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )

def save_raw(conn, source, payload):
    """Inserta un payload crudo en raw_prices."""
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO raw_prices (source, payload) VALUES (%s, %s)",
            (source, Json(payload)),
        )
    conn.commit()

def run_transform(conn):
    """Ejecuta el SQL de transformación (raw -> modelo estrella)."""
    sql_path = Path(__file__).parent.parent / "sql" / "03_transform.sql"
    sql = sql_path.read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()

def main():
    klines = fetch_klines(SYMBOL, INTERVAL, LIMIT)
    print(f"Traje {len(klines)} velas de {SYMBOL}")

    payload = {"symbol": SYMBOL, "interval": INTERVAL, "klines": klines}

    conn = get_connection()
    save_raw(conn, "binance", payload)
    print("Crudo guardado en raw_prices ✅")

    run_transform(conn)
    print("Transformación aplicada — modelo estrella actualizado ⭐")

    conn.close()

if __name__ == "__main__":
    main()