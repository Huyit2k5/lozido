from firebase_admin import firestore

def _get_house_name(db, house_id: str) -> str:
    """Hàm bổ trợ để lấy tên nhà trọ từ propertyName."""
    house_doc = db.collection('houses').document(house_id).get()
    if house_doc.exists:
        data = house_doc.to_dict()
        return data.get('propertyName', house_id)
    return house_id


def get_houses_list() -> str:
    """Hàm này lấy danh sách tên và ID của tất cả các nhà trọ (houses) đang quản lý."""
    db = firestore.client()
    houses_ref = db.collection('houses').get()
    if not houses_ref:
        return "Không có nhà trọ nào được quản lý."
    
    result = "Danh sách nhà trọ (Gồm Tên và ID):\n"
    for h in houses_ref:
        data = h.to_dict()
        house_name = data.get('propertyName', data.get('houseName', data.get('name', 'Không tên')))
        result += f"- {house_name} (ID: {h.id})\n"

        
    return result

def get_rooms_status(house_id: str) -> str:
    """Hàm này lấy trạng thái của tất cả các phòng trong một nhà trọ cụ thể dựa trên house_id."""
    db = firestore.client()
    house_name = _get_house_name(db, house_id)
    rooms_ref = db.collection('houses').document(house_id).collection('rooms').get()
    if not rooms_ref:
        return f"Không tìm thấy phòng nào trong nhà: {house_name}."
        
    result = f"Thống kê các phòng trong nhà {house_name}:\n"

    for r in rooms_ref:
        data = r.to_dict()
        room_name = data.get('roomName', 'Phòng không tên')
        status = data.get('status', 'Trống')
        tenant_name = data.get('tenantName', 'Không có người thuê')
        if status == 'Trống':
            tenant_name = 'Không có'
        price = data.get('rentPrice', data.get('price', 0))
        
        result += f"- Phòng {room_name}: Trạng thái '{status}', Giá thuê {price:,.0f}đ, Người thuê: {tenant_name}\n"
        
    return result

def get_unpaid_invoices(house_id: str) -> str:
    """Hàm này lấy danh sách các hóa đơn tiền phòng/điện nước chưa được thanh toán đủ trong một nhà trọ cụ thể dựa trên house_id."""
    db = firestore.client()
    house_name = _get_house_name(db, house_id)
    invoices_ref = db.collection('houses').document(house_id).collection('invoices').get()
    
    if not invoices_ref:
        return f"Không có hóa đơn nào trong nhà {house_name}."
        
    result = f"Danh sách hóa đơn chưa thu hoặc thu thiếu trong nhà {house_name}:\n"
    count = 0
    for i in invoices_ref:
        data = i.to_dict()
        status = data.get('status', '')
        if status in ['Chưa thu', 'Thu một phần']:
            count += 1
            room_name = data.get('roomName', 'Không rõ')
            month = data.get('billingMonth', 'Không rõ')
            total = data.get('grandTotal', 0)
            paid = data.get('paidAmount', 0)
            try:
                debt = float(total) - float(paid)
            except:
                debt = 0
            if debt > 0:
                result += f"- Phòng {room_name} (Tháng {month}): Trạng thái '{status}', Cần thu thêm {debt:,.0f}đ (Tổng: {total:,.0f}đ)\n"
            
    if count == 0:
        return "Tất cả hóa đơn trong nhà này đều đã được thu đủ."
        
    return result
