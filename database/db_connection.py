# database/db_connection.py
import psycopg2
import os
import logging
from config import Config

logger = logging.getLogger(__name__)

def get_db_connection():
    """Devuelve una conexión a PostgreSQL usando DATABASE_URL"""
    conn = psycopg2.connect(Config.DATABASE_URL)
    return conn

def test_connection():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()
        cur.close()
        conn.close()
        logger.info(f"Conexión exitosa a PostgreSQL: {version[0]}")
        return True
    except Exception as e:
        logger.error(f"Error de conexión: {e}")
        return False