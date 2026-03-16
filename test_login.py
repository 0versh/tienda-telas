# test_login.py
from werkzeug.security import generate_password_hash, check_password_hash
import psycopg2

# Conectar a la BD
conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="inventario_telas",
    user="postgres",
    password="Kidover2020"
)

cur = conn.cursor()

# Verificar usuario
cur.execute("SELECT id_usuario, nombre_usuario, contrasena_hash FROM usuarios WHERE nombre_usuario = 'admin'")
usuario = cur.fetchone()

if usuario:
    print(f"Usuario encontrado: {usuario[1]}")
    print(f"Hash: {usuario[2][:50]}...")
    
    # Probar contraseña
    contraseña = "admin123"
    if check_password_hash(usuario[2], contraseña):
        print("✅ Contraseña correcta")
    else:
        print("❌ Contraseña incorrecta")
        
        # Generar nuevo hash
        nuevo_hash = generate_password_hash("admin123")
        print(f"Nuevo hash generado: {nuevo_hash[:50]}...")
        
        # Actualizar
        cur.execute("UPDATE usuarios SET contrasena_hash = %s WHERE nombre_usuario = 'admin'", (nuevo_hash,))
        conn.commit()
        print("✅ Contraseña actualizada")
else:
    print("❌ Usuario no encontrado")

cur.close()
conn.close()