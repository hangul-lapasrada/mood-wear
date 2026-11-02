# Mood Wear — Digital Database Final Project (802244)

ระบบร้านแฟชั่นออนไลน์ **Mood Wear** = Flutter app (หน้าร้าน) + FastAPI back office + ฐานข้อมูล SQLite
ตามข้อกำหนดวิชา 802244 DIGITAL DATABASE: มี 6 Entity, ความสัมพันธ์มากกว่า 5 ความสัมพันธ์,
ทุกตารางมีข้อมูลเกิน 50 แถว, มี PK/FK จริง, และมี Back office ที่ทำ **แสดง / เพิ่ม (Insert) / แก้ไข (Update) / ลบ (Delete)** ได้ทุกตาราง

## ข้อมูลตรงตามเกณฑ์

| เกณฑ์ | ของตอนนี้ |
|---|---|
| 5 Entity ขึ้นไป | `products`, `users`, `orders`, `order_items`, `cart_items`, `favorites` = **6 ตาราง** |
| ความสัมพันธ์ ≥ 3 | users→orders (1:M), orders→order_items (1:M), products→order_items (1:M), users→cart_items (1:M), products→cart_items (1:M), users↔products ผ่าน favorites (M:N) |
| แต่ละตาราง ≥ 50 แถว | products 66 · users 51 · orders 58 · order_items 111 · cart_items 52 · favorites 52 |
| Primary/Foreign Key | กำหนดครบทั้ง 6 ตาราง และเปิด `PRAGMA foreign_keys=ON` บังคับจริง |
| Back office + CRUD | เปิด http://127.0.0.1:8000/admin |
| Data source | สินค้ารวบรวมจากเว็บร้านแบรนด์ (Instant Data Scraping) แล้วยกระดับเป็นข้อมูลในตาราง |
| SQL Export | [backend/database_export_sqlite.sql](backend/database_export_sqlite.sql) + [backend/database_export_mysql.sql](backend/database_export_mysql.sql) |

## ความสัมพันธ์ของตาราง

- `users 1 ── M orders` (ผู้ใช้สั่งซื้อได้หลายครั้ง)
- `orders 1 ── M order_items` (1 คำสั่งซื้อมีหลายรายการ)
- `products 1 ── M order_items` (สินค้าถูกสั่งได้หลายครั้ง)
- `users 1 ── M cart_items` / `products 1 ── M cart_items` (ตะกร้า)
- `users M ── N products` ผ่านตารางกลาง `favorites`

แต่ละสินค้ามี **variants** (`vgroup` + `vname` + `vorder`) เช่น Adidas Samba แต่ละสี —
กลุ่มเดียวกันจะแสดงเป็นชิปสีเปลี่ยนชื่อ/ราคาได้ในหน้าสินค้าของแอป

## วิธีติดตั้ง (เครื่องใหม่)

ต้องมี: Python 3.11+ และ Flutter SDK (พร้อม `flutter doctor` ผ่าน)

### 1) Backend + ฐานข้อมูล

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

- ฐานข้อมูล `backend/fashion.db` จะถูกสร้าง + seed อัตโนมัติ (ครบ ≥50 แถวทุกตาราง)
- Back office: **http://127.0.0.1:8000/admin** — เลือกตารางจากแท็บ, ค้นหา, กด + เพิ่มข้อมูล, แก้ไข, ลบ ได้
- API docs (FastAPI Swagger): http://127.0.0.1:8000/docs

### 2) นำเข้าฐานข้อมูลจากไฟล์ SQL บนเครื่องอื่น (ถ้าต้องการใช้ข้อมูลชุดเดิม)

**SQLite (ใช้กับระบบนี้โดยตรง):**

```bash
sqlite3 backend/fashion.db < backend/database_export_sqlite.sql
```

**MySQL/phpMyAdmin (ต้องแก้ backend/main.py: แทน sqlite3 น้อยที่สุด):**

```sql
SOURCE database_export_mysql.sql;  -- ใน mysql client
-- หรือ import ไฟล์ผ่าน phpMyAdmin (ครบ PK/FK + SET FOREIGN_KEY_CHECKS)
```

ไฟล์ MySQL จะสร้างฐานข้อมูลชื่อ `moodwear` ให้พร้อมข้อมูลครบทุกตาราง

### 3) แอป Flutter

```bash
flutter pub get
# Android emulator:
flutter run --dart-define=API_URL=http://10.0.2.2:8000
# iOS simulator / Chrome:
flutter run --dart-define=API_URL=http://127.0.0.1:8000 -d chrome
```

โครงสร้างโค้ด Flutter:

```
lib/main.dart               จุดเริ่มแอป
lib/shop_shell.dart         แท็บหลัก (Home / Style Studio / Search / Saved)
lib/pages/category_page.dart
lib/pages/product_detail.dart   ภาพสินค้า + variant chips + ขนาด + เพิ่มของเข้าตะกร้า
lib/pages/basket_page.dart      ตะกร้า
lib/pages/profile_page.dart     โปรไฟล์ / ล็อกอิน / ประวัติสั่งซื้อ
lib/api.dart === โค้ดเรียก API
lib/models.dart === โมเดลข้อมูล
lib/widgets.dart === ปุ่มนำทาง / ภาพสินค้า
```

## API ที่ Back office ใช้

| Method | Path | ทำอะไร |
|---|---|---|
| GET | `/admin/stats` | จำนวนแถวของทุกตาราง |
| GET | `/admin/t/{products\|users\|orders\|order_items\|cart_items\|favorites}?q=คำค้น` | แสดงแถว + ค้นหา |
| POST | `/admin/t/{table}` | เพิ่มแถว (ส่งชื่อ field ในตาราง) |
| PUT | `/admin/t/{table}/{id}` | แก้ไขแถว (favorites ต้องส่ง ?uid= ด้วย) |
| DELETE | `/admin/t/{table}/{id}` | ลบแถว (favorites ต้องส่ง ?uid= ด้วย) |

และ API ของแอปร้านค้า: `/products`, `/products/{id}`, `/register`, `/login`,
`/cart (GET/POST/PUT/DELETE)`, `/favorites (GET/POST/DELETE)`, `/orders (GET/POST)`

## โครงสร้างไฟล์ของระบบ (อธิบายไฟล์ทุกไฟล์)

**Backend (Python/FastAPI):**
- `backend/main.py` — ระบบหลัก: สร้าง/seed ฐานข้อมูล, REST API ของแอปหน้าร้าน (products/users/cart/checkout/favorites) และ API ของ Back office (`/admin/*`) พร้อมบังคับ Foreign Key
- `backend/admin.html` — หน้าเว็บ Back office (แสดง/ค้นหา/เพิ่ม/แก้ไข/ลบ ทุกตาราง รวม Favorites แบบ composite key)
- `backend/export_sql.py` — สคริปต์ export ฐานข้อมูลเป็นไฟล์ SQL (SQLite + MySQL) พร้อม PK/FK ครบ
- `backend/database_export_sqlite.sql` · `backend/database_export_mysql.sql` — ไฟล์ SQL export สำหรับติดตั้งบนเครื่องอื่น
- `backend/fashion.db` — ไฟล์ฐานข้อมูล SQLite ปัจจุบัน (ถูกสร้าง/seed ใหม่เมื่อรันเซิร์ฟเวอร์หากยังไม่มี)
- `backend/requirements.txt` — แพ็กเกจที่ต้องติดตั้ง (FastAPI, uvicorn)

**แอปหน้าร้าน (Flutter):**
- `lib/main.dart` — จุดเริ่มแอป + การตั้งค่า API URL
- `lib/api.dart` — โค้ดเรียก REST API ทั้งหมดของแอป
- `lib/models.dart` · `lib/widgets.dart` · `lib/shop_shell.dart` — โมเดลข้อมูล, วิดเจ็ตและโครงหน้าจอหลัก
- `lib/pages/` — หน้าจอแยกไฟล์: `basket_page.dart`, `category_page.dart`, `product_detail.dart`, `profile_page.dart`
- `assets/products/` — รูปสินค้าทั้งหมดที่ใช้ในระบบ (ข้อมูลรวบรวมเอง + Web Scraping)

**เอกสาร/ข้อส่ง:**
- `deliverables/submission/` — รายงาน PDF (_01), Presentation PDF (_02), วิดีโอสาธิต MP4 (_03)
- `slides/er.html` + `slides/assets/er_diagram.png` — แผนผัง ER ที่ใช้ในรายงาน/สไลด์

## ไฟล์ที่ต้องส่ง 12 เอกสาร (ตอนส่งงานจริง)

- รายงานฉบับสมบูรณ์ → `69db_รหัสนักศึกษา_01.pdf`
- Presentation → `69db_รหัสนักศึกษา_02.pdf`
- วิดีโอนำเสนอ ≤ 1 นาที → `69db_รหัสนักศึกษา_03.mp4`
- GitHub repo (source code + ไฟล์ SQL export 2 ไฟล์ + README นี้)

## Troubleshooting

- สินค้าไม่แสดงในแอป → ต้องเปิด `uvicorn main:app --port 8000` ก่อนเสมอ
- Android emulator ต้องใช้ `10.0.2.2` ต่อ backend ไม่ใช่ `localhost`
- ใช้ `python3 export_sql.py` (ใน `backend/`) เพื่อ regen ไฟล์ SQL export ตอนฐานข้อมูลอัปเดต
