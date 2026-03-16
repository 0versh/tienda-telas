# models/inventario_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras

class InventarioModel:
    
    @staticmethod
    def obtener_rollos():
        """Obtiene todos los rollos con su información"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT ir.*, t.codigo_tela, t.nombre_tela, 
                   c.nombre_color, tp.nombre_tipo
            FROM inventario_rollos ir
            JOIN telas t ON ir.id_tela = t.id_tela
            JOIN tipos_de_tela tp ON t.id_tipo = tp.id_tipo
            LEFT JOIN colores c ON ir.id_color = c.id_color
            WHERE ir.metros_actuales > 0
            ORDER BY t.nombre_tela, ir.numero_rollo
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_rollos_por_tela(id_tela):
        """Obtiene los rollos de una tela específica"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT ir.*, c.nombre_color
            FROM inventario_rollos ir
            LEFT JOIN colores c ON ir.id_color = c.id_color
            WHERE ir.id_tela = %s AND ir.metros_actuales > 0
            ORDER BY ir.numero_rollo
        """, (id_tela,))
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_colores():
        """Obtiene todos los colores"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("SELECT id_color, nombre_color, codigo_color FROM colores ORDER BY nombre_color")
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados