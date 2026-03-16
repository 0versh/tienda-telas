# models/compra_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras
from datetime import datetime

class CompraModel:
    
    @staticmethod
    def obtener_todas():
        """Obtiene todas las compras"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT c.*, p.nombre_proveedor, u.nombre_usuario
            FROM compras_proveedor c
            JOIN proveedores p ON c.id_proveedor = p.id_proveedor
            JOIN usuarios u ON c.id_usuario_registra = u.id_usuario
            ORDER BY c.fecha_compra DESC
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_por_id(id_compra):
        """Obtiene una compra con sus detalles"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        # Obtener la compra
        cur.execute("""
            SELECT c.*, p.nombre_proveedor, u.nombre_usuario
            FROM compras_proveedor c
            JOIN proveedores p ON c.id_proveedor = p.id_proveedor
            JOIN usuarios u ON c.id_usuario_registra = u.id_usuario
            WHERE c.id_compra = %s
        """, (id_compra,))
        compra = dict(cur.fetchone())
        
        # Obtener los detalles (rollos)
        cur.execute("""
            SELECT d.*, t.nombre_tela, t.codigo_tela, col.nombre_color
            FROM detalle_compras d
            JOIN telas t ON d.id_tela = t.id_tela
            LEFT JOIN colores col ON d.id_color = col.id_color
            WHERE d.id_compra = %s
        """, (id_compra,))
        detalles = [dict(row) for row in cur.fetchall()]
        
        compra['detalles'] = detalles
        cur.close()
        conn.close()
        return compra

    @staticmethod
    def crear_compra(datos_compra, detalles):
        """Crea una nueva compra con sus rollos"""
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Insertar la compra
            cur.execute("""
                INSERT INTO compras_proveedor (
                    id_proveedor, fecha_compra, numero_factura,
                    total_metros, total_pagar, estado_pago,
                    id_usuario_registra, observaciones
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id_compra
            """, (
                datos_compra['id_proveedor'],
                datetime.now(),
                datos_compra.get('numero_factura'),
                datos_compra['total_metros'],
                datos_compra['total_pagar'],
                datos_compra.get('estado_pago', 'pendiente'),
                datos_compra['id_usuario'],
                datos_compra.get('observaciones')
            ))
            
            id_compra = cur.fetchone()[0]
            
            # Insertar cada detalle (rollo)
            for detalle in detalles:
                cur.execute("""
                    INSERT INTO detalle_compras (
                        id_compra, id_tela, id_color,
                        cantidad_rollos, metros_por_rollo, precio_metro_compra
                    ) VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    id_compra,
                    detalle['id_tela'],
                    detalle.get('id_color'),
                    detalle['cantidad_rollos'],
                    detalle['metros_por_rollo'],
                    detalle['precio_metro']
                ))
            
            conn.commit()
            return id_compra
            
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()

    @staticmethod
    def obtener_proveedores():
        """Obtiene proveedores activos"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT id_proveedor, nombre_proveedor 
            FROM proveedores 
            WHERE activo = true 
            ORDER BY nombre_proveedor
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_telas():
        """Obtiene telas activas"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT t.id_tela, t.codigo_tela, t.nombre_tela, 
                   tp.nombre_tipo, p.nombre_proveedor
            FROM telas t
            JOIN tipos_de_tela tp ON t.id_tipo = tp.id_tipo
            JOIN proveedores p ON t.id_proveedor = p.id_proveedor
            WHERE t.activo = true
            ORDER BY t.nombre_tela
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_colores():
        """Obtiene colores disponibles"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("SELECT id_color, nombre_color FROM colores ORDER BY nombre_color")
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados