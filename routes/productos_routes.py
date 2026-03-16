# routes/productos_routes.py
from flask import Blueprint, render_template, request, redirect, url_for, flash
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.producto_model import ProductoModel

productos_bp = Blueprint('productos', __name__, url_prefix='/productos')

@productos_bp.route('/')
def lista():
    """Lista todos los productos"""
    telas = ProductoModel.obtener_todos()
    return render_template('productos/lista.html', telas=telas)

@productos_bp.route('/nuevo', methods=['GET', 'POST'])
def nuevo():
    """Agrega un nuevo producto"""
    if request.method == 'POST':
        try:
            datos = {
                'codigo': request.form['codigo'],
                'nombre': request.form['nombre'],
                'id_tipo': request.form['id_tipo'],
                'id_proveedor': request.form['id_proveedor'],
                'composicion': request.form.get('composicion'),
                'ancho': float(request.form['ancho']) if request.form.get('ancho') else None,
                'peso_gramaje': float(request.form['peso_gramaje']) if request.form.get('peso_gramaje') else None,
                'precio_compra': float(request.form['precio_compra']),
                'precio_venta': float(request.form['precio_venta']),
                'stock_minimo': float(request.form['stock_minimo'])
            }
            id_tela = ProductoModel.crear(datos)
            flash(f'✅ Tela {datos["nombre"]} creada exitosamente', 'success')
            return redirect(url_for('productos.lista'))
        except Exception as e:
            flash(f'❌ Error al crear: {str(e)}', 'danger')
    
    # GET: mostrar formulario
    tipos = ProductoModel.obtener_tipos()
    proveedores = ProductoModel.obtener_proveedores()
    return render_template('productos/agregar.html', tipos=tipos, proveedores=proveedores)

@productos_bp.route('/editar/<int:id>', methods=['GET', 'POST'])
def editar(id):
    """Edita un producto existente"""
    if request.method == 'POST':
        try:
            datos = {
                'codigo': request.form['codigo'],
                'nombre': request.form['nombre'],
                'id_tipo': request.form['id_tipo'],
                'id_proveedor': request.form['id_proveedor'],
                'composicion': request.form.get('composicion'),
                'ancho': float(request.form['ancho']) if request.form.get('ancho') else None,
                'peso_gramaje': float(request.form['peso_gramaje']) if request.form.get('peso_gramaje') else None,
                'precio_compra': float(request.form['precio_compra']),
                'precio_venta': float(request.form['precio_venta']),
                'stock_minimo': float(request.form['stock_minimo'])
            }
            ProductoModel.actualizar(id, datos)
            flash(f'✅ Tela actualizada exitosamente', 'success')
            return redirect(url_for('productos.lista'))
        except Exception as e:
            flash(f'❌ Error al actualizar: {str(e)}', 'danger')
    
    # GET: mostrar formulario con datos
    tela = ProductoModel.obtener_por_id(id)
    if not tela:
        flash('❌ Tela no encontrada', 'danger')
        return redirect(url_for('productos.lista'))
    
    tipos = ProductoModel.obtener_tipos()
    proveedores = ProductoModel.obtener_proveedores()
    return render_template('productos/editar.html', tela=tela, tipos=tipos, proveedores=proveedores)

@productos_bp.route('/eliminar/<int:id>')
def eliminar(id):
    """Elimina (desactiva) un producto"""
    try:
        ProductoModel.eliminar(id)
        flash('✅ Tela eliminada exitosamente', 'success')
    except Exception as e:
        flash(f'❌ Error al eliminar: {str(e)}', 'danger')
    return redirect(url_for('productos.lista'))