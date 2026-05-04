# 📋 Kế Hoạch: Module Khoản Thu Chi

> **File mới:** `lib/presentation/pages/finance/transaction_list_page.dart`
> **File mới:** `lib/presentation/pages/finance/add_transaction_page.dart`
> **File sửa:** `lib/presentation/pages/home/home_page.dart`
> **Ngày:** 03/05/2026

---

## 1. Màn hình Khoản Thu Chi

### Collection mới trên Firestore
```
houses/{houseId}/transactions/{transactionId}
```

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `type` | String | `'Thu'` hoặc `'Chi'` |
| `category` | String | Danh mục (xem bên dưới) |
| `amount` | Number | Số tiền |
| `date` | Timestamp | Ngày giao dịch |
| `note` | String | Ghi chú |
| `createdAt` | Timestamp | Ngày tạo |

### Danh mục (Categories)

**Thu (Income):**
- Tiền phòng
- Tiền điện
- Tiền nước
- Tiền rác
- Tiền wifi
- Tiền dịch vụ khác
- ~~Thu tiền giường~~ → ❌ Bỏ

**Chi (Expense):**
- Chi phí sửa chữa
- Chi phí vệ sinh
- Chi phí khác

### Layout giao diện (theo ảnh)

```
┌─────────────────────────────────────┐
│ ← Khoản thu chi          [+] Thêm   │ AppBar
├─────────────────────────────────────┤
│ 📅 Tháng 04/2026         [▼]        │ Filter thời gian
│ Loại: [Tất cả ▼]   Danh mục: [▼]   │ Filter loại & danh mục
├─────────────────────────────────────┤
│ 📄 Tiền phòng                       │
│   Phòng 101 - Tháng 04/2026         │
│   03/04/2026            +3.000.000₫ │
├─────────────────────────────────────┤
│ 📄 Tiền điện                        │
│   Phòng 101 - Chỉ số: 120-150       │
│   03/04/2026              -350.000₫ │
├─────────────────────────────────────┤
│ ...                                 │
│                                     │
│ Tổng thu:  xx ₫   Tổng chi: xx ₫   │ Footer
└─────────────────────────────────────┘
```

### Tính năng chính
1. **Lọc thu/chi**: Dropdown 3 giá trị: `Tất cả`, `Thu`, `Chi`
2. **Lọc thời gian**: Modal chọn tháng/năm
3. **Lọc danh mục**: Dropdown danh mục (phụ thuộc vào loại)
4. **Thêm giao dịch**: FloatingActionButton → AddTransactionPage
5. **Tổng thu/tổng chi**: Footer cố định

---

## 2. Màn hình Tổng kết dịch vụ (placeholder)

- Chỉ tạo file, để hardcode, không load DB
- Giao diện đơn giản: title + message "Đang phát triển"

---

## 3. Thao tác khác (home_page.dart)

Thêm section mới sau "Menu quản lý nhà trọ":
```
Section: Thao tác khác
  Grid: [Khoản thu chi] [Tổng kết dịch vụ]
```
