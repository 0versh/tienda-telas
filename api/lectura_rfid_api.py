# api/lectura_rfid_api.py
from flask_restful import Resource
from flask import request
from flask_login import login_required
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database.db_connection import get_db_connection

class LecturaRFIDAPI(Resource):
    method_decorators = [login_required]

    def post(self):
        data = request.get_json()
        codigo_rfid = data.get('codigo_rfid')
        if not codigo_rfid:
            return {'status': 'error', 'message': 'Código RFID requerido'}, 400

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT ir.id_rollo, ir.metros_actuales, t.nombre_tela, t.precio_venta_metro
            FROM inventario_rollos ir
            JOIN telas t ON ir.id_tela = t.id_tela
            WHERE ir.codigo_rfid = %s
        """, (codigo_rfid,))
        rollo = cur.fetchone()
        cur.close()
        conn.close()

        if not rollo:
            return {'status': 'error', 'message': 'Rollo no encontrado'}, 404

        return {
            'status': 'success',
            'data': {
                'id_rollo': rollo[0],
                'metros_disponibles': float(rollo[1]),
                'nombre_tela': rollo[2],
                'precio_metro': float(rollo[3])
            }
        }, 200