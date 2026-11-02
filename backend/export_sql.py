"""Export the Mood Wear SQLite database to portable SQL files.

Outputs (same folder as this script):
- database_export_sqlite.sql  -> import with sqlite3:  sqlite3 new.db < database_export_sqlite.sql
- database_export_mysql.sql   -> import with MySQL:    mysql -u USER -p moodwear < database_export_mysql.sql

Run after starting the backend once (main.py seeds all tables on startup),
or directly:  python3 export_sql.py
"""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), 'fashion.db')
c = sqlite3.connect(DB)
c.row_factory = sqlite3.Row

# ---------- SQLite dump ----------
with open(os.path.join(os.path.dirname(__file__), 'database_export_sqlite.sql'), 'w', encoding='utf-8') as f:
    for line in c.iterdump():
        f.write(line + '\n')
print('wrote database_export_sqlite.sql')

# ---------- MySQL dump (proper PK / FK, importable with phpMyAdmin) ----------
TABLES = {
    'products': ('id', "id INT PRIMARY KEY, name VARCHAR(255) NOT NULL, price INT NOT NULL, category VARCHAR(50), stock INT, img VARCHAR(255) DEFAULT '', vgroup VARCHAR(64) DEFAULT '', vname VARCHAR(128) DEFAULT '', vorder INT DEFAULT 0"),
    'users': ('id', 'id INT PRIMARY KEY, username VARCHAR(100) NOT NULL, email VARCHAR(150) NOT NULL UNIQUE, phone VARCHAR(30), password_hash VARCHAR(64) NOT NULL'),
    'orders': ('id', 'id INT PRIMARY KEY, user_id INT, address VARCHAR(255) NOT NULL, total INT NOT NULL, created_at DATETIME, FOREIGN KEY (user_id) REFERENCES users(id)'),
    'order_items': ('id', 'id INT PRIMARY KEY, order_id INT NOT NULL, product_id INT NOT NULL, quantity INT NOT NULL, size VARCHAR(20), color VARCHAR(64), unit_price INT NOT NULL, FOREIGN KEY (order_id) REFERENCES orders(id), FOREIGN KEY (product_id) REFERENCES products(id)'),
    'cart_items': ('id', 'id INT PRIMARY KEY, user_id INT NOT NULL, product_id INT NOT NULL, quantity INT DEFAULT 1, size VARCHAR(20) DEFAULT "M", color VARCHAR(64) DEFAULT "", UNIQUE (user_id, product_id, size, color), FOREIGN KEY (user_id) REFERENCES users(id), FOREIGN KEY (product_id) REFERENCES products(id)'),
    'favorites': (None, 'user_id INT NOT NULL, product_id INT NOT NULL, created_at DATETIME, PRIMARY KEY (user_id, product_id), FOREIGN KEY (user_id) REFERENCES users(id), FOREIGN KEY (product_id) REFERENCES products(id)'),
}

def esc(v):
    if v is None: return 'NULL'
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace('\\', '\\\\').replace("'", "''") + "'"

cols = {t: [r[1] for r in c.execute(f'PRAGMA table_info({t})').fetchall()] for t in TABLES}

with open(os.path.join(os.path.dirname(__file__), 'database_export_mysql.sql'), 'w', encoding='utf-8') as f:
    f.write('-- Mood Wear — 802244 Digital Database Final Project\n')
    f.write('CREATE DATABASE IF NOT EXISTS moodwear CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\nUSE moodwear;\n')
    f.write('SET FOREIGN_KEY_CHECKS=0;\n')
    for t in reversed(list(TABLES)):
        f.write(f'DROP TABLE IF EXISTS {t};\n')
    for t, (_pk, ddl) in TABLES.items():
        f.write(f'CREATE TABLE {t} ({ddl});\n')
    for t in TABLES:
        for r in c.execute(f'SELECT * FROM {t} ORDER BY 1').fetchall():
            vals = ', '.join(esc(r[k]) for k in cols[t])
            f.write(f"INSERT INTO {t} ({', '.join(cols[t])}) VALUES ({vals});\n")
    f.write('SET FOREIGN_KEY_CHECKS=1;\n')
print('wrote database_export_mysql.sql')

for t in TABLES:
    print(t, c.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0], 'rows')
