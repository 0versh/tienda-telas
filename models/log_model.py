# models/log_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LogModel:
    
    @staticmethod
    def registrar(usuario_id, accion, modulo, detalle, ip=None):
        """Registra una acción en el log"""
        conn = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("""
                INSERT INTO logs (
                    usuario_id, accion, modulo, detalle, ip, fecha
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (usuario_id, accion, modulo, detalle, ip, datetime.now()))
            conn.commit()
            cur.close()
        except Exception as e:
            logger.error(f"Error registrando log: {e}")
        finally:
            if conn:
                conn.close()

    @staticmethod
    def obtener_logs(limite=100):
        """Obtiene los últimos logs"""
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT l.*, u.nombre_usuario 
            FROM logs l
            JOIN usuarios u ON l.usuario_id = u.id_usuario
            ORDER BY l.fecha DESC
            LIMIT %s
        """, (limite,))
        logs = cur.fetchall()
        cur.close()
        conn.close()
        return logs