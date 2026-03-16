# routes/proveedores_routes.py
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.proveedor_model import ProveedorModel

proveedores_bp = Blueprint('proveedores', __name__, url_prefix='/proveedores')

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if current_user.rol != 'admin':
            flash('Acceso denegado. Se requieren permisos de administrador.', 'danger')
            return redirect(url_for('inicio'))
        return f(*args, **kwargs)
    return decorated_function

@proveedores_bp.route('/')
@login_required
def lista():
    """Lista todos los proveedores"""
    proveedores = ProveedorModel.obtener_todos()
    return render_template('proveedores/lista.html', proveedores=proveedores)

@proveedores_bp.route('/nuevo', methods=['GET', 'POST'])
@login_required
@admin_required
def nuevo():
    """Crea un nuevo proveedor"""
    if request.method == 'POST':
        try:
            datos = {
                'nombre_proveedor': request.form['nombre_proveedor'],
                'contacto': request.form.get('contacto'),
                'telefono': request.form.get('telefono'),
                'email': request.form.get('email'),
                'direccion': request.form.get('direccion'),
                'tipo_telas': request.form.get('tipo_telas')
            }
            
            ProveedorModel.crear(datos)
            flash('Proveedor creado exitosamente', 'success')
            return redirect(url_for('proveedores.lista'))
            
        except Exception as e:
            flash(f'Error al crear proveedor: {str(e)}', 'danger')
    
    return render_template('proveedores/nuevo.html')

@proveedores_bp.route('/editar/<int:id>', methods=['GET', 'POST'])
@login_required
@admin_required
def editar(id):
    """Edita un proveedor existente"""
    if request.method == 'POST':
        try:
            datos = {
                'nombre_proveedor': request.form['nombre_proveedor'],
                'contacto': request.form.get('contacto'),
                'telefono': request.form.get('telefono'),
                'email': request.form.get('email'),
                'direccion': request.form.get('direccion'),
                'tipo_telas': request.form.get('tipo_telas')
            }
            
            ProveedorModel.actualizar(id, datos)
            flash('Proveedor actualizado exitosamente', 'success')
            return redirect(url_for('proveedores.lista'))
            
        except Exception as e:
            flash(f'Error al actualizar proveedor: {str(e)}', 'danger')
    
    proveedor = ProveedorModel.obtener_por_id(id)
    if not proveedor:
        flash('Proveedor no encontrado', 'danger')
        return redirect(url_for('proveedores.lista'))
    
    return render_template('proveedores/editar.html', proveedor=proveedor)

@proveedores_bp.route('/eliminar/<int:id>')
@login_required
@admin_required
def eliminar(id):
    """Elimina un proveedor"""
    try:
        ProveedorModel.eliminar(id)
        flash('Proveedor eliminado exitosamente', 'success')
    except Exception as e:
        flash(f'Error al eliminar proveedor: {str(e)}', 'danger')
    
    return redirect(url_for('proveedores.lista'))