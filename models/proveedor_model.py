# models/proveedor_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras

class ProveedorModel:
    
    @staticmethod
    def obtener_todos():
        """Obtiene todos los proveedores activos"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT id_proveedor, nombre_proveedor, contacto, telefono, 
                   email, direccion, tipo_telas_suministra, fecha_registro
            FROM proveedores 
            WHERE activo = true
            ORDER BY nombre_proveedor
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def obtener_por_id(id_proveedor):
        """Obtiene un proveedor por su ID"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT * FROM proveedores 
            WHERE id_proveedor = %s AND activo = true
        """, (id_proveedor,))
        resultado = cur.fetchone()
        cur.close()
        conn.close()
        return dict(resultado) if resultado else None

    @staticmethod
    def crear(datos):
        """Crea un nuevo proveedor"""
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("""
                INSERT INTO proveedores (
                    nombre_proveedor, contacto, telefono, email, 
                    direccion, tipo_telas_suministra
                ) VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_proveedor
            """, (
                datos['nombre_proveedor'],
                datos.get('contacto'),
                datos.get('telefono'),
                datos.get('email'),
                datos.get('direccion'),
                datos.get('tipo_telas')
            ))
            id_proveedor = cur.fetchone()[0]
            conn.commit()
            return id_proveedor
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()

    @staticmethod
    def actualizar(id_proveedor, datos):
        """Actualiza un proveedor existente"""
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("""
                UPDATE proveedores SET
                    nombre_proveedor = %s,
                    contacto = %s,
                    telefono = %s,
                    email = %s,
                    direccion = %s,
                    tipo_telas_suministra = %s
                WHERE id_proveedor = %s
            """, (
                datos['nombre_proveedor'],
                datos.get('contacto'),
                datos.get('telefono'),
                datos.get('email'),
                datos.get('direccion'),
                datos.get('tipo_telas'),
                id_proveedor
            ))
            conn.commit()
            return True
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()

    @staticmethod
    def eliminar(id_proveedor):
        """Eliminación lógica de un proveedor"""
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("UPDATE proveedores SET activo = false WHERE id_proveedor = %s", (id_proveedor,))
            conn.commit()
            return True
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()