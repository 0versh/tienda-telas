# models/venta_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras
from datetime import datetime

class VentaModel:
    
    @staticmethod
    def obtener_todas():
        """Obtiene todas las ventas"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT v.*, u.nombre_usuario, c.nombre_cliente
            FROM ventas v
            JOIN usuarios u ON v.id_usuario = u.id_usuario
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            ORDER BY v.fecha_venta DESC
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_por_id(id_venta):
        """Obtiene una venta con sus detalles"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        # Obtener la venta
        cur.execute("""
            SELECT v.*, u.nombre_usuario, c.nombre_cliente
            FROM ventas v
            JOIN usuarios u ON v.id_usuario = u.id_usuario
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            WHERE v.id_venta = %s
        """, (id_venta,))
        venta = dict(cur.fetchone())
        
        # Obtener los detalles (cortes)
        cur.execute("""
            SELECT cv.*, t.nombre_tela, t.codigo_tela, ir.numero_rollo
            FROM cortes_ventas cv
            JOIN telas t ON cv.id_tela = t.id_tela
            LEFT JOIN inventario_rollos ir ON cv.id_rollo = ir.id_rollo
            WHERE cv.id_venta = %s
        """, (id_venta,))
        detalles = [dict(row) for row in cur.fetchall()]
        
        venta['detalles'] = detalles
        cur.close()
        conn.close()
        return venta

    @staticmethod
    def crear_venta(datos_venta, cortes):
        """Crea una nueva venta con sus cortes"""
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Insertar la venta
            cur.execute("""
                INSERT INTO ventas (
                    fecha_venta, id_usuario, id_cliente,
                    total_metros, subtotal, descuento, iva, total_pagar,
                    metodo_pago, estado
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id_venta
            """, (
                datetime.now(), 1,  # ID usuario temporal (después pondremos login)
                None,  # cliente temporal
                datos_venta['total_metros'],
                datos_venta['subtotal'],
                datos_venta.get('descuento', 0),
                datos_venta.get('iva', 0),
                datos_venta['total_pagar'],
                datos_venta.get('metodo_pago', 'efectivo'),
                'completada'
            ))
            
            id_venta = cur.fetchone()[0]
            
            # Insertar cada corte
            for corte in cortes:
                cur.execute("""
                    INSERT INTO cortes_ventas (
                        id_venta, id_rollo, id_tela,
                        metros_cortados, precio_metro_momento
                    ) VALUES (%s, %s, %s, %s, %s)
                """, (
                    id_venta,
                    corte['id_rollo'],
                    corte['id_tela'],
                    corte['metros'],
                    corte['precio']
                ))
            
            conn.commit()
            return id_venta
            
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()

    @staticmethod
    def obtener_rollos_disponibles():
        """Obtiene rollos disponibles para la venta"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT ir.id_rollo, ir.numero_rollo, ir.metros_actuales,
                   t.id_tela, t.nombre_tela, t.codigo_tela,
                   t.precio_venta_metro, c.nombre_color
            FROM inventario_rollos ir
            JOIN telas t ON ir.id_tela = t.id_tela
            LEFT JOIN colores c ON ir.id_color = c.id_color
            WHERE ir.metros_actuales > 0
            ORDER BY t.nombre_tela, ir.numero_rollo
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados