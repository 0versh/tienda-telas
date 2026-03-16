# api/inventario_api.py
from flask_restful import Resource
from flask import request
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.inventario_model import InventarioModel
from models.log_model import LogModel

class InventarioAPI(Resource):
    method_decorators = [login_required]
    
    def get(self, id_rollo=None):
        """GET /api/inventario - Lista todo el inventario
           GET /api/inventario/<id_rollo> - Obtiene un rollo específico"""
        if id_rollo:
            # Aquí implementarías obtener_por_id
            return {'status': 'success', 'data': {}}, 200
        else:
            rollos = InventarioModel.obtener_rollos()
            return {'status': 'success', 'data': rollos}, 200
    
    def post(self):
        """POST /api/inventario/consulta - Endpoint para RFID"""
        data = request.get_json()
        codigo_rfid = data.get('codigo_rfid')
        
        # Buscar rollo por código RFID (asumiendo que lo guardas en numero_rollo)
        # Aquí implementarías la lógica de búsqueda por RFID
        
        return {
            'status': 'success',
            'data': {
                'mensaje': 'Endpoint listo para integración RFID',
                'codigo_recibido': codigo_rfid
            }
        }, 200