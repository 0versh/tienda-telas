# routes/rfid_routes.py
from flask import Blueprint, render_template
from flask_login import login_required

rfid_bp = Blueprint('rfid', __name__, url_prefix='/rfid')

@rfid_bp.route('/')
@login_required
def lector():
    """Pantalla del lector RFID"""
    return render_template('rfid/lector.html')