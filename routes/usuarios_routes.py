# routes/usuarios_routes.py
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.usuario_model import UsuarioModel  # <-- IMPORTACIÓN AL INICIO
from database.db_connection import get_db_connection

usuarios_bp = Blueprint('usuarios', __name__, url_prefix='/usuarios')

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if current_user.rol != 'admin':
            flash('Acceso denegado. Se requieren permisos de administrador.', 'danger')
            return redirect(url_for('inicio'))
        return f(*args, **kwargs)
    return decorated_function

@usuarios_bp.route('/')
@login_required
@admin_required
def lista():
    """Lista todos los usuarios"""
    usuarios = UsuarioModel.obtener_todos()
    return render_template('usuarios/lista.html', usuarios=usuarios)

@usuarios_bp.route('/nuevo', methods=['GET', 'POST'])
@login_required
@admin_required
def nuevo():
    """Crear un nuevo usuario"""
    if request.method == 'POST':
        try:
            datos = {
                'nombre_usuario': request.form['nombre_usuario'],
                'nombre_completo': request.form['nombre_completo'],
                'email': request.form['email'],
                'contraseña': request.form['contraseña'],
                'rol': request.form['rol']
            }
            
            # Validar que las contraseñas coincidan
            if datos['contraseña'] != request.form['confirmar_contraseña']:
                flash('Las contraseñas no coinciden', 'danger')
                return redirect(url_for('usuarios.nuevo'))
            
            UsuarioModel.crear(datos)
            flash('Usuario creado exitosamente', 'success')
            return redirect(url_for('usuarios.lista'))
            
        except Exception as e:
            flash(f'Error al crear usuario: {str(e)}', 'danger')
    
    return render_template('usuarios/nuevo.html')

@usuarios_bp.route('/editar/<int:id>', methods=['GET', 'POST'])
@login_required
@admin_required
def editar(id):
    """Editar un usuario existente"""
    if request.method == 'POST':
        try:
            datos = {
                'nombre_usuario': request.form['nombre_usuario'],
                'nombre_completo': request.form['nombre_completo'],
                'email': request.form['email'],
                'rol': request.form['rol']
            }
            
            # Solo incluir contraseña si se proporcionó
            if request.form.get('contraseña'):
                datos['contraseña'] = request.form['contraseña']
                if datos['contraseña'] != request.form.get('confirmar_contraseña'):
                    flash('Las contraseñas no coinciden', 'danger')
                    return redirect(url_for('usuarios.editar', id=id))
            
            # Usar el modelo importado al inicio
            UsuarioModel.actualizar(id, datos)
            flash('Usuario actualizado exitosamente', 'success')
            return redirect(url_for('usuarios.lista'))
            
        except Exception as e:
            flash(f'Error al actualizar usuario: {str(e)}', 'danger')
            return redirect(url_for('usuarios.editar', id=id))
    
    # GET: obtener datos del usuario
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT id_usuario, nombre_usuario, nombre_completo, email, rol 
            FROM usuarios WHERE id_usuario = %s
        """, (id,))
        usuario = cur.fetchone()
        cur.close()
        conn.close()
        
        if not usuario:
            flash('Usuario no encontrado', 'danger')
            return redirect(url_for('usuarios.lista'))
        
        return render_template('usuarios/editar.html', usuario=usuario)
        
    except Exception as e:
        flash(f'Error al cargar usuario: {str(e)}', 'danger')
        return redirect(url_for('usuarios.lista'))

@usuarios_bp.route('/eliminar/<int:id>')
@login_required
@admin_required
def eliminar(id):
    """Eliminar (desactivar) un usuario"""
    try:
        # No permitir eliminarse a sí mismo
        if id == current_user.id:
            flash('No puedes eliminar tu propio usuario', 'danger')
            return redirect(url_for('usuarios.lista'))
        
        UsuarioModel.eliminar(id)
        flash('Usuario eliminado exitosamente', 'success')
    except Exception as e:
        flash(f'Error al eliminar usuario: {str(e)}', 'danger')
    
    return redirect(url_for('usuarios.lista'))