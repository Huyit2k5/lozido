import os
import tempfile
from firebase_functions import storage_fn
from firebase_admin import initialize_app, firestore, storage
import google.generativeai as genai
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from google.cloud.firestore_v1.vector import Vector

# Firebase Admin sẽ được khởi tạo bên trong function để tránh làm chậm / timeout lúc Firebase quét (deploy)

@storage_fn.on_object_finalized()
def process_pdf_and_embed(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    # Lazy init Firebase
    try:
        initialize_app()
    except ValueError:
        pass
    db = firestore.client()

    bucket_name = event.data.bucket
    file_path = event.data.name 
    
    if not file_path.endswith(".pdf"):
        return

    # --- BƯỚC MỚI: LẤY API KEY TỪ FIRESTORE ---
    try:
        # Truy cập collection 'config', document 'gemini'
        config_ref = db.collection("config").document("gemini").get()
        if not config_ref.exists:
            print("❌ Lỗi: Không tìm thấy document 'config/gemini' trên Firestore")
            return
        
        # Lấy giá trị từ field 'api_key'
        gemini_data = config_ref.to_dict()
        api_key = gemini_data.get("api_key")
        
        if not api_key:
            print("❌ Lỗi: Field 'api_key' bị trống")
            return

        # Cấu hình Gemini với Key vừa lấy được
        genai.configure(api_key=api_key)
    except Exception as e:
        print(f"❌ Lỗi khi lấy API Key: {str(e)}")
        return
    # ------------------------------------------

    # Phần code xử lý PDF giữ nguyên như cũ
    file_name = os.path.basename(file_path)
    _, temp_local_path = tempfile.mkstemp(suffix=".pdf")

    try:
        bucket = storage.bucket(bucket_name)
        blob = bucket.blob(file_path)
        blob.download_to_filename(temp_local_path)

        loader = PyPDFLoader(temp_local_path)
        docs = loader.load()
        
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
        chunks = text_splitter.split_documents(docs)

        # Tạo bản ghi cha trong knowledge_base
        file_ref = db.collection("knowledge_base").document()
        file_ref.set({
            "file_name": file_name,
            "storage_path": file_path,
            "created_at": firestore.SERVER_TIMESTAMP,
            "total_chunks": len(chunks)
        })

        for i, chunk in enumerate(chunks):
            # Tạo Embedding
            result = genai.embed_content(
                model="models/gemini-embedding-2-preview",
                content=chunk.page_content,
                task_type="retrieval_document",
                output_dimensionality=768
            )
            
            # Lưu vào sub-collection 'chunks'
            file_ref.collection("chunks").add({
                "content": chunk.page_content,
                "embedding": Vector(result['embedding']),
                "page": chunk.metadata.get("page", 0),
                "index": i
            })

        print(f"✅ Đã bóc tách và tạo vector cho: {file_name}")

    except Exception as e:
        print(f"❌ Lỗi xử lý file: {str(e)}")
    finally:
        if os.path.exists(temp_local_path):
            os.remove(temp_local_path)