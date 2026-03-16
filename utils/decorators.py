# utils/decorators.py
from functools import wraps
from flask import request
from models.log_model import LogModel
from flask_login import current_user

def log_action(accion, modulo):
    """Decorador para registrar acciones automáticamente"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Ejecutar la función
            resultado = f(*args, **kwargs)
            
            # Registrar el log
            try:
                if current_user and current_user.is_authenticated:
                    LogModel.registrar(
                        usuario_id=current_user.id,
                        accion=accion,
                        modulo=modulo,
                        detalle=request.path,
                        ip=request.remote_addr
                    )
            except:
                pass
            
            return resultado
        return decorated_function
    return decorator