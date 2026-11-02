-- ══ คิวรีสาธิตสำหรับคลิปวิดีโอ (ก๊อปแต่ละบล็อกไปรันในแท็บ Execute SQL) ══

-- ▶ 1) พิสูจน์ว่าทุกตารางมี ≥ 50 แถว
SELECT 'products' AS ตาราง, COUNT(*) AS จำนวนแถว FROM products
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'cart_items', COUNT(*) FROM cart_items
UNION ALL SELECT 'favorites', COUNT(*) FROM favorites;

-- ▶ 2) โชว์ PK และ FK ของแต่ละตาราง (โครงสร้าง)
-- เปลี่ยนชื่อตารางใน WHERE ได้: products / users / orders / order_items / cart_items / favorites
SELECT sql FROM sqlite_master WHERE name = 'orders';

-- ▶ 3) ความสัมพันธ์ 1:M — ผู้ใช้ 1 คนมีหลายคำสั่งซื้อ
SELECT users.id AS user_id, users.username, COUNT(orders.id) AS จำนวนคำสั่งซื้อ
FROM users JOIN orders ON orders.user_id = users.id
GROUP BY users.id ORDER BY จำนวนคำสั่งซื้อ DESC LIMIT 5;

-- ▶ 4) M:N ผ่านตารางกลาง order_items — สินค้าถูกสั่งกี่ครั้ง
SELECT products.name, products.price, SUM(order_items.quantity) AS ยอดสินค้าที่ขาย
FROM order_items JOIN products ON products.id = order_items.product_id
GROUP BY products.id ORDER BY ยอดสินค้าที่ขาย DESC LIMIT 5;
