# api/lectura_rfid_api.py
from flask_restful import Resource
from flask import request
from flask_login import login_required, current_user
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection
from datetime import datetime

class LecturaRFIDAPI(Resource):
    method_decorators = [login_required]
    
    def post(self):
        """
        Endpoint para recibir lecturas de tags RFID
        Espera: {"codigo_rfid": "RFID-00000001", "tipo": "entrada", "metros": 5}
        """
        data = request.get_json()
        codigo_rfid = data.get('codigo_rfid')
        tipo = data.get('tipo')  # 'entrada' o 'salida'
        metros = data.get('metros')  # solo para salidas (ventas)
        
        if not codigo_rfid:
            return {'status': 'error', 'message': 'Código RFID requerido'}, 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Buscar rollo por RFID
        cur.execute("""
            SELECT ir.id_rollo, ir.metros_actuales, t.nombre_tela, t.precio_venta_metro
            FROM inventario_rollos ir
            JOIN telas t ON ir.id_tela = t.id_tela
            WHERE ir.codigo_rfid = %s
        """, (codigo_rfid,))
        
        rollo = cur.fetchone()
        
        if not rollo:
            return {'status': 'error', 'message': 'Rollo no encontrado'}, 404
        
        if tipo == 'entrada':
            # Registrar entrada de rollo (compra)
            return {
                'status': 'success',
                'accion': 'entrada',
                'data': {
                    'id_rollo': rollo[0],
                    'nombre_tela': rollo[2],
                    'metros_actuales': float(rollo[1])
                },
                'mensaje': 'Rollo listo para registrar entrada'
            }
        
        elif tipo == 'salida':
            # Registrar salida para venta
            if not metros:
                return {'status': 'error', 'message': 'Metros requeridos para salida'}, 400
            
            if metros > rollo[1]:
                return {'status': 'error', 'message': f'Solo hay {rollo[1]} metros disponibles'}, 400
            
            return {
                'status': 'success',
                'accion': 'salida',
                'data': {
                    'id_rollo': rollo[0],
                    'nombre_tela': rollo[2],
                    'metros_disponibles': float(rollo[1]),
                    'precio_metro': float(rollo[3])
                },
                'mensaje': f'Rollo encontrado. {metros} m a facturar'
            }
        
        cur.close()
        conn.close()
        
        return {'status': 'success', 'data': {'id_rollo': rollo[0], 'nombre_tela': rollo[2]}}, 200