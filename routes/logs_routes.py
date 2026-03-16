# routes/logs_routes.py
from flask import Blueprint, render_template, redirect, url_for, flash
from flask_login import login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.log_model import LogModel

logs_bp = Blueprint('logs', __name__, url_prefix='/logs')

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if current_user.rol != 'admin':
            flash('Acceso denegado. Se requieren permisos de administrador.', 'danger')
            return redirect(url_for('inicio'))
        return f(*args, **kwargs)
    return decorated_function

@logs_bp.route('/')
@login_required
@admin_required
def ver_logs():
    """Muestra los logs del sistema"""
    logs = LogModel.obtener_logs()
    print(f"DEBUG - Logs encontrados: {len(logs)}")
    return render_template('logs/lista.html', logs=logs)