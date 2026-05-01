import os
from dotenv import load_dotenv

# Cargar variables del archivo .env solo en desarrollo local
# En producción, Render inyecta las variables directamente
load_dotenv()

class Config:
    # Base de datos: primero intenta usar DATABASE_URL (Render) o la conexión local
    DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:Kidover2020@localhost:5432/inventario_telas')
    
    # Seguridad
    SECRET_KEY = os.getenv('SECRET_KEY', 'clave-secreta-temporal-para-desarrollo')
    
    # Modo debug: desactivado en producción por defecto
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'