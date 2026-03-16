# api/__init__.py
from flask import Blueprint
from flask_restful import Api
from .productos_api import ProductosAPI
from .inventario_api import InventarioAPI
from .ventas_api import VentasAPI
from .lectura_rfid_api import LecturaRFIDAPI 

api_bp = Blueprint('api', __name__, url_prefix='/api')
api = Api(api_bp)

api.add_resource(ProductosAPI, '/productos', '/productos/<int:id>')
api.add_resource(InventarioAPI, '/inventario', '/inventario/<int:id_rollo>')
api.add_resource(VentasAPI, '/ventas', '/ventas/<int:id_venta>')
api.add_resource(LecturaRFIDAPI, '/lectura-rfid')  

# Para depuración
print("✅ API blueprint creado correctamente")