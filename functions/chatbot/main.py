from firebase_functions import https_fn, options

# Cài đặt region mặc định (asia-southeast1) và tăng RAM lên 1GB (quan trọng cho AI & GenAI)
options.set_global_options(
    region="asia-southeast1", 
    memory=options.MemoryOption.GB_1,
    timeout_sec=300
)
# Khai báo các function từ các module đã định nghĩa
from rag import process_pdf_and_embed
from chatbot_reply import reply_chatbot_message
