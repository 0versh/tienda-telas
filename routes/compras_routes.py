# routes/compras_routes.py
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.compra_model import CompraModel
import json

compras_bp = Blueprint('compras', __name__, url_prefix='/compras')

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if current_user.rol != 'admin':
            flash('Acceso denegado. Se requieren permisos de administrador.', 'danger')
            return redirect(url_for('inicio'))
        return f(*args, **kwargs)
    return decorated_function

@compras_bp.route('/')
@login_required
@admin_required
def lista():
    """Lista todas las compras"""
    compras = CompraModel.obtener_todas()
    return render_template('compras/lista.html', compras=compras)

@compras_bp.route('/nueva', methods=['GET', 'POST'])
@login_required
@admin_required
def nueva():
    """Registra una nueva compra"""
    if request.method == 'POST':
        try:
            datos_compra = json.loads(request.form['datos_compra'])
            detalles = json.loads(request.form['detalles'])
            
            datos_compra['id_usuario'] = current_user.id
            
            id_compra = CompraModel.crear_compra(datos_compra, detalles)
            flash(f'✅ Compra #{id_compra} registrada exitosamente', 'success')
            return redirect(url_for('compras.lista'))
            
        except Exception as e:
            flash(f'❌ Error al registrar compra: {str(e)}', 'danger')
            return redirect(url_for('compras.nueva'))
    
    # GET: mostrar formulario
    proveedores = CompraModel.obtener_proveedores()
    telas = CompraModel.obtener_telas()
    colores = CompraModel.obtener_colores()
    
    return render_template('compras/nueva.html', 
                         proveedores=proveedores, 
                         telas=telas, 
                         colores=colores)

@compras_bp.route('/<int:id>')
@login_required
@admin_required
def detalle(id):
    """Muestra el detalle de una compra"""
    compra = CompraModel.obtener_por_id(id)
    if not compra:
        flash('❌ Compra no encontrada', 'danger')
        return redirect(url_for('compras.lista'))
    return render_template('compras/detalle.html', compra=compra)

@compras_bp.route('/api/telas')
@login_required
def api_telas():
    """API para obtener telas en formato JSON"""
    telas = CompraModel.obtener_telas()
    return jsonify(telas)