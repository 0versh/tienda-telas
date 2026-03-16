# app.py
from flask import Flask, render_template, redirect, url_for
from flask_login import LoginManager, current_user
from config import Config
from database.db_connection import test_connection
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Crear aplicación Flask
app = Flask(__name__)
app.config.from_object(Config)
app.config['SECRET_KEY'] = 'mi-clave-secreta-2025'

# Configurar Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'auth.login'  
login_manager.login_message = 'Por favor inicia sesión para acceder a esta página'
login_manager.login_message_category = 'info'

# Importar modelos después de crear app
from models.usuario_model import UsuarioModel, Usuario

@login_manager.user_loader
def load_user(user_id):
    return UsuarioModel.obtener_por_id(int(user_id))

# Importar blueprints
from routes.productos_routes import productos_bp
from routes.inventario_routes import inventario_bp
from routes.ventas_routes import ventas_bp
from routes.auth_routes import auth_bp
from routes.usuarios_routes import usuarios_bp

# Registrar blueprints
app.register_blueprint(productos_bp)
app.register_blueprint(inventario_bp)
app.register_blueprint(ventas_bp)
app.register_blueprint(auth_bp)
app.register_blueprint(usuarios_bp)

@app.route('/')
def inicio():
    """Página principal - Dashboard"""
    if not current_user.is_authenticated:
        return render_template('auth/login.html')
    return render_template('index.html')

@app.route('/test-db')
def test_db():
    if test_connection():
        return """
        <h2>✅ Conexión exitosa a PostgreSQL</h2>
        <p><a href='/'>Volver</a></p>
        """
    else:
        return """
        <h2>❌ Error de conexión</h2>
        <p><a href='/'>Volver</a></p>
        """

if __name__ == '__main__':
    logger.info("Iniciando aplicación de inventario de telas")
    app.run(debug=True, port=5000)