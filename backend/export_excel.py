"""Export ทุกตารางใน fashion.db เป็นไฟล์ Excel (.xlsx) — 1 ชีตต่อ 1 ตาราง

ใช้งาน:  python3 export_excel.py [ไฟล์ปลายทาง]
ค่าเริ่มต้น: ../deliverables/mood_wear_data.xlsx
"""
import os
import sqlite3
import sys

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "fashion.db")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(BASE, "..", "deliverables", "mood_wear_data.xlsx")

# แต่ละตาราง JOIN ชื่อผู้ใช้/ชื่อสินค้า เพื่อให้เปิด Excel แล้วอ่านรู้เรื่อง
QUERIES = {
    "products": "SELECT * FROM products",
    "users": "SELECT * FROM users",
    "orders": """SELECT o.id, o.user_id, u.username AS user_name, o.address, o.total, o.created_at
                 FROM orders o LEFT JOIN users u ON u.id = o.user_id""",
    "order_items": """SELECT oi.id, oi.order_id, u.username AS user_name, oi.product_id,
                             p.name AS product_name, oi.quantity, oi.size, oi.color, oi.unit_price
                      FROM order_items oi
                      LEFT JOIN orders o ON o.id = oi.order_id
                      LEFT JOIN users u ON u.id = o.user_id
                      LEFT JOIN products p ON p.id = oi.product_id""",
    "cart_items": """SELECT ci.id, ci.user_id, u.username AS user_name, ci.product_id,
                            p.name AS product_name, ci.quantity, ci.size, ci.color
                     FROM cart_items ci
                     LEFT JOIN users u ON u.id = ci.user_id
                     LEFT JOIN products p ON p.id = ci.product_id""",
    "favorites": """SELECT f.user_id, u.username AS user_name, f.product_id,
                           p.name AS product_name, f.created_at
                    FROM favorites f
                    LEFT JOIN users u ON u.id = f.user_id
                    LEFT JOIN products p ON p.id = f.product_id""",
}

HEAD_FILL = PatternFill("solid", fgColor="111111")
HEAD_FONT = Font(color="FFFFFF", bold=True, size=11)


def main():
    if not os.path.exists(DB):
        raise SystemExit(f"ไม่พบฐานข้อมูล: {DB}")

    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    wb = Workbook()
    summary = wb.active
    summary.title = "จำนวนแถว"
    summary_rows = []

    for name, sql in QUERIES.items():
        cur = con.execute(sql)
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
        summary_rows.append((name, len(rows)))

        ws = wb.create_sheet(name)
        ws.append(cols)
        for r in rows:
            ws.append([r[c] for c in cols])

        # จัดรูปแบบหัวตาราง
        for col_idx, _ in enumerate(cols, start=1):
            cell = ws.cell(row=1, column=col_idx)
            cell.fill = HEAD_FILL
            cell.font = HEAD_FONT
            cell.alignment = Alignment(horizontal="left", vertical="center")
        ws.freeze_panes = "A2"

        # ปรับความกว้างคอลัมน์ตามเนื้อหาที่ยาวที่สุด (จำกัดไม่เกิน 55)
        for col_idx, col in enumerate(cols, start=1):
            longest = len(str(col))
            for r in rows:
                longest = max(longest, len(str(r[col] if r[col] is not None else "")))
            ws.column_dimensions[get_column_letter(col_idx)].width = min(55, longest + 3)

        # ใส่ตัวกรองอัตโนมัติที่แถวหัวตาราง
        ws.auto_filter.ref = f"A1:{get_column_letter(len(cols))}{max(1, len(rows) + 1)}"

    # ชีตสรุปจำนวนแถว
    summary.append(["ตาราง (TABLE)", "จำนวนแถว (ROWS)"])
    for name, count in summary_rows:
        summary.append([name, count])
    summary.append(["รวม", sum(c for _, c in summary_rows)])
    for col_idx in (1, 2):
        cell = summary.cell(row=1, column=col_idx)
        cell.fill = HEAD_FILL
        cell.font = HEAD_FONT
    summary.column_dimensions["A"].width = 26
    summary.column_dimensions["B"].width = 18
    summary.freeze_panes = "A2"

    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    wb.save(OUT)
    con.close()

    print(f"บันทึกแล้ว: {os.path.abspath(OUT)}")
    for name, count in summary_rows:
        print(f"  {name:12s} {count:>4d} แถว")


if __name__ == "__main__":
    main()
