# models/dashboard_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras
from datetime import datetime, timedelta

class DashboardModel:
    
    @staticmethod
    def obtener_estadisticas():
        """Obtiene estadísticas generales para el dashboard"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        estadisticas = {}
        
        # Total de productos (telas activas)
        cur.execute("SELECT COUNT(*) FROM telas WHERE activo = true")
        estadisticas['total_productos'] = cur.fetchone()[0]
        
        # Total de rollos en inventario
        cur.execute("SELECT COUNT(*) FROM inventario_rollos WHERE metros_actuales > 0")
        estadisticas['total_rollos'] = cur.fetchone()[0]
        
        # Metros totales en inventario
        cur.execute("SELECT COALESCE(SUM(metros_actuales), 0) FROM inventario_rollos WHERE metros_actuales > 0")
        estadisticas['metros_totales'] = float(cur.fetchone()[0])
        
        # Productos con stock crítico
        cur.execute("""
            SELECT COUNT(*) FROM telas 
            WHERE activo = true AND stock_total_metros <= stock_minimo_metros
        """)
        estadisticas['stock_critico'] = cur.fetchone()[0]
        
        # Ventas hoy
        hoy = datetime.now().date()
        cur.execute("""
            SELECT COALESCE(COUNT(*), 0), COALESCE(SUM(total_pagar), 0)
            FROM ventas 
            WHERE DATE(fecha_venta) = %s AND estado = 'completada'
        """, (hoy,))
        ventas_hoy = cur.fetchone()
        estadisticas['ventas_hoy_cantidad'] = ventas_hoy[0]
        estadisticas['ventas_hoy_total'] = float(ventas_hoy[1]) if ventas_hoy[1] else 0
        
        # Ventas esta semana
        semana_inicio = datetime.now().date() - timedelta(days=7)
        cur.execute("""
            SELECT COALESCE(SUM(total_pagar), 0)
            FROM ventas 
            WHERE DATE(fecha_venta) >= %s AND estado = 'completada'
        """, (semana_inicio,))
        estadisticas['ventas_semana'] = float(cur.fetchone()[0]) if cur.fetchone()[0] else 0
        
        # Ventas este mes
        mes_inicio = datetime.now().date().replace(day=1)
        cur.execute("""
            SELECT COALESCE(SUM(total_pagar), 0)
            FROM ventas 
            WHERE DATE(fecha_venta) >= %s AND estado = 'completada'
        """, (mes_inicio,))
        estadisticas['ventas_mes'] = float(cur.fetchone()[0]) if cur.fetchone()[0] else 0
        
        # Últimas 5 ventas
        cur.execute("""
            SELECT v.id_venta, v.fecha_venta, v.total_pagar, 
                   u.nombre_usuario, c.nombre_cliente
            FROM ventas v
            JOIN usuarios u ON v.id_usuario = u.id_usuario
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            WHERE v.estado = 'completada'
            ORDER BY v.fecha_venta DESC
            LIMIT 5
        """)
        columnas = [desc[0] for desc in cur.description]
        estadisticas['ultimas_ventas'] = [dict(zip(columnas, row)) for row in cur.fetchall()]
        
        # Productos con stock crítico (detalle)
        cur.execute("""
            SELECT t.id_tela, t.codigo_tela, t.nombre_tela, 
                   t.stock_total_metros, t.stock_minimo_metros,
                   p.nombre_proveedor
            FROM telas t
            JOIN proveedores p ON t.id_proveedor = p.id_proveedor
            WHERE t.activo = true AND t.stock_total_metros <= t.stock_minimo_metros
            ORDER BY (t.stock_total_metros / t.stock_minimo_metros) ASC
            LIMIT 5
        """)
        columnas = [desc[0] for desc in cur.description]
        estadisticas['productos_criticos'] = [dict(zip(columnas, row)) for row in cur.fetchall()]
        
        cur.close()
        conn.close()
        
        return estadisticas