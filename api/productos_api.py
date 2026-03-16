# api/productos_api.py
from flask_restful import Resource
from flask import request
from flask_login import login_required
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from models.producto_model import ProductoModel
from models.log_model import LogModel
from flask_login import current_user

class ProductosAPI(Resource):
    method_decorators = [login_required]
    
    def get(self, id=None):
        """GET /api/productos - Lista todos los productos
           GET /api/productos/<id> - Obtiene un producto específico"""
        if id:
            producto = ProductoModel.obtener_por_id(id)
            if producto:
                return {'status': 'success', 'data': producto}, 200
            return {'status': 'error', 'message': 'Producto no encontrado'}, 404
        else:
            productos = ProductoModel.obtener_todos()
            return {'status': 'success', 'data': productos}, 200
    
    def post(self):
        """POST /api/productos - Crea un nuevo producto"""
        data = request.get_json()
        try:
            id_producto = ProductoModel.crear(data)
            
            # Log de la acción
            LogModel.registrar(
                usuario_id=current_user.id,
                accion='crear',
                modulo='api_productos',
                detalle=f'Producto creado via API: {data["nombre"]}',
                ip=request.remote_addr
            )
            
            return {'status': 'success', 'id': id_producto}, 201
        except Exception as e:
            return {'status': 'error', 'message': str(e)}, 400
    
    def put(self, id):
        """PUT /api/productos/<id> - Actualiza un producto"""
        data = request.get_json()
        try:
            ProductoModel.actualizar(id, data)
            
            LogModel.registrar(
                usuario_id=current_user.id,
                accion='actualizar',
                modulo='api_productos',
                detalle=f'Producto {id} actualizado via API',
                ip=request.remote_addr
            )
            
            return {'status': 'success', 'message': 'Producto actualizado'}, 200
        except Exception as e:
            return {'status': 'error', 'message': str(e)}, 400
    
    def delete(self, id):
        """DELETE /api/productos/<id> - Elimina un producto"""
        try:
            ProductoModel.eliminar(id)
            
            LogModel.registrar(
                usuario_id=current_user.id,
                accion='eliminar',
                modulo='api_productos',
                detalle=f'Producto {id} eliminado via API',
                ip=request.remote_addr
            )
            
            return {'status': 'success', 'message': 'Producto eliminado'}, 200
        except Exception as e:
            return {'status': 'error', 'message': str(e)}, 400