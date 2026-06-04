# Lozido App - Cấu trúc dự án (MVVM Architecture)

Dự án này được xây dựng dựa trên kiến trúc **MVVM (Model - View - ViewModel)** kết hợp với **Provider** để quản lý trạng thái, đảm bảo mã nguồn dễ bảo trì, dễ mở rộng và tách bạch rõ ràng giữa giao diện, logic nghiệp vụ và dữ liệu.

## 📂 Cấu trúc thư mục

```text
lib/
├── core/                  # Các thành phần cốt lõi dùng chung
│   ├── constants/         # Các hằng số (colors, strings, api endpoints)
│   └── error/             # Xử lý lỗi (failures, exceptions)
├── data/                  # Tầng dữ liệu (Data Layer)
│   ├── models/            # Cấu trúc dữ liệu (Models) có hàm fromJson, toJson
│   └── repositories/      # Chứa logic tương tác với Firebase (Firestore, Auth, Storage)
├── presentation/          # Tầng giao diện (View Layer)
│   ├── pages/             # Các trang (Màn hình), được chia theo từng module tính năng
│   └── widgets/           # Các UI component có thể dùng chung (Dialog, Button, TextField)
├── utils/                 # Các hàm tiện ích (format tiền, ngày tháng, helpers)
└── viewmodels/            # Tầng logic nghiệp vụ (ViewModel Layer - ChangeNotifier)
```

## 🏗️ Luồng hoạt động (Data Flow)

Ứng dụng tuân theo luồng luân chuyển dữ liệu một chiều (Unidirectional Data Flow):

1. **View (Presentation)**: Các trang UI (`pages/`) không chứa logic kết nối database. Giao diện sử dụng `context.watch<T>()` hoặc `Consumer<T>` từ thư viện **Provider** để lắng nghe sự thay đổi trạng thái từ `ViewModel` và tự động cập nhật UI. Người dùng tương tác (nhấn nút, nhập form) sẽ gọi các hàm của `ViewModel` thông qua `context.read<T>()`.
2. **ViewModel (ViewModels)**: Kế thừa `ChangeNotifier`. Chứa toàn bộ logic nghiệp vụ (business logic) và trạng thái hiển thị (`isLoading`, `tasks`, `houses`,...). `ViewModel` gọi các hàm từ `Repository` để lấy hoặc lưu dữ liệu, sau đó gọi `notifyListeners()` để báo cho `View` cập nhật.
3. **Repository (Data/Repositories)**: Nơi duy nhất gọi trực tiếp tới Firebase (Firestore, Authentication, Storage). Trả về các đối tượng `Model` cho `ViewModel`.
4. **Model (Data/Models)**: Các lớp định nghĩa cấu trúc dữ liệu thuần túy như `TaskModel`, `HouseModel`, `InvoiceModel`.

> **Ưu điểm của cấu trúc này:** UI chỉ biết về `ViewModel`, `ViewModel` chỉ biết về `Repository`. Nhờ đó, nếu sau này cần đổi database từ Firebase sang API REST, bạn chỉ cần sửa ở `Repository` mà không cần chạm vào `ViewModel` hay `View`.

## 📏 Nguyên tắc đặt tên (Naming Conventions)

Để code đồng bộ, chúng ta thống nhất:
- **Thư mục & File**: Sử dụng `snake_case` (ví dụ: `room_detail_page.dart`, `task_viewmodel.dart`).
- **Class (Lớp)**: Sử dụng `PascalCase` (ví dụ: `class TaskViewModel`, `class AuthRepository`).
- **Biến & Hàm**: Sử dụng `camelCase` (ví dụ: `final String roomName;`, `void calculateTotalBill()`).
- **Hằng số**: Sử dụng `camelCase` hoặc `UPPER_CASE` tùy theo thói quen (ưu tiên `camelCase` cho AppColors).

## 🌿 Quy trình làm việc trên GitHub (Git Flow)

Chúng ta không bao giờ code trực tiếp trên nhánh `main`. Quy trình như sau:

1. **Quy tắc đặt tên nhánh (Branching)**
   - `main`: Nhánh chính, chứa code ổn định nhất (chỉ dùng để demo/nộp bài).
   - `develop`: Nhánh tập hợp code của mọi người để kiểm tra.
   - `feature/tên-tính-năng`: Nhánh làm tính năng mới (ví dụ: `feature/login`, `feature/add-room`).
   - `bugfix/tên-lỗi`: Nhánh để sửa lỗi.

2. **Các bước đẩy code**
   - Tạo nhánh mới từ develop: `git checkout -b feature/manage-room`
   - Làm việc và commit: `git commit -m "feat: thêm giao diện danh sách phòng"`
   - Đẩy lên GitHub: `git push origin feature/manage-room`
   - Tạo Pull Request (PR) trên GitHub để nhóm trưởng review và merge vào `develop`
