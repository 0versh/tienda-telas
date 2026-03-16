# models/usuario_model.py
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
import psycopg2.extras
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin

class Usuario(UserMixin):
    def __init__(self, id, nombre_usuario, nombre_completo, email, rol):
        self.id = id
        self.nombre_usuario = nombre_usuario
        self.nombre_completo = nombre_completo
        self.email = email
        self.rol = rol

class UsuarioModel:
    
    @staticmethod
    def obtener_por_id(user_id):
        """Obtiene un usuario por su ID"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT id_usuario, nombre_usuario, nombre_completo, email, rol 
            FROM usuarios 
            WHERE id_usuario = %s AND activo = true
        """, (user_id,))
        usuario = cur.fetchone()
        cur.close()
        conn.close()
        
        if usuario:
            return Usuario(
                id=usuario['id_usuario'],
                nombre_usuario=usuario['nombre_usuario'],
                nombre_completo=usuario['nombre_completo'],
                email=usuario['email'],
                rol=usuario['rol']
            )
        return None

    @staticmethod
    def obtener_por_nombre_usuario(nombre_usuario):
        """Obtiene un usuario por su nombre de usuario"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT id_usuario, nombre_usuario, nombre_completo, email, rol, contrasena_hash
            FROM usuarios 
            WHERE nombre_usuario = %s AND activo = true
        """, (nombre_usuario,))
        usuario = cur.fetchone()
        cur.close()
        conn.close()
        return usuario

    @staticmethod
    def verificar_contraseña(usuario, contraseña):
        """Verifica si la contraseña es correcta"""
        return check_password_hash(usuario['contrasena_hash'], contraseña)

    @staticmethod
    def obtener_todos():
        """Obtiene todos los usuarios activos"""
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cur.execute("""
            SELECT id_usuario, nombre_usuario, nombre_completo, email, rol, fecha_registro
            FROM usuarios 
            WHERE activo = true
            ORDER BY nombre_completo
        """)
        resultados = [dict(row) for row in cur.fetchall()]
        cur.close()
        conn.close()
        return resultados

    @staticmethod
    def crear(datos):
        """Crea un nuevo usuario"""
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Generar hash de la contraseña
        hash_contraseña = generate_password_hash(datos['contraseña'])
        
        try:
            cur.execute("""
                INSERT INTO usuarios (
                    nombre_usuario, nombre_completo, email, contrasena_hash, rol
                ) VALUES (%s, %s, %s, %s, %s)
                RETURNING id_usuario
            """, (
                datos['nombre_usuario'],
                datos['nombre_completo'],
                datos['email'],
                hash_contraseña,
                datos['rol']
            ))
            id_usuario = cur.fetchone()[0]
            conn.commit()
            return id_usuario
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()

    @staticmethod
    def actualizar(id_usuario, datos):
        """Actualiza un usuario existente"""
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            if 'contraseña' in datos and datos['contraseña']:
                # Actualizar incluyendo contraseña
                hash_contraseña = generate_password_hash(datos['contraseña'])
                cur.execute("""
                    UPDATE usuarios SET
                        nombre_usuario = %s,
                        nombre_completo = %s,
                        email = %s,
                        contrasena_hash = %s,
                        rol = %s
                    WHERE id_usuario = %s
                """, (
                    datos['nombre_usuario'],
                    datos['nombre_completo'],
                    datos['email'],
                    hash_contraseña,
                    datos['rol'],
                    id_usuario
                ))
            else:
                # Actualizar sin cambiar contraseña
                cur.execute("""
                    UPDATE usuarios SET
                        nombre_usuario = %s,
                        nombre_completo = %s,
                        email = %s,
                        rol = %s
                    WHERE id_usuario = %s
                """, (
                    datos['nombre_usuario'],
                    datos['nombre_completo'],
                    datos['email'],
                    datos['rol'],
                    id_usuario
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
    def eliminar(id_usuario):
        """Eliminación lógica de un usuario"""
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("UPDATE usuarios SET activo = false WHERE id_usuario = %s", (id_usuario,))
            conn.commit()
            return True
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cur.close()
            conn.close()