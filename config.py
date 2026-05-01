# config.py
import os
from dotenv import load_dotenv

# Cargar variables del archivo .env
load_dotenv()

class Config:
    # Base de datos
    DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://localhost/inventario_telas')
    DB_HOST = os.getenv('DB_HOST')
    DB_PORT = os.getenv('DB_PORT')
    DB_NAME = os.getenv('DB_NAME')
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    
    # App
    SECRET_KEY = os.getenv('SECRET_KEY', 'clave-secreta-temporal')
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
