# models/producto_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras

class ProductoModel:
    
    @staticmethod
    def obtener_todos():
        """Obtiene todas las telas activas"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT t.*, tp.nombre_tipo, p.nombre_proveedor 
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
    def obtener_por_id(id_tela):
        """Obtiene una tela por su ID"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT t.*, tp.nombre_tipo, p.nombre_proveedor 
            FROM telas t
            JOIN tipos_de_tela tp ON t.id_tipo = tp.id_tipo
            JOIN proveedores p ON t.id_proveedor = p.id_proveedor
            WHERE t.id_tela = %s AND t.activo = true
        """, (id_tela,))
        resultado = cur.fetchone()
        cur.close()
        conn.close()
        return dict(resultado) if resultado else None

    @staticmethod
    def crear(datos):
        """Crea una nueva tela"""
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO telas (
                codigo_tela, nombre_tela, id_tipo, id_proveedor,
                composicion, ancho, peso_gramaje,
                precio_compra_metro, precio_venta_metro,
                stock_minimo_metros, fecha_ingreso
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_DATE)
            RETURNING id_tela
        """, (
            datos['codigo'], datos['nombre'], datos['id_tipo'], 
            datos['id_proveedor'], datos.get('composicion'), 
            datos.get('ancho'), datos.get('peso_gramaje'),
            datos['precio_compra'], datos['precio_venta'],
            datos['stock_minimo']
        ))
        id_tela = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return id_tela

    @staticmethod
    def actualizar(id_tela, datos):
        """Actualiza una tela existente"""
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            UPDATE telas SET
                codigo_tela = %s,
                nombre_tela = %s,
                id_tipo = %s,
                id_proveedor = %s,
                composicion = %s,
                ancho = %s,
                peso_gramaje = %s,
                precio_compra_metro = %s,
                precio_venta_metro = %s,
                stock_minimo_metros = %s
            WHERE id_tela = %s
        """, (
            datos['codigo'], datos['nombre'], datos['id_tipo'],
            datos['id_proveedor'], datos.get('composicion'),
            datos.get('ancho'), datos.get('peso_gramaje'),
            datos['precio_compra'], datos['precio_venta'],
            datos['stock_minimo'], id_tela
        ))
        conn.commit()
        cur.close()
        conn.close()
        return True

    @staticmethod
    def eliminar(id_tela):
        """Eliminación lógica de una tela"""
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE telas SET activo = false WHERE id_tela = %s", (id_tela,))
        conn.commit()
        cur.close()
        conn.close()
        return True

    @staticmethod
    def obtener_tipos():
        """Obtiene todos los tipos de tela"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("SELECT id_tipo, nombre_tipo FROM tipos_de_tela ORDER BY nombre_tipo")
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_proveedores():
        """Obtiene todos los proveedores activos"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("SELECT id_proveedor, nombre_proveedor FROM proveedores WHERE activo = true ORDER BY nombre_proveedor")
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados