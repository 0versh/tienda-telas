# routes/inventario_routes.py
from flask import Blueprint, render_template
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.inventario_model import InventarioModel
from models.producto_model import ProductoModel

inventario_bp = Blueprint('inventario', __name__, url_prefix='/inventario')

@inventario_bp.route('/')
@login_required 
def lista():
    """Lista todos los rollos en inventario"""
    rollos = InventarioModel.obtener_rollos()
    return render_template('inventario/lista.html', rollos=rollos)

@inventario_bp.route('/tela/<int:id_tela>')
@login_required 
def por_tela(id_tela):
    """Muestra los rollos de una tela específica"""
    rollos = InventarioModel.obtener_rollos_por_tela(id_tela)
    tela = ProductoModel.obtener_por_id(id_tela)
    return render_template('inventario/por_tela.html', rollos=rollos, tela=tela)