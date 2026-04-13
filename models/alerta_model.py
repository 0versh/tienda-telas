# models/alerta_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras
from datetime import datetime, timedelta

class AlertaModel:
    
    @staticmethod
    def obtener_stock_critico():
        """Obtiene productos con stock crítico"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT t.id_tela, t.codigo_tela, t.nombre_tela, 
                   t.stock_total_metros, t.stock_minimo_metros,
                   p.nombre_proveedor, p.telefono, p.email
            FROM telas t
            JOIN proveedores p ON t.id_proveedor = p.id_proveedor
            WHERE t.activo = true 
              AND t.stock_total_metros <= t.stock_minimo_metros
            ORDER BY (t.stock_total_metros / t.stock_minimo_metros) ASC
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_alertas_activas():
        """Obtiene todas las alertas activas"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        alertas = []
        
        # Stock crítico
        stock_critico = AlertaModel.obtener_stock_critico()
        for item in stock_critico:
            alertas.append({
                'tipo': 'stock_critico',
                'severidad': 'alta',
                'mensaje': f"Stock crítico: {item['nombre_tela']} ({item['stock_total_metros']} m / mínimo {item['stock_minimo_metros']} m)",
                'producto': item,
                'fecha': datetime.now()
            })
        

        
        cur.close()
        conn.close()
        return alertas