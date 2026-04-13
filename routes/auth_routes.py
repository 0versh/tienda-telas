# routes/auth_routes.py
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.usuario_model import UsuarioModel, Usuario
from database.db_connection import get_db_connection

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Página de inicio de sesión"""
    
    if current_user.is_authenticated:
        return redirect(url_for('inicio'))
    
    if request.method == 'POST':
        nombre_usuario = request.form['nombre_usuario']
        contraseña = request.form['contraseña']
        
        # Buscar usuario
        usuario = UsuarioModel.obtener_por_nombre_usuario(nombre_usuario)
        
        if usuario and UsuarioModel.verificar_contraseña(usuario, contraseña):
            # Crear objeto Usuario
            user_obj = Usuario(
                id=usuario['id_usuario'],
                nombre_usuario=usuario['nombre_usuario'],
                nombre_completo=usuario['nombre_completo'],
                email=usuario['email'],
                rol=usuario['rol']
            )
            login_user(user_obj, remember=True)  
            
            # Obtener la página a la que intentaba acceder
            next_page = request.args.get('next')
            if next_page and next_page != '/':
                return redirect(next_page)
            
            flash(f'¡Bienvenido {usuario["nombre_completo"]}!', 'success')
            return redirect(url_for('inicio'))
        else:
            flash('Nombre de usuario o contraseña incorrectos', 'danger')
    
    return render_template('auth/login.html')

@auth_bp.route('/logout')
@login_required
def logout():
    """Cerrar sesión"""
    logout_user()
    flash('Sesión cerrada exitosamente', 'success')
    return redirect(url_for('auth.login'))

@auth_bp.route('/perfil')
@login_required
def perfil():
    """Ver perfil del usuario actual"""
    return render_template('auth/perfil.html', usuario=current_user)

@auth_bp.route('/cambiar-contraseña', methods=['POST'])
@login_required
def cambiar_contraseña():
    """Cambiar contraseña del usuario actual"""
    from models.usuario_model import UsuarioModel
    
    contraseña_actual = request.form['contraseña_actual']
    nueva_contraseña = request.form['nueva_contraseña']
    confirmar = request.form['confirmar_contraseña']
    
    # Verificar contraseña actual
    usuario = UsuarioModel.obtener_por_nombre_usuario(current_user.nombre_usuario)
    
    if not UsuarioModel.verificar_contraseña(usuario, contraseña_actual):
        flash('La contraseña actual es incorrecta', 'danger')
        return redirect(url_for('auth.perfil'))
    
    if nueva_contraseña != confirmar:
        flash('Las contraseñas no coinciden', 'danger')
        return redirect(url_for('auth.perfil'))
    
    # Actualizar contraseña
    from werkzeug.security import generate_password_hash
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE usuarios SET contrasena_hash = %s 
        WHERE id_usuario = %s
    """, (generate_password_hash(nueva_contraseña), current_user.id))
    conn.commit()
    cur.close()
    conn.close()
    
    flash('Contraseña actualizada exitosamente', 'success')
    return redirect(url_for('auth.perfil'))
