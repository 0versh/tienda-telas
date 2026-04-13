# app.py
from flask import Flask, render_template, redirect, url_for
from flask_login import LoginManager, current_user
from flask_cors import CORS
from config import Config
from database.db_connection import test_connection, get_db_connection
import logging
import traceback
from datetime import datetime, timedelta
import psycopg2.extras
from routes.compras_routes import compras_bp 
from routes.rfid_routes import rfid_bp  

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config.from_object(Config)

# Configurar CORS
CORS(app)

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
from routes.proveedores_routes import proveedores_bp
from routes.alertas_routes import alertas_bp
from routes.logs_routes import logs_bp
from api import api_bp
from routes.compras_routes import compras_bp  
from routes.rfid_routes import rfid_bp 

# Registrar blueprints
app.register_blueprint(productos_bp)
app.register_blueprint(inventario_bp)
app.register_blueprint(ventas_bp)
app.register_blueprint(auth_bp)
app.register_blueprint(usuarios_bp)
app.register_blueprint(proveedores_bp)
app.register_blueprint(alertas_bp)
app.register_blueprint(logs_bp)
app.register_blueprint(api_bp)
app.register_blueprint(compras_bp)  
app.register_blueprint(rfid_bp)

# ============================================
# DASHBOARD PRINCIPAL 
# ============================================
@app.route('/')
def inicio():
    try:
        if not current_user.is_authenticated:
            return redirect(url_for('auth.login'))
        
        # OBTENER DATOS DE LA BD
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
        # 1. Total de productos
        cur.execute("SELECT COUNT(*) FROM telas WHERE activo = true")
        total_productos = cur.fetchone()[0]
        
        # 2. Total de rollos
        cur.execute("SELECT COUNT(*) FROM inventario_rollos WHERE metros_actuales > 0")
        total_rollos = cur.fetchone()[0]
        
        # 3. Stock crítico (solo el contador, sin detalles)
        cur.execute("""
            SELECT COUNT(*) FROM telas 
            WHERE activo = true AND stock_total_metros <= stock_minimo_metros
        """)
        stock_critico = cur.fetchone()[0]
        
        # 4. Ventas hoy
        hoy = datetime.now().date()
        cur.execute("""
            SELECT COALESCE(SUM(total_pagar), 0) 
            FROM ventas 
            WHERE DATE(fecha_venta) = %s AND estado = 'completada'
        """, (hoy,))
        ventas_hoy_total = float(cur.fetchone()[0])
        
        # 5. Ventas esta semana
        semana_inicio = hoy - timedelta(days=7)
        cur.execute("""
            SELECT COALESCE(SUM(total_pagar), 0) 
            FROM ventas 
            WHERE DATE(fecha_venta) >= %s AND estado = 'completada'
        """, (semana_inicio,))
        ventas_semana = float(cur.fetchone()[0])
        
        # 6. Ventas este mes
        mes_inicio = hoy.replace(day=1)
        cur.execute("""
            SELECT COALESCE(SUM(total_pagar), 0) 
            FROM ventas 
            WHERE DATE(fecha_venta) >= %s AND estado = 'completada'
        """, (mes_inicio,))
        ventas_mes = float(cur.fetchone()[0])
        
        cur.close()
        conn.close()
        
        # Crear diccionario de estadísticas 
        stats = {
            'total_productos': total_productos,
            'total_rollos': total_rollos,
            'stock_critico': stock_critico,
            'ventas_hoy_total': ventas_hoy_total,
            'ventas_semana': ventas_semana,
            'ventas_mes': ventas_mes
        }
        
        return render_template('index.html', stats=stats)
        
    except Exception as e:
        print(f"❌ ERROR EN DASHBOARD: {e}")
        traceback.print_exc()
        return render_template('index.html', stats={
            'total_productos': 0,
            'total_rollos': 0,
            'stock_critico': 0,
            'ventas_hoy_total': 0,
            'ventas_semana': 0,
            'ventas_mes': 0
        })

# ============================================
# RUTA DE PRUEBA DE BD
# ============================================
@app.route('/test-db')
def test_db():
    if test_connection():
        return """
        <h2>✅ Conexión exitosa a PostgreSQL</h2>
        <p><a href='/'>Volver al dashboard</a></p>
        """
    else:
        return """
        <h2>❌ Error de conexión</h2>
        <p><a href='/'>Volver al dashboard</a></p>
        """

if __name__ == '__main__':
    logger.info("🚀 Iniciando aplicación de inventario de telas")
    print("\n" + "="*50)
    print("🌐 Servidor corriendo en: http://localhost:5000")
    print("👤 Usuario: admin / admin123")
    print("="*50 + "\n")
    app.run(debug=True, port=5000)