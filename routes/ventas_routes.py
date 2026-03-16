# routes/ventas_routes.py
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.venta_model import VentaModel
import json

ventas_bp = Blueprint('ventas', __name__, url_prefix='/ventas')

@ventas_bp.route('/')
@login_required
def lista():
    """Lista todas las ventas con filtros opcionales"""
    # Obtener parámetros de filtro desde la URL
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    metodo_pago = request.args.get('metodo_pago')
    estado = request.args.get('estado')
    cliente = request.args.get('cliente')
    
    filtros = {
        'fecha_inicio': fecha_inicio if fecha_inicio else None,
        'fecha_fin': fecha_fin if fecha_fin else None,
        'metodo_pago': metodo_pago if metodo_pago else 'todos',
        'estado': estado if estado else 'todos',
        'cliente': cliente if cliente else None
    }
    
    # Si no hay filtros de fecha, mostrar ventas de los últimos 30 días por defecto
    if not fecha_inicio and not fecha_fin:
        from datetime import datetime, timedelta
        filtros['fecha_inicio'] = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')
    
    ventas = VentaModel.obtener_filtradas(filtros)
    
    return render_template('ventas/lista.html', ventas=ventas, filtros=filtros)

@ventas_bp.route('/nueva', methods=['GET', 'POST'])
@login_required
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
@login_required
def detalle(id):
    """Muestra el detalle de una venta"""
    venta = VentaModel.obtener_por_id(id)
    if not venta:
        flash('❌ Venta no encontrada', 'danger')
        return redirect(url_for('ventas.lista'))
    return render_template('ventas/detalle.html', venta=venta)

@ventas_bp.route('/api/rollos')
@login_required
def api_rollos():
    """API para obtener rollos disponibles (formato JSON)"""
    rollos = VentaModel.obtener_rollos_disponibles()
    return jsonify(rollos)