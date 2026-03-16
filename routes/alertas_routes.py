# routes/alertas_routes.py
from flask import Blueprint, render_template, jsonify
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.alerta_model import AlertaModel

alertas_bp = Blueprint('alertas', __name__, url_prefix='/alertas')

@alertas_bp.route('/')
@login_required
def ver_alertas():
    """Muestra todas las alertas"""
    alertas = AlertaModel.obtener_alertas_activas()
    print(f"DEBUG - Alertas encontradas: {len(alertas)}")
    return render_template('alertas/lista.html', alertas=alertas)

@alertas_bp.route('/api/alertas')
@login_required
def api_alertas():
    """API para obtener alertas en formato JSON"""
    alertas = AlertaModel.obtener_alertas_activas()
    return jsonify(alertas)