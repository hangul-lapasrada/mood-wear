from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import sqlite3, hashlib, os, random
random.seed(2569)
DB=os.path.join(os.path.dirname(__file__),'fashion.db')
app=FastAPI(title='Mood Wear API')
app.add_middleware(CORSMiddleware,allow_origins=['*'],allow_methods=['*'],allow_headers=['*'])
def hashed(s):return hashlib.sha256(s.encode()).hexdigest()
def conn():
 c=sqlite3.connect(DB);c.row_factory=sqlite3.Row;c.execute('PRAGMA foreign_keys=ON');return c

# name, price, category, stock, img, vgroup, vname, vorder
SEED=[
 ('Adidas Samba OG — Cloud White / Core Black',5200,'Shoes',12,'products/adidas-samba-og-cloud-white-core-black-1.jpg.webp','samba','Cloud White / Core Black',1),
 ('Adidas Samba OG — Core White / Halo Blue',5200,'Shoes',9,'products/adidas-samba-og-core-white-halo-blue-1.jpg.webp','samba','Core White / Halo Blue',2),
 ('Adidas Samba OG — Black / White / Gum',5600,'Shoes',7,'products/B75807-adidas-samba-og-black-white-gum-1.jpg.webp','samba','Black / White / Gum',3),
 ('Adidas Samba OG — White / Better Scarlet',5200,'Shoes',10,'products/IG1025-adidas-samba-og-white-better-scarlet-1.jpg.webp','samba','White / Better Scarlet',4),
 ('AMI Paris De Coeur T-Shirt — Black',2090,'Upper',20,'products/BFUTS035-724-001-ami-paris-de-coeur-t-shirt-black-1.jpg.webp','ami-tee','Black',1),
 ('AMI Paris Cotton De Coeur T-Shirt — Heather Ash Grey',2190,'Upper',15,'products/BFUTS035-724-0951-ami-paris-cotton-ami-de-coeur-t-shirt-heather-ash-grey-1.jpg.webp','ami-tee','Heather Ash Grey',2),
 ('AMI De Coeur Organic Cotton Jersey T-Shirt — White',2090,'Upper',18,'products/BFUTS035-724-100-ami-de-coeur-oragnic-cotton-jersey-t-shirt-white-1.jpg.webp','ami-tee','White',3),
 ('AMI Paris De Coeur T-Shirt — Navy Blue',2190,'Upper',14,'products/BFUTS035-724-430-ami-paris-cotton-ami-de-coeur-t-shirt-navy-blue-1.jpg.webp','ami-tee','Navy Blue',4),
 ('Nike Jacket — Grey',4290,'Upper',8,'products/727325-084-nike-jackets-men-gray-1.jpg.webp','nike-jacket','Grey',1),
 ('Nike Jacket — White',4290,'Upper',6,'products/DH6685-072-nike-jackets-men-white-1.jpg.webp','nike-jacket','White',2),
 ('Nike Jacket — Black',4390,'Upper',9,'products/DV1363-010-nike-jackets-men-black-1.jpg.webp','nike-jacket','Black',3),
 ('Fear of God Essentials Relaxed Sweatpant — Black',2890,'Bottom',17,'products/fear-of-god-essentials-fleece-relaxed-sweatpant-black-fw24-1.jpg.webp','essentials-pant','Black',1),
 ('Fear of God Essentials Relaxed Sweatpant — Dark Heather',2890,'Bottom',12,'products/fear-of-god-essentials-fleece-relaxed-sweatpant-dark-heather-fw24-1.jpg.webp','essentials-pant','Dark Heather',2),
 ('Fear of God Essentials Relaxed Sweatpant — Military',2990,'Bottom',10,'products/fear-of-god-essentials-fleece-relaxed-sweatpant-military-fw24-1.jpg.webp','essentials-pant','Military',3),
 ('Fear of God Essentials Relaxed Sweatpant — Olive',2990,'Bottom',11,'products/fear-of-god-essentials-fleece-relaxed-sweatpant-olive-fw24-1.jpg.webp','essentials-pant','Olive',4),
 ('Vivienne Westwood Mini Bas Relief Pendant Necklace 48cm — Silver Tone w/ Crystal Orb',12500,'Accessories',5,'products/63020086-02p116-vivienne-westwood-mini-bas-relief-pendant-necklace-48cm-in-silver-tone-plating-with-crystal-encrusted-orb-1.jpg.webp','vw-necklace','Silver Tone / Crystal Orb',1),
 ('Vivienne Westwood Mini Bas Relief Pendant Necklace 48cm — Polished Silver',12900,'Accessories',4,'products/63020086-02p116-vivienne-westwood-mini-bas-relief-pendant-necklace-48cm-in-silver-tone-plating-with-crystal-encrusted-orb-2.jpg.webp','vw-necklace','Polished Silver',2),
 ('Human Made Daily Cap — Black Front Logo',1890,'Hat',15,'products/HM29GD-BLACK-human-madedaily-cap-290404-black-2025-1.jpg.webp','hm-cap','Black / Front Logo',1),
 ('Human Made Daily Cap — Black Back Logo',1990,'Hat',15,'products/HM29GD-BLACK-human-madedaily-cap-290404-black-2025-2.jpg.webp','hm-cap','Black / Back Logo',2),
 ('Studio Fit — Tee + Sweatpant + Samba',10180,'Set',5,'products/B75807-adidas-samba-og-black-white-gum-1.jpg.webp','set-bundle','Bundle',1),
]

# Extra rows so every table meets the >=50-row requirement of 802244 Digital Database.
IMG={'samba-w':'products/adidas-samba-og-cloud-white-core-black-1.jpg.webp',
     'samba-b':'products/adidas-samba-og-core-white-halo-blue-1.jpg.webp',
     'samba-g':'products/B75807-adidas-samba-og-black-white-gum-1.jpg.webp',
     'tee-b':'products/BFUTS035-724-001-ami-paris-de-coeur-t-shirt-black-1.jpg.webp',
     'tee-g':'products/BFUTS035-724-0951-ami-paris-cotton-ami-de-coeur-t-shirt-heather-ash-grey-1.jpg.webp',
     'tee-w':'products/BFUTS035-724-100-ami-de-coeur-oragnic-cotton-jersey-t-shirt-white-1.jpg.webp',
     'tee-n':'products/BFUTS035-724-430-ami-paris-cotton-ami-de-coeur-t-shirt-navy-blue-1.jpg.webp',
     'jkt':'products/727325-084-nike-jackets-men-gray-1.jpg.webp',
     'pant':'products/fear-of-god-essentials-fleece-relaxed-sweatpant-black-fw24-1.jpg.webp',
     'cap':'products/HM29GD-BLACK-human-madedaily-cap-290404-black-2025-1.jpg.webp',
     'neck':'products/63020086-02p116-vivienne-westwood-mini-bas-relief-pendant-necklace-48cm-in-silver-tone-plating-with-crystal-encrusted-orb-1.jpg.webp'}
EXTRA=[
 (f'Adidas Samba OG — Variation {i:02d} — Colorway Collection',5200+(i-1)%3*200,'Shoes',8+(i%13),IMG['samba-w' if i%2==0 else 'samba-b'] if i%3==0 else IMG['samba-g'],f'samba-x{i}','Colorway '+str(i),i) for i in range(1,11)
]+[
 (f'AMI Paris Ami De Coeur Tee — Seasonal Print {i:02d}',1990+(i-1)%4*150,'Upper',12+(i%9),[IMG[k] for k in ['tee-b','tee-g','tee-w','tee-n']][i%4],f'ami-x{i}','Print '+str(i),i) for i in range(1,11)
]+[
 (f'Nike Woven Jacket — Utility Edition {i:02d}',4290+(i-1)%3*300,'Upper',6+(i%8),IMG['jkt'],f'jkt-x{i}','Edition '+str(i),i) for i in range(1,7)
]+[
 (f'Fear of God Essentials Sweatpant — Seasonal {i:02d}',2890+(i-1)%2*100,'Bottom',10+(i%10),IMG['pant'],f'pant-x{i}','Seasonal '+str(i),i) for i in range(1,7)
]+[
 (f'Human Made Daily Cap — Archive Print {i:02d}',1890+(i-1)*100,'Hat',14-(i%6),IMG['cap'],f'cap-x{i}','Archive '+str(i),i) for i in range(1,6)
]+[
 (f'Vivienne Westwood Bas Relief — Orb Edition {i:02d}',12500+i*250,'Accessories',3+(i%5),IMG['neck'],f'neck-x{i}','Orb Edition '+str(i),i) for i in range(1,6)
]+[
 ('Studio Fit — Samba + Tee Full Look',11490,'Set',4,IMG['samba-w'],'set-full-look','Full Look',1),
 ('Studio Fit — Jacket + Pant Layer Set',9980,'Set',3,IMG['jkt'],'set-layer','Layer Set',2),
 ('Studio Fit — Cap + Tee Everyday Set',4580,'Set',6,IMG['cap'],'set-everyday','Everyday Set',3),
 ('Studio Fit — Necklace + Tee Accessory Set',5390,'Set',2,IMG['neck'],'set-accessory','Accessory Set',4),
]
NAMES=['Kanin','Prim','Bright','Yuki','Mew','Aom','Peak','Nine','Tara','Namtan','Tor','Gun','James','Pink','Fern','Petch','Yoda','Mark','Britain','Singto']
DOMS=['gmail.com','outlook.com','moodwear.shop']
def init():
 with conn() as c:
  c.execute("CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY,name TEXT,price INTEGER,category TEXT,stock INTEGER,img TEXT DEFAULT '',vgroup TEXT DEFAULT '',vname TEXT DEFAULT '',vorder INTEGER DEFAULT 0)")
  c.execute('CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY,username TEXT,email TEXT UNIQUE,phone TEXT,password_hash TEXT)')
  c.execute('CREATE TABLE IF NOT EXISTS orders(id INTEGER PRIMARY KEY,user_id INTEGER,address TEXT,total INTEGER,created_at TEXT DEFAULT CURRENT_TIMESTAMP)')
  c.execute('CREATE TABLE IF NOT EXISTS order_items(id INTEGER PRIMARY KEY,order_id INTEGER,product_id INTEGER,quantity INTEGER,size TEXT,color TEXT,unit_price INTEGER)')
  # Per-user basket and favorites so the app state survives closing the app.
  c.execute("CREATE TABLE IF NOT EXISTS cart_items(id INTEGER PRIMARY KEY,user_id INTEGER,product_id INTEGER,quantity INTEGER DEFAULT 1,size TEXT DEFAULT 'M',color TEXT DEFAULT '',UNIQUE(user_id,product_id,size,color))")
  c.execute('CREATE TABLE IF NOT EXISTS favorites(user_id INTEGER,product_id INTEGER,created_at TEXT DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(user_id,product_id))')
  cols=[r[1] for r in c.execute('PRAGMA table_info(products)').fetchall()]
  for col,typ,default in [('img','TEXT',"''"),('vgroup','TEXT',"''"),('vname','TEXT',"''"),('vorder','INTEGER','0')]:
   if col not in cols:
    c.execute(f'ALTER TABLE products ADD COLUMN {col} {typ} DEFAULT {default}')
  if not c.execute("SELECT COUNT(*) FROM products WHERE img<>''").fetchone()[0]:
   c.execute('DELETE FROM products')
   c.executemany('INSERT INTO products(name,price,category,stock,img,vgroup,vname,vorder) VALUES(?,?,?,?,?,?,?,?)',SEED)
  if c.execute('SELECT COUNT(*) FROM products').fetchone()[0] < 50:
   have={r[0] for r in c.execute('SELECT vgroup FROM products').fetchall()}
   c.executemany('INSERT INTO products(name,price,category,stock,img,vgroup,vname,vorder) VALUES(?,?,?,?,?,?,?,?)',[p for p in EXTRA if p[5] not in have])
  # 50 demo users (ids 2..51) — user id 1 stays untouched for the app.
  if c.execute('SELECT COUNT(*) FROM users').fetchone()[0] < 51:
   for i in range(2,52):
    n=NAMES[(i-2)%len(NAMES)]+'_u%03d'%i
    c.execute('INSERT OR IGNORE INTO users(username,email,phone,password_hash) VALUES(?,?,?,?)',(n,n.lower()+'@'+DOMS[i%3],'0812345'+format(i,'03d'),hashed('password123')))
  # 52 orders across demo users + order items (>=50 rows each).
  if c.execute('SELECT COUNT(*) FROM orders').fetchone()[0] < 52:
   pids=[r[0] for r in c.execute('SELECT id FROM products').fetchall()]
   for oi in range(52):
    d,h=1+oi%28,(oi*7)%24
    cur=c.execute("INSERT INTO orders(user_id,address,total,created_at) VALUES(?,?,?,?)",(2+oi%50,random.choice(['1 Sukhumvit Rd, Bangkok','88 Rama I Rd, Bangkok','45 Nimman Rd, Chiang Mai','2 Charoen Krung Rd, Bangkok']),0,f'2026-10-{d:02d} {h:02d}:{(oi*11)%60:02d}:00'))
    oid=cur.lastrowid;total=0
    for p_id in random.sample(pids,1+oi%3):
     p=c.execute('SELECT price,stock FROM products WHERE id=?',(p_id,)).fetchone()
     qty=1+oi%3;total+=p[0]*qty
     c.execute('INSERT INTO order_items(order_id,product_id,quantity,size,color,unit_price) VALUES(?,?,?,?,?,?)',(oid,p_id,qty,random.choice(['S','M','L','8 US','9 US']),['','Black','White'][oi%3],p[0]))
    c.execute('UPDATE orders SET total=? WHERE id=?',(total,oid))
  # >=50 cart rows + >=50 favorites, always for demo users, never user 1.
  if c.execute('SELECT COUNT(*) FROM cart_items').fetchone()[0] < 52:
   pids=[r[0] for r in c.execute('SELECT id FROM products').fetchall()]
   for i,uid in enumerate([2+i%50 for i in range(52)]):
    c.execute('INSERT OR IGNORE INTO cart_items(user_id,product_id,quantity,size,color) VALUES(?,?,?,?,?)',(uid,pids[i%len(pids)],1+i%3,['S','M','L','8 US','9 US'][i%5],['','Black','White','Navy'][i%4]))
  if c.execute('SELECT COUNT(*) FROM favorites').fetchone()[0] < 52:
   pids=[r[0] for r in c.execute('SELECT id FROM products').fetchall()]
   for i in range(52):
    c.execute('INSERT OR IGNORE INTO favorites(user_id,product_id,created_at) VALUES(?,?,?)',(2+i%50,pids[(i*7+i//50)%len(pids)],f'2026-10-{1+i%28:02d} 09:{i%60:02d}:00'))
init()

class User(BaseModel):
 username:str;email:str;password:str;phone:str=''
class Login(BaseModel):
 email:str;password:str
class Item(BaseModel):
 product_id:int;quantity:int=1;size:str='M';color:str='Blue'
class Order(BaseModel):
 user_id:int|None=None;address:str;items:list[Item]
class CartAdd(BaseModel):
 user_id:int;product_id:int;quantity:int=1;size:str='M';color:str=''
class CartUpdate(BaseModel):
 quantity:int
class FavToggle(BaseModel):
 user_id:int;product_id:int

def pcols(r):
 return {k:r[k] for k in ('id','name','price','category','stock','img','vgroup','vname','vorder')}

@app.get('/products')
def products(category:str|None=None,search:str|None=None):
 sql='SELECT * FROM products WHERE 1=1';args=[]
 if category and category!='New Arrival':sql+=' AND category=?';args.append(category)
 if search:sql+=' AND name LIKE ?';args.append('%'+search+'%')
 sql+=' ORDER BY vgroup,vorder'
 with conn() as c:return [dict(r) for r in c.execute(sql,args)]
@app.get('/products/{pid}')
def product(pid:int):
 with conn() as c:r=c.execute('SELECT * FROM products WHERE id=?',(pid,)).fetchone()
 if not r:raise HTTPException(404,'Product not found')
 return dict(r)
@app.post('/register')
def register(u:User):
 if not u.username.strip() or '@' not in u.email or len(u.password)<6:raise HTTPException(400,'Enter username, valid email, password >= 6 characters')
 try:
  with conn() as c:
   cur=c.execute('INSERT INTO users(username,email,phone,password_hash) VALUES(?,?,?,?)',(u.username,u.email.lower(),u.phone,hashed(u.password)))
   return {'id':cur.lastrowid,'username':u.username,'email':u.email}
 except sqlite3.IntegrityError:raise HTTPException(409,'Email already registered')
@app.post('/login')
def login(u:Login):
 with conn() as c:r=c.execute('SELECT id,username,email FROM users WHERE email=? AND password_hash=?',(u.email.lower(),hashed(u.password))).fetchone()
 if not r:raise HTTPException(401,'Invalid credentials')
 return dict(r)
@app.post('/orders')
def order(o:Order):
 if not o.address.strip() or not o.items:raise HTTPException(400,'Address and items required')
 with conn() as c:
  total=0;rows=[]
  for item in o.items:
   p=c.execute('SELECT * FROM products WHERE id=?',(item.product_id,)).fetchone()
   if not p or item.quantity<1 or item.quantity>p['stock']:raise HTTPException(400,'Invalid quantity or insufficient stock')
   total+=p['price']*item.quantity;rows.append((p,item))
  cur=c.execute('INSERT INTO orders(user_id,address,total) VALUES(?,?,?)',(o.user_id,o.address,total));oid=cur.lastrowid
  for p,item in rows:
   c.execute('INSERT INTO order_items(order_id,product_id,quantity,size,color,unit_price) VALUES(?,?,?,?,?,?)',(oid,p['id'],item.quantity,item.size,item.color,p['price']))
   c.execute('UPDATE products SET stock=stock-? WHERE id=?',(item.quantity,p['id']))
 return {'order_id':oid,'subtotal':total,'delivery_fee':0,'total':total}
@app.get('/orders')
def order_history(user_id:int):
 with conn() as c:
  out=[]
  for o in c.execute('SELECT * FROM orders WHERE user_id=? ORDER BY id DESC',(user_id,)):
   oi=c.execute('SELECT oi.*,p.name FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=?',(o['id'],)).fetchall()
   out.append({'id':o['id'],'address':o['address'],'total':o['total'],'created_at':o['created_at'],'items':[dict(r) for r in oi]})
  return out

# ---- Basket (cart_items table) ------------------------------------------
@app.get('/cart')
def get_cart(user_id:int):
 with conn() as c:
  rows=c.execute('SELECT ci.id AS cid,ci.quantity,ci.size,ci.color,p.*,p.id AS pid FROM cart_items ci JOIN products p ON p.id=ci.product_id WHERE ci.user_id=? ORDER BY ci.id',(user_id,)).fetchall()
  return [{'id':r['cid'],'quantity':r['quantity'],'size':r['size'],'color':r['color'],'product':pcols(r)} for r in rows]
@app.put('/cart/{cid}')
def update_cart(cid:int,q:CartUpdate):
 with conn() as c:
  r=c.execute('SELECT ci.*,p.stock FROM cart_items ci JOIN products p ON p.id=ci.product_id WHERE ci.id=?',(cid,)).fetchone()
  if not r:raise HTTPException(404,'Cart item not found')
  if q.quantity<1:
   c.execute('DELETE FROM cart_items WHERE id=?',(cid,));return {'id':cid,'deleted':True}
  c.execute('UPDATE cart_items SET quantity=? WHERE id=?',(min(q.quantity,r['stock']),cid))
  return {'id':cid,'quantity':min(q.quantity,r['stock'])}
@app.delete('/cart/{cid}')
def delete_cart(cid:int):
 with conn() as c:
  c.execute('DELETE FROM cart_items WHERE id=?',(cid,));return {'id':cid,'deleted':True}
@app.delete('/cart')
def clear_cart(user_id:int):
 with conn() as c:
  c.execute('DELETE FROM cart_items WHERE user_id=?',(user_id,));return {'cleared':True}
# POST /cart upserts by (user, product, size, color) and SETs the quantity,
# so the app can simply mirror its local basket state on every change.
@app.post('/cart')
def add_cart(item:CartAdd):
 with conn() as c:
  p=c.execute('SELECT stock FROM products WHERE id=?',(item.product_id,)).fetchone()
  if not p:raise HTTPException(404,'Product not found')
  row=c.execute('SELECT id FROM cart_items WHERE user_id=? AND product_id=? AND size=? AND color=?',(item.user_id,item.product_id,item.size,item.color)).fetchone()
  if item.quantity<1:
   if row:c.execute('DELETE FROM cart_items WHERE id=?',(row['id'],))
   return {'id':row['id'] if row else None,'quantity':0}
  q=min(item.quantity,p['stock'])
  if row:
   c.execute('UPDATE cart_items SET quantity=? WHERE id=?',(q,row['id']));cid=row['id']
  else:
   cid=c.execute('INSERT INTO cart_items(user_id,product_id,quantity,size,color) VALUES(?,?,?,?,?)',(item.user_id,item.product_id,q,item.size,item.color)).lastrowid
  return {'id':cid,'quantity':q}

# ---- Favorites ----------------------------------------------------------
@app.get('/favorites')
def get_favorites(user_id:int):
 with conn() as c:return [dict(r) for r in c.execute('SELECT p.* FROM favorites f JOIN products p ON p.id=f.product_id WHERE f.user_id=? ORDER BY f.created_at DESC',(user_id,))]
@app.post('/favorites')
def add_favorite(t:FavToggle):
 with conn() as c:
  if not c.execute('SELECT 1 FROM products WHERE id=?',(t.product_id,)).fetchone():raise HTTPException(404,'Product not found')
  c.execute('INSERT OR IGNORE INTO favorites(user_id,product_id) VALUES(?,?)',(t.user_id,t.product_id));return {'saved':True}
@app.delete('/favorites/{user_id}/{product_id}')
def delete_favorite(user_id:int,product_id:int):
 with conn() as c:
  c.execute('DELETE FROM favorites WHERE user_id=? AND product_id=?',(user_id,product_id));return {'removed':True}

# ---- Back office CRUD (802244 Digital Database final project) -----------
ADMIN={
 'products':{'pk':'id','cols':['name','price','category','stock','img','vgroup','vname','vorder']},
 'users':{'pk':'id','cols':['username','email','phone','password_hash']},
 'orders':{'pk':'id','cols':['user_id','address','total','created_at']},
 'order_items':{'pk':'id','cols':['order_id','product_id','quantity','size','color','unit_price']},
 'cart_items':{'pk':'id','cols':['user_id','product_id','quantity','size','color']},
 'favorites':{'pk':None,'cols':['user_id','product_id','created_at']}}
@app.get('/admin')
def admin_page():return FileResponse(os.path.join(os.path.dirname(__file__),'admin.html'))
@app.get('/admin/stats')
def admin_stats():
 with conn() as c:return {t:c.execute('SELECT COUNT(*) FROM '+t).fetchone()[0] for t in ADMIN}
@app.get('/admin/t/{t}')
def admin_list(t:str,q:str|None=None):
 if t not in ADMIN:raise HTTPException(404,'Unknown table')
 s=ADMIN[t];sql='SELECT * FROM '+t;args=[]
 if q and q.strip():
  args=['%'+q+'%']*len(s['cols']);sql+=' WHERE '+' OR '.join(f"CAST({col} AS TEXT) LIKE ?" for col in s['cols'])
 sql+=' ORDER BY '+('user_id,product_id' if s['pk'] is None else s['pk'])+' LIMIT 300'
 with conn() as c:return [dict(r) for r in c.execute(sql,args)]
@app.post('/admin/t/{t}')
def admin_insert(t:str,body:dict):
 if t not in ADMIN:raise HTTPException(404,'Unknown table')
 s=ADMIN[t];d={k:body[k] for k in s['cols'] if k in body and body[k] is not None}
 if not d:raise HTTPException(400,'No valid fields')
 try:
  with conn() as c:
   cur=c.execute(f'INSERT INTO {t}({",".join(d)}) VALUES({",".join("?"*len(d))})',list(d.values()))
   return {'id':cur.lastrowid,'inserted':True}
 except sqlite3.IntegrityError as e:raise HTTPException(409,str(e))
@app.put('/admin/t/{t}/{pid}')
def admin_update(t:str,pid:int,body:dict):
 if t not in ADMIN:raise HTTPException(404,'Unknown table')
 s=ADMIN[t]
 if not s['pk']:raise HTTPException(405,'This table has a composite key; edit via insert/delete')
 d={k:body[k] for k in s['cols'] if k in body}
 if not d:raise HTTPException(400,'No valid fields')
 try:
  with conn() as c:
   cur=c.execute(f'UPDATE {t} SET {",".join(k+"=?" for k in d)} WHERE {s["pk"]}=?',list(d.values())+[pid])
   if not cur.rowcount:raise HTTPException(404,'Row not found')
   return {'id':pid,'updated':True}
 except sqlite3.IntegrityError as e:raise HTTPException(409,str(e))
@app.delete('/admin/t/{t}/{pid}')
def admin_delete(t:str,pid:int,uid:int|None=None):
 if t not in ADMIN:raise HTTPException(404,'Unknown table')
 s=ADMIN[t]
 with conn() as c:
  if s['pk'] is None: # favorites: composite PK (user_id, product_id)
   if uid is None:raise HTTPException(400,'favorites needs ?uid=user_id')
   c.execute('DELETE FROM favorites WHERE user_id=? AND product_id=?',(uid,pid));return {'deleted':True}
  c.execute(f'DELETE FROM {t} WHERE {s["pk"]}=?',(pid,));return {'id':pid,'deleted':True}
