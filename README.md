# Mood Wear — Digital Database Final Project (802244)

ระบบฐานข้อมูลร้านค้าเสื้อผ้าแฟชั่น **Mood Wear** ประกอบด้วย
**แอปพลิเคชันร้านค้า (Flutter — Mobile/Web)** + **Back Office เว็บ (FastAPI + SQLite)** + **แดชบอร์ดสรุปยอดขาย**
โดยทุกส่วนอ่าน/เขียนฐานข้อมูลชุดเดียวกันผ่าน REST API

- Back Office + แดชบอร์ด: `http://127.0.0.1:8000/admin`
- API docs (Swagger): `http://127.0.0.1:8000/docs`
- วิชา 802244 DIGITAL DATABASE · ภาคการศึกษา 2569
- ผู้จัดทำ: นางสาว ลภัสรดา หาญกุล 681310676 · นายวรเศรษฐ์ บุญสวัสดิ์ 681310306

---

## 1. ภาพรวมระบบ

| ส่วน | เทคโนโลยี | หน้าที่ |
|---|---|---|
| ฐานข้อมูล | SQLite 3 (`backend/fashion.db`) | เก็บข้อมูล 6 ตาราง + VIEW 4 ตัว |
| Backend API | Python + FastAPI + uvicorn | REST API ของแอปหน้าร้าน และ API ของ Back Office |
| Back Office | HTML/CSS/JS (`backend/admin.html`) | แสดง / ค้นหา / เพิ่ม / แก้ไข / ลบ ทุกตาราง + แดชบอร์ดสรุปยอดขาย |
| แอปหน้าร้าน | Flutter (Dart) | ดูสินค้า/ตัวเลือกสินค้า, ตะกร้า, รายการถูกใจ, สั่งซื้อ |
| ไฟล์ข้อมูล | SQL Export + Excel | นำไปใช้บนเครื่องอื่น / ตรวจข้อมูล |

## 2. เกณฑ์โครงงานที่ระบบทำได้

| เกณฑ์ | สถานะ |
|---|---|
| Entity ≥ 5 | **6 ตาราง**: `products`, `users`, `orders`, `order_items`, `cart_items`, `favorites` |
| ความสัมพันธ์ ≥ 3 | **6 ความสัมพันธ์**: `users→orders`, `orders→order_items`, `products→order_items`, `users→cart_items`, `products→cart_items` (1:M) และ `users↔products` ผ่าน `favorites` (M:N) |
| ทุกตาราง ≥ 50 แถว | products 66 · users 51 · orders 58 · **order_items 112** · cart_items 52 · favorites 52 (รวม **391 แถว**) |
| Primary Key / Foreign Key | ครบทุกตาราง + เปิด `PRAGMA foreign_keys=ON` บังคับใช้จริง |
| Data Dictionary / ER Diagram | อยู่ในรายงาน (`deliverables/db_report.html`) |
| Normalization | ผ่าน 1NF / 2NF / 3NF |
| Back Office CRUD | แสดง / เพิ่ม / แก้ไข / ลบ ได้ทุกตาราง (favorites ใช้ composite key) |
| แหล่งข้อมูล | ข้อมูลสินค้าและรูปภาพรวบรวมเอง + Web Scraping จากหน้าร้านแบรนด์จริง |
| SQL Export | `backend/database_export_sqlite.sql`, `backend/database_export_mysql.sql` (มี VIEW ต่อท้าย) |
| แดชบอร์ด | สรุปยอดขาย/สินค้าขายดี/ผู้ซื้อสูงสุด/ยอดตามหมวดหมู่ คำนวณสดจากฐานข้อมูล |

## 3. ความสัมพันธ์ของข้อมูล

```
users 1 ──< orders 1 ──< order_items >── 1 products
users 1 ──< cart_items >── 1 products
users M ──< favorites >── N products      (ตารางเชื่อม composite PK)
```

สินค้าแต่ละกลุ่มมี **variant** (`vgroup` + `vname` + `vorder`) เช่น Adidas Samba แต่ละสี
ทำให้หน้าสินค้าสลับชื่อ/ราคาตามตัวเลือกได้

## 4. โครงสร้างโปรเจกต์

```
.
├── backend/                     # เซิร์ฟเวอร์ + ฐานข้อมูล + หน้า Back Office
│   ├── main.py                  # FastAPI: seed DB, REST API, /admin/* CRUD, /admin/summary
│   ├── admin.html               # หน้า Back Office + แดชบอร์ด (แสดงชื่อผู้ใช้/สินค้า + รูปสินค้า)
│   ├── export_sql.py            # export ฐานข้อมูลเป็นไฟล์ SQL (SQLite + MySQL)
│   ├── export_excel.py          # export ทุกตารางเป็น Excel (มีคอลัมน์ชื่อผู้ใช้/สินค้า)
│   ├── database_export_sqlite.sql  # ไฟล์นำเข้าฐานข้อมูล (SQLite) + VIEW 4 ตัว
│   ├── database_export_mysql.sql   # ไฟล์นำเข้าฐานข้อมูล (MySQL/phpMyAdmin) + VIEW 4 ตัว
│   ├── demo_queries.sql         # คิวรีสาธิตสำหรับการนำเสนอ/วิดีโอ
│   └── requirements.txt         # แพ็กเกจ Python ที่ต้องติดตั้ง
├── lib/                         # แอปพลิเคชันร้านค้า (Flutter)
│   ├── main.dart · api.dart · models.dart · widgets.dart · shop_shell.dart
│   └── pages/                   # หน้าจอ: home/category, product detail, basket, profile, search, saved
├── assets/products/             # รูปสินค้าทั้งหมด (ใช้ทั้งแอปและ Back Office)
├── deliverables/                # เอกสาร รายงาน สไลด์ และไฟล์ข้อมูล
│   ├── db_report.html           # รายงาน (ต้นฉบับ) → PDF ใน submission/
│   ├── db_slides.html           # สไลด์ (ต้นฉบับ) → PDF ใน submission/
│   ├── mood_wear_data.xlsx      # ข้อมูลทุกตาราง (Excel)
│   ├── er_diagram.dbml · img/   # แหล่ง ER Diagram และรูปประกอบ
│   └── submission/              # ไฟล์ส่งอาจารย์ (PDF/MP4)
└── README.md
```

## 5. เครื่องมือและซอฟต์แวร์ที่ต้องติดตั้ง

| ซอฟต์แวร์ | เวอร์ชันที่แนะนำ | ใช้ทำอะไร |
|---|---|---|
| Python | 3.11 ขึ้นไป | รัน FastAPI backend |
| pip package | `fastapi>=0.115,<1`, `uvicorn[standard]>=0.30,<1` | เว็บเซิร์ฟเวอร์/API |
| SQLite | 3 (มากับ Python) | ฐานข้อมูลหลัก |
| Flutter SDK + Dart | Flutter 3.x / Dart 3.x | แอปพลิเคชันร้านค้า (ไม่บังคับถ้าดูเฉพาะ Back Office) |
| openpyxl | ล่าสุด (เฉพาะตอน export Excel) | สร้างไฟล์ `mood_wear_data.xlsx` |
| MySQL 8 / phpMyAdmin | ไม่บังคับ | ใช้นำเข้าไฟล์ `database_export_mysql.sql` |
| Google Chrome | ล่าสุด | รันแอปเวอร์ชันเว็บ / พิมพ์เอกสาร PDF |

## 6. ขั้นตอนการติดตั้งระบบ

### 6.1 Backend + ฐานข้อมูล (สร้างฐานข้อมูลอัตโนมัติ)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate            # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

- ครั้งแรกที่รัน ระบบจะสร้าง `backend/fashion.db` และ seed ข้อมูลครบทุกตาราง (≥ 50 แถว/ตาราง)
- เปิด Back Office: **http://127.0.0.1:8000/admin**
- เปิด Swagger: **http://127.0.0.1:8000/docs**

### 6.2 ทางเลือก: นำเข้าฐานข้อมูลจากไฟล์ SQL (ใช้ข้อมูลชุดเดิมบนเครื่องอื่น)

**SQLite**

```bash
sqlite3 backend/fashion.db < backend/database_export_sqlite.sql
```

ไฟล์นี้สร้างตารางทั้ง 6 + ข้อมูล + **VIEW 4 ตัว** (`v_orders`, `v_order_items`, `v_cart_items`, `v_favorites`)
เปิดดูแบบเห็นชื่อได้ทันที เช่น `SELECT * FROM v_order_items LIMIT 5;`

**MySQL / phpMyAdmin**

```sql
SOURCE backend/database_export_mysql.sql;   -- ใน mysql client
-- หรือ import ผ่าน phpMyAdmin (ไฟล์สร้างฐานข้อมูล moodwear ให้เอง)
```

> หมายเหตุ: ระบบรันด้วย SQLite เป็นหลัก หากใช้ MySQL ต้องปรับ `backend/main.py` ส่วนเชื่อมต่อฐานข้อมูล
> และแก้ไวยากรณ์การสร้าง VIEW ให้ตรงกับ MySQL (ไฟล์ MySQL ใช้ `CREATE OR REPLACE VIEW` ให้แล้ว)

### 6.3 ไฟล์ข้อมูล Excel (สำหรับตรวจข้อมูล)

```bash
python3 backend/export_excel.py deliverables/mood_wear_data.xlsx
```

### 6.4 แอปพลิเคชันร้านค้า (Flutter)

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000      # เว็บ
flutter run --dart-define=API_URL=http://10.0.2.2:8000                 # Android emulator
flutter run --dart-define=API_URL=http://127.0.0.1:8000                # iOS simulator
```

## 7. การเชื่อมต่อระบบ

| จุดเชื่อมต่อ | ค่า |
|---|---|
| Backend API | `http://127.0.0.1:8000` |
| Back Office + แดชบอร์ด | `http://127.0.0.1:8000/admin` |
| รูปสินค้า (static) | `http://127.0.0.1:8000/assets/products/...` |
| แอป → API (เว็บ/iOS) | `--dart-define=API_URL=http://127.0.0.1:8000` |
| แอป → API (Android emulator) | `--dart-define=API_URL=http://10.0.2.2:8000` |
| CORS | เปิด `allow_origins=['*']` สำหรับการสาธิตในเครื่อง |

## 8. ตารางและ VIEW ในฐานข้อมูล

**ตารางจริง (เก็บรหัสอ้างอิงตามหลัก normalization)**

| ตาราง | Primary Key | Foreign Key |
|---|---|---|
| `users` | id | — |
| `products` | id | — |
| `orders` | id | user_id → users.id |
| `order_items` | id | order_id → orders.id, product_id → products.id |
| `cart_items` | id | user_id, product_id (+ UNIQUE user/product/size/color) |
| `favorites` | (user_id, product_id) | user_id, product_id |

**VIEW สำหรับอ่านข้อมูลให้เห็นชื่อ (ไม่เก็บชื่อซ้ำในตาราง)**

| View | ใช้ดู |
|---|---|
| `v_orders` | ออเดอร์ + ชื่อผู้ใช้ |
| `v_order_items` | รายการในออเดอร์ + ชื่อผู้ใช้ + ชื่อสินค้า |
| `v_cart_items` | ตะกร้า + ชื่อผู้ใช้ + ชื่อสินค้า |
| `v_favorites` | รายการถูกใจ + ชื่อผู้ใช้ + ชื่อสินค้า |

## 9. API ที่ใช้

| Method | Path | หน้าที่ |
|---|---|---|
| GET | `/products`, `/products/{id}` | รายการ/รายละเอียดสินค้า |
| POST | `/register`, `/login` | สมัคร/เข้าสู่ระบบ (รหัสผ่านเก็บเป็น SHA-256 hash) |
| GET/POST/PUT/DELETE | `/cart`, `/cart/{id}` | ตะกร้าสินค้า |
| GET/POST/DELETE | `/favorites` | รายการถูกใจ |
| POST/GET | `/orders`, `/orders?user_id=` | สร้าง/ดูประวัติคำสั่งซื้อ |
| GET | `/admin/t/{table}?q=` | แสดง + ค้นหาข้อมูล (JOIN ชื่อผู้ใช้/สินค้า) |
| POST/PUT/DELETE | `/admin/t/{table}[/{id}]` | เพิ่ม / แก้ไข / ลบ (favorites ส่ง `?uid=` ด้วย) |
| GET | `/admin/stats` | จำนวนแถวทุกตาราง |
| GET | `/admin/summary` | ข้อมูลแดชบอร์ด (ยอดขาย, สินค้าขายดี, ผู้ซื้อสูงสุด, ยอดรายวัน/หมวดหมู่) |

## 10. เอกสารและไฟล์ส่งงาน

| ไฟล์ | รายละเอียด |
|---|---|
| `deliverables/submission/69db_report_681310676_681310306.pdf` | รายงานฉบับสมบูรณ์ (14 หน้า) |
| `deliverables/submission/69db_present_681310676_681310306.pdf` | สไลด์นำเสนอ (11 แผ่น) |
| `deliverables/submission/69db_676_306_03.mp4` | วิดีโอสาธิตการใช้งาน |
| `deliverables/mood_wear_data.xlsx` | ข้อมูลทุกตาราง (Excel) |
| `backend/database_export_*.sql` | ไฟล์ SQL สำหรับนำเข้าฐานข้อมูล |

## 11. ความปลอดภัยของข้อมูล

- ไม่มีไฟล์ `.env`, API key, รหัสผ่าน หรือ token ใด ๆ อยู่ใน Repository
- รหัสผ่านของผู้ใช้ถูกเก็บเป็น **SHA-256 hash** ไม่ได้เก็บ plain text
- ไฟล์ฐานข้อมูลที่เกิดตอนรัน (`backend/fashion.db`) และ log ถูก ignore ผ่าน `.gitignore`
  (ใช้ไฟล์ SQL export เป็นแหล่งข้อมูลตั้งต้นแทน)
- ข้อมูลผู้ใช้ทั้งหมดเป็นข้อมูลจำลองเพื่อการสาธิต ไม่มีข้อมูลบุคคลจริง

## 12. แก้ปัญหาที่พบบ่อย

| อาการ | วิธีแก้ |
|---|---|
| เปิดแอปแล้วสินค้าไม่ขึ้น | ยังไม่ได้รัน backend — เริ่ม `uvicorn main:app --port 8000` ก่อน |
| Android emulator ต่อ API ไม่ได้ | ใช้ `10.0.2.2` แทน `127.0.0.1` |
| รูปสินค้าไม่แสดงใน Back Office | ต้องรันผ่าน backend (path `/assets/products/...`) ไม่ใช่เปิดไฟล์ HTML ตรง ๆ |
| ข้อมูลไม่ตรงหลังแก้ตาราง | กดปุ่ม **รีเฟรช** หรือรัน `python3 backend/export_sql.py` เพื่อ export ไฟล์ SQL ใหม่ |
| อยากดูข้อมูลแบบมีชื่อผู้ใช้/สินค้า | ใช้ VIEW เช่น `SELECT * FROM v_order_items LIMIT 10;` |
