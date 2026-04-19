import os
from firebase_functions import firestore_fn
from firebase_admin import initialize_app, firestore
import google.generativeai as genai
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector
from database_tools import get_houses_list, get_rooms_status, get_unpaid_invoices

# Admin sdk init inside the execution body to prevent deploy timeout

@firestore_fn.on_document_created(document="chatRooms/{roomId}/messages/{messageId}")
def reply_chatbot_message(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    try:
        initialize_app()
    except ValueError:
        pass
    db = firestore.client()

    # 1. Lấy thông tin snapshot
    new_message = event.data
    if not new_message.exists:
        return
    
    msg_data = new_message.to_dict()
    sender_id = msg_data.get("senderId", "")
    text = msg_data.get("text", "")
    
    # Bỏ qua nếu tin nhắn là do bot gửi hoặc tin trống
    if sender_id == "bot" or not text:
        return

    room_id = event.params["roomId"]

    # 2. Kiểm tra xem phòng này có phải 'lozido cskh' không
    room_ref = db.collection("chatRooms").document(room_id).get()
    if not room_ref.exists:
        return
    
    room_data = room_ref.to_dict()
    room_name = room_data.get("roomName", "").lower()
    if room_name != "lozido cskh":
        return

    # 3. Lấy API Key từ Firestore
    try:
        config_ref = db.collection("config").document("gemini").get()
        if not config_ref.exists:
            print("❌ Lỗi: Không tìm thấy document 'config/gemini'")
            return
        
        api_key = config_ref.to_dict().get("api_key")
        if not api_key:
            return
            
        genai.configure(api_key=api_key)
    except Exception as e:
        print(f"❌ Lỗi khi lấy API Key: {str(e)}")
        return

    # 4. Tìm kiếm nội dung liên quan trong knowledge_base (Vector Search)
    context_chunks = []
    try:
        # Nhúng câu hỏi của người dùng
        query_embedding_response = genai.embed_content(
            model="models/gemini-embedding-2-preview",
            content=text,
            task_type="retrieval_query",
            output_dimensionality=768
        )
        query_vector = query_embedding_response['embedding']

        # Truy vấn tất cả file trong knowledge base (Ở đây query giới hạn 1 file hoặc tìm trong group)
        # Vì collection group chunks mới hỗ trợ vector query
        docs = db.collection_group("chunks") \
                 .find_nearest(
                     vector_field="embedding",
                     query_vector=Vector(query_vector),
                     distance_measure=DistanceMeasure.COSINE,
                     limit=3
                 ).stream()
                 
        for doc in docs:
            chunk_data = doc.to_dict()
            if "content" in chunk_data:
                context_chunks.append(chunk_data["content"])

    except Exception as e:
        print(f"⚠️ Không thể thực hiện RAG hoặc không có context: {str(e)}")

    # 5. Phân quyền: Kiểm tra người gửi là Chủ Nhà (Landlord) hay Người Thuê (Tenant)
    is_landlord = False
    try:
        user_doc = db.collection("users").document(sender_id).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            if user_data.get("role") == "Landlord":
                is_landlord = True
    except Exception as e:
        print(f"Lỗi kiểm tra quyền: {e}")

    # 6. Khởi tạo Gemini Model và tạo câu trả lời
    prompt = "Bạn là một Chatbot hỗ trợ chăm sóc khách hàng (CSKH). Tên của bạn là Chat Bot Nhà Trọ.\n\n"
    
    if is_landlord:
        prompt += "[QUYỀN CHỦ NHÀ]: Bạn đang nói chuyện với CHỦ TRỌ. Bạn CÓ QUYỀN sử dụng các công cụ tìm kiếm dữ liệu (house, room, invoice) để trả lời họ.\n\n"
    else:
        prompt += "[QUYỀN NGƯỜI THUÊ]: Bạn đang nói chuyện với NGƯỜI THUÊ PHÒNG. BẠN TUYỆT ĐỐI KHÔNG ĐƯỢC TIẾT LỘ dữ liệu quản lý. Chỉ trả lời dựa vào các quy định và thông tin chung sau đây:\n\n"

    if context_chunks:
        prompt += "Hãy dựa vào các thông tin sau để trả lời:\n"
        prompt += "\n---\n".join(context_chunks)
        prompt += "\n---\n\n"

    prompt += f"Câu hỏi của khách hàng: {text}\n"
    prompt += "Hãy trả lời một cách tự nhiên, lịch sự, ngắn gọn và hữu ích nhé."

    try:
        # Nhóm công cụ truy vấn (Chỉ cấp cho Landlord)
        active_tools = [get_houses_list, get_rooms_status, get_unpaid_invoices] if is_landlord else None

        model = genai.GenerativeModel(
            model_name='gemini-flash-lite-latest',
            tools=active_tools
        )
        chat = model.start_chat(enable_automatic_function_calling=True)
        response = chat.send_message(prompt)
        bot_reply = response.text

        # 6. Gửi tin nhắn trả lời ngược lại Firebase
        db.collection("chatRooms").document(room_id).collection("messages").add({
            "senderId": "bot",
            "senderName": "Lozido CSKH",
            "text": bot_reply,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "isSticker": False
        })
        print(f"✅ Đã trả lời trong phòng {room_name}")

    except Exception as e:
        print(f"❌ Lỗi sinh phản hồi từ Gemini: {str(e)}")
