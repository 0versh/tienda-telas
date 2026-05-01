import psycopg2
import os

DATABASE_URL = os.getenv('DATABASE_URL')

if not DATABASE_URL:
    print("❌ No se encontró DATABASE_URL. Asegúrate de que la variable de entorno esté configurada.")
    exit(1)

# Conectar a la base de datos
conn = psycopg2.connect(DATABASE_URL)
conn.autocommit = True
cur = conn.cursor()

# Leer el archivo SQL desde el mismo directorio
with open('respaldo.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

# Limpiar líneas problemáticas (comandos psql y OWNER TO)
lines = sql.splitlines()
clean_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('\\') or 'OWNER TO' in stripped:
        continue
    clean_lines.append(line)

clean_sql = '\n'.join(clean_lines)

try:
    cur.execute(clean_sql)
    print("✅ Backup importado exitosamente")
except Exception as e:
    print(f"❌ Error durante la importación: {e}")

cur.close()
conn.close()