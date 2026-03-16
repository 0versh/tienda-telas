# api/ventas_api.py
from flask_restful import Resource
from flask import request
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.venta_model import VentaModel
from models.log_model import LogModel
import json

class VentasAPI(Resource):
    method_decorators = [login_required]
    
    def get(self, id_venta=None):
        if id_venta:
            venta = VentaModel.obtener_por_id(id_venta)
            if venta:
                return {'status': 'success', 'data': venta}, 200
            return {'status': 'error', 'message': 'Venta no encontrada'}, 404
        else:
            ventas = VentaModel.obtener_todas()
            return {'status': 'success', 'data': ventas}, 200
    
    def post(self):
        """POST /api/ventas - Registrar venta via API"""
        data = request.get_json()
        try:
            id_venta = VentaModel.crear_venta(
                data['datos_venta'],
                data['cortes']
            )
            return {'status': 'success', 'id_venta': id_venta}, 201
        except Exception as e:
            return {'status': 'error', 'message': str(e)}, 400