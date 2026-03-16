# routes/ventas_routes.py
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.venta_model import VentaModel
import json

# Crear el blueprint (ASEGÚRATE QUE ESTÁ BIEN ESCRITO)
ventas_bp = Blueprint('ventas', __name__, url_prefix='/ventas')

@ventas_bp.route('/')
def lista():
    """Lista todas las ventas"""
    ventas = VentaModel.obtener_todas()
    return render_template('ventas/lista.html', ventas=ventas)

@ventas_bp.route('/nueva', methods=['GET', 'POST'])
def nueva():
    """Registra una nueva venta"""
    if request.method == 'POST':
        try:
            datos_venta = json.loads(request.form['datos_venta'])
            cortes = json.loads(request.form['cortes'])
            
            id_venta = VentaModel.crear_venta(datos_venta, cortes)
            flash(f'✅ Venta #{id_venta} registrada exitosamente', 'success')
            return redirect(url_for('ventas.lista'))
            
        except Exception as e:
            flash(f'❌ Error al registrar venta: {str(e)}', 'danger')
            return redirect(url_for('ventas.nueva'))
    
    # GET: mostrar formulario
    rollos = VentaModel.obtener_rollos_disponibles()
    return render_template('ventas/nueva.html', rollos=rollos)

@ventas_bp.route('/<int:id>')
def detalle(id):
    """Muestra el detalle de una venta"""
    venta = VentaModel.obtener_por_id(id)
    if not venta:
        flash('❌ Venta no encontrada', 'danger')
        return redirect(url_for('ventas.lista'))
    return render_template('ventas/detalle.html', venta=venta)

@ventas_bp.route('/api/rollos')
def api_rollos():
    """API para obtener rollos disponibles (formato JSON)"""
    rollos = VentaModel.obtener_rollos_disponibles()
    return jsonify(rollos)