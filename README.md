📂 Cấu trúc thư mục (Clean Architecture)
Dự án tuân thủ cấu trúc Clean Architecture để đảm bảo code dễ bảo trì, dễ kiểm thử và làm việc nhóm hiệu quả.

1. lib/core/ - Nền tảng dùng chung
Chứa các thành phần không thuộc về một tính năng cụ thể nào mà được dùng cho toàn bộ ứng dụng.

constants/: Chứa màu sắc (app_colors.dart), chuỗi văn bản (app_strings.dart), cấu hình API (api_endpoints.dart).

utils/: Các hàm tiện ích như format tiền tệ (currency_formatter.dart), định dạng ngày tháng, validate form.

widgets/: Các UI component dùng lại nhiều nơi như CustomButton, LoadingDialog, AppTextField.

error/: Định nghĩa các lớp xử lý lỗi và ngoại lệ (Failures, Exceptions).

2. lib/domain/ - Tầng nghiệp vụ (Entities & Repositories Interface)
Là "trái tim" của ứng dụng, không phụ thuộc vào bất kỳ thư viện ngoài hay framework nào.

entities/: Định nghĩa các đối tượng dữ liệu thuần túy như Room, Tenant, Bill, Contract.

repositories/: Chứa các lớp trừu tượng (Abstract classes) định nghĩa các hàm cần thực hiện (ví dụ: getRooms()).

3. lib/data/ - Tầng dữ liệu (Implementation)
Nơi triển khai thực tế việc lấy dữ liệu từ đâu (API, Firebase hay Database cục bộ).

models/: Kế thừa từ entities, chứa các phương thức fromJson và toJson.

datasources/: Chứa code gọi API (remote_datasource.dart) hoặc SQLite (local_datasource.dart).

repositories/: Triển khai (Implement) các Repository interface đã định nghĩa ở tầng Domain.

4. lib/presentation/ - Tầng giao diện (UI & State Management)
Nơi chứa mọi thứ mà người dùng nhìn thấy và tương tác.

pages/: Chia theo module tính năng (ví dụ: auth/, home/, room_management/, billing/).

widgets/: Các widget chỉ dùng riêng cho một module cụ thể.

state_management/ (hoặc bloc/provider): Quản lý logic xử lý giao diện cho từng màn hình.

📏 Nguyên tắc đặt tên (Naming Conventions)
Để code đồng bộ, chúng ta thống nhất:

Thư mục & File: Sử dụng snake_case (ví dụ: room_detail_page.dart, app_colors.dart).

Class (Lớp): Sử dụng PascalCase (ví dụ: class RoomRepositoryImpl).

Biến & Hàm: Sử dụng camelCase (ví dụ: final String roomName;, void calculateTotalBill()).

Hằng số: Sử dụng camelCase hoặc UPPER_CASE tùy theo thói quen (ưu tiên camelCase cho AppColors).

🌿 Quy trình làm việc trên GitHub (Git Flow)
Chúng ta không bao giờ code trực tiếp trên nhánh main. Quy trình như sau:

1. Quy tắc đặt tên nhánh (Branching)
main: Nhánh chính, chứa code ổn định nhất (chỉ dùng để demo/nộp bài).

develop: Nhánh tập hợp code của mọi người để kiểm tra.

feature/tên-tính-năng: Nhánh làm tính năng mới (ví dụ: feature/login, feature/add-room).

bugfix/tên-lỗi: Nhánh để sửa lỗi.

2. Các bước đẩy code
Tạo nhánh mới từ develop: git checkout -b feature/manage-room

Làm việc và commit: git commit -m "feat: thêm giao diện danh sách phòng"

Đẩy lên GitHub: git push origin feature/manage-room

Tạo Pull Request (PR) trên GitHub để nhóm trưởng review và merge vào develop
