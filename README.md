# PHÁT TRIỂN ỨNG DỤNG HỌC CHỮ KHMER CHO HỌC SINH TIỂU HỌC

## 📋 Thông tin chung

| Thông tin | Chi tiết |
|---|---|
| **Tên đề tài** | Phát triển ứng dụng học chữ Khmer cho học sinh tiểu học |
| **Sinh viên thực hiện** | *Lâm Văn Na* |
| **MSSV** | *110122116* |
| **Lớp** | *DA22TTB* |
| **Năm học** | 2025 – 2026 |

---

## 📖 Giới thiệu

**KhmerKid** là ứng dụng di động đa nền tảng (Android/iOS) hỗ trợ học sinh tiểu học (6–12 tuổi) học chữ Khmer một cách trực quan và sinh động. Ứng dụng cung cấp hệ thống bài học có cấu trúc gồm 11 chủ đề từ cơ bản đến nâng cao, kết hợp công nghệ trí tuệ nhân tạo (AI) để:

- **Nhận diện chữ viết tay** bằng mô hình AI lai hai tầng (Hybrid Two-Tier): Google ML Kit (on-device) + Phân tích hình học DTW (backend).
- **Đánh giá phát âm** tự động bằng Google Cloud Speech-to-Text API.
- **Phát âm chuẩn tiếng Khmer** từ file âm thanh người bản ngữ.
- **Gamification toàn diện** với sao, XP, streak, huy hiệu, bảng xếp hạng và 11 trò chơi giáo dục.

### Đối tượng sử dụng
- **Chính**: Trẻ em tiểu học (6–12 tuổi) muốn học hoặc củng cố kiến thức tiếng Khmer.
- **Phụ**: Phụ huynh, giáo viên theo dõi tiến độ học tập của trẻ.

---

## 🏗️ Kiến trúc hệ thống

Ứng dụng được xây dựng theo kiến trúc **Client-Server**, gồm:
- **Client**: Ứng dụng Flutter đa nền tảng (Android/iOS).
- **Server**: RESTful API Node.js/Express.js, giao tiếp thời gian thực qua Socket.IO.
- **Cơ sở dữ liệu**: MongoDB Atlas (Cloud).
- **Lưu trữ đám mây**: Cloudinary (hình ảnh).

```
┌─────────────────────────────────┐     ┌──────────────────────────────────┐
│      CLIENT (Flutter App)       │     │      SERVER (Node.js Backend)    │
│                                 │     │                                  │
│  ┌───────────────────────────┐  │     │  ┌────────────────────────────┐  │
│  │   UI Layer (Screens)      │  │     │  │  Express.js REST API       │  │
│  │   + Widgets               │  │     │  │  + Socket.IO WebSocket     │  │
│  └──────────┬────────────────┘  │     │  └──────────┬─────────────────┘  │
│  ┌──────────▼────────────────┐  │     │  ┌──────────▼─────────────────┐  │
│  │   Service Layer           │──┼─HTTP─┼─▶│  Controllers + Services   │  │
│  │   (Auth, TTS, Score,      │  │  +   │  │  (AI Analyzer, Speech,    │  │
│  │    Handwriting, Voice)    │──┼─WS──┼─▶│   Scoring, TTS)           │  │
│  └──────────┬────────────────┘  │     │  └──────────┬─────────────────┘  │
│  ┌──────────▼────────────────┐  │     │  ┌──────────▼─────────────────┐  │
│  │   Repository Layer        │  │     │  │  Mongoose Models (19)      │  │
│  └───────────────────────────┘  │     │  └──────────┬─────────────────┘  │
│                                 │     │  ┌──────────▼─────────────────┐  │
│  ┌───────────────────────────┐  │     │  │  MongoDB Atlas (Cloud)     │  │
│  │   Google ML Kit (Tier 1)  │  │     │  └────────────────────────────┘  │
│  │   On-device Recognition   │  │     │                                  │
│  └───────────────────────────┘  │     │  ┌────────────────────────────┐  │
│                                 │     │  │  Google Cloud STT + TTS    │  │
└─────────────────────────────────┘     │  │  Cloudinary (Images)       │  │
                                        │  └────────────────────────────┘  │
                                        └──────────────────────────────────┘
```

---

## 💻 Công nghệ sử dụng

### Phía Client (Mobile App)

| Công nghệ | Phiên bản | Mục đích |
|---|---|---|
| Flutter (Dart) | SDK ^3.11.4 | Framework phát triển ứng dụng đa nền tảng |
| Google ML Kit Digital Ink | 0.14.0 | Nhận diện chữ viết tay on-device (Tier 1) |
| flutter_tts + audioplayers | 4.2.2 / 5.2.1 | Text-to-Speech + Phát âm chuẩn từ file âm thanh |
| record | 5.0.0 | Ghi âm WAV để đánh giá phát âm |
| socket_io_client | 3.0.2 | WebSocket cho phân tích chữ viết real-time |
| google_sign_in | 6.2.1 | Đăng nhập Google OAuth 2.0 |
| flutter_screenutil | 5.9.3 | Responsive UI cho mọi kích thước màn hình |
| google_fonts | 8.0.2 | Typography (Plus Jakarta Sans, Noto Sans Khmer) |

### Phía Server (Backend)

| Công nghệ | Phiên bản | Mục đích |
|---|---|---|
| Node.js | ≥18.0.0 | Runtime JavaScript phía server |
| Express.js | 4.21.0 | Web framework RESTful API |
| MongoDB (Mongoose) | 8.7.0 | Cơ sở dữ liệu NoSQL đám mây |
| Socket.IO | 4.8.0 | WebSocket cho phân tích nét chữ real-time |
| Google Cloud Speech-to-Text | 5.6.0 | Nhận diện giọng nói tiếng Khmer |
| Cloudinary | 1.41.3 | Lưu trữ hình ảnh đám mây |
| JWT (jsonwebtoken) | 9.0.2 | Xác thực và phân quyền |
| opentype.js | 2.0.0 | Phân tích font chữ Khmer chuẩn |

---

## 📁 Cấu trúc thư mục dự án

```
├── docs/                           # Tài liệu đồ án
│   ├── baocao/                     # Báo cáo khóa luận (.docx, .pdf)
│   ├── slide/                      # Slide bảo vệ (.pptx)
│   ├── poster/                     # Poster A1 (.pdf)
│   ├── huongdan/                   # Hướng dẫn sử dụng & tham khảo kỹ thuật
│   ├── khoaluan_structure.md       # Cấu trúc chi tiết nội dung khóa luận
│   └── system_overview.md          # Tổng quan kiến trúc hệ thống
│
├── src/                            # Toàn bộ mã nguồn và cơ sở dữ liệu
│   ├── client/                     # Ứng dụng di động Flutter (Client)
│   │   ├── lib/                    # Mã nguồn chính của ứng dụng Flutter
│   │   │   ├── main.dart           # Điểm khởi đầu ứng dụng
│   │   │   ├── screens/            # Các màn hình UI (auth, learn, play, ...)
│   │   │   ├── services/           # Lớp dịch vụ (auth, TTS, AI, scoring, ...)
│   │   │   ├── widgets/            # Widget tái sử dụng (canvas viết, ghi âm, ...)
│   │   │   └── ...
│   │   ├── assets/                 # Tài nguyên ứng dụng client (âm thanh, dịch thuật)
│   │   │   ├── images/
│   │   │   ├── audio/khmer/
│   │   │   └── translations/
│   │   ├── image/                  # Ảnh chụp màn hình giao diện phục vụ app
│   │   ├── android/                # Cấu hình native Android
│   │   ├── ios/                    # Cấu hình native iOS
│   │   ├── test/                   # Flutter tests
│   │   ├── pubspec.yaml            # Cấu hình Flutter dependencies
│   │   └── analysis_options.yaml   # Lint rules
│   │
│   ├── backend/                    # Máy chủ API Node.js/Express (Server)
│   │   ├── server.js               # Entry point server
│   │   ├── src/                    # Mã nguồn chính của backend
│   │   │   ├── config/             # Cấu hình (db, cloudinary, passport)
│   │   │   ├── controllers/        # Controllers xử lý requests
│   │   │   ├── services/           # Services (AI analyzer, Speech, scoring)
│   │   │   ├── models/             # 19 Mongoose schemas (MongoDB)
│   │   │   ├── routes/             # Định tuyến API
│   │   │   ├── sockets/            # WebSocket handlers
│   │   │   ├── seeders/            # Scripts seed dữ liệu
│   │   │   └── ...
│   │   ├── test/                   # Unit tests
│   │   ├── .env.example            # Mẫu file cấu hình môi trường
│   │   └── package.json            # Dependencies Node.js
│   │
│   └── database/                   # Cơ sở dữ liệu
│       └── database_schema.sql     # Schema cơ sở dữ liệu MongoDB
│
├── .gitignore                      # Danh sách file/thư mục bỏ qua bởi Git
└── README.md                       # File này
```

---

## ⚙️ Yêu cầu phần mềm

### Phía Client (Flutter App)

| Phần mềm | Phiên bản tối thiểu |
|---|---|
| Flutter SDK | 3.11.4 trở lên |
| Dart SDK | 3.11.4 trở lên |
| Android Studio / VS Code | Phiên bản mới nhất |
| Android SDK | API 21+ (Android 5.0 Lollipop) |
| JDK | 17 |

### Phía Server (Backend)

| Phần mềm | Phiên bản tối thiểu |
|---|---|
| Node.js | 18.0.0 trở lên |
| npm | 8.0.0 trở lên |
| MongoDB Atlas | Tài khoản miễn phí (M0 Sandbox) |
| Google Cloud Account | Bật Speech-to-Text API |

---

## 🚀 Hướng dẫn Cài đặt và Chạy chương trình

### 1. Clone repository

```bash
git clone https://github.com/Lamvanna/KHOALUAN_TN.git
cd KHOALUAN_TN
```

### 2. Cài đặt và chạy Backend (Server)

```bash
# Di chuyển vào thư mục backend
cd src/backend

# Cài đặt dependencies
npm install

# Tạo file cấu hình môi trường từ mẫu
cp .env.example .env
# Sau đó chỉnh sửa file .env với thông tin kết nối MongoDB, JWT secret, API keys, v.v.

# Seed dữ liệu mẫu vào MongoDB (chỉ chạy lần đầu)
npm run seed

# Khởi chạy server ở chế độ phát triển
npm run dev

# Hoặc khởi chạy server ở chế độ production
npm start
```

Server sẽ chạy mặc định tại `http://localhost:5000`.

### 3. Cài đặt và chạy Client (Flutter App)

```bash
# Di chuyển vào thư mục client từ thư mục gốc
cd src/client

# Cài đặt Flutter dependencies
flutter pub get

# Kiểm tra môi trường Flutter
flutter doctor

# Chạy ứng dụng trên thiết bị/emulator Android
flutter run

# Hoặc build APK để cài đặt trực tiếp
flutter build apk --release
```

### 4. Cấu hình kết nối Client ↔ Server

- Khi chạy trên **emulator Android**: Ứng dụng tự động dò tìm IP server trong mạng LAN.
- Khi chạy trên **thiết bị thật**: Đảm bảo thiết bị và máy chạy server cùng mạng WiFi. Ứng dụng hỗ trợ nhập IP thủ công trong phần Cài đặt.

---

## 🎬 Video Demo

> 📹 *(Thêm link video demo tại đây)*

---

## 📚 Tài liệu tham khảo

- Báo cáo khóa luận: [`docs/baocao/`](docs/baocao/)
- Slide bảo vệ: [`docs/slide/`](docs/slide/)
- Poster A1: [`docs/poster/`](docs/poster/)
- Tổng quan hệ thống: [`docs/system_overview.md`](docs/system_overview.md)
- Cấu trúc khóa luận: [`docs/khoaluan_structure.md`](docs/khoaluan_structure.md)
- Schema cơ sở dữ liệu: [`src/database/database_schema.sql`](src/database/database_schema.sql)
- Hướng dẫn kỹ thuật: [`docs/huongdan/`](docs/huongdan/)
- API Documentation: [`src/backend/src/docs/API.md`](src/backend/src/docs/API.md)

---

## 📞 Liên hệ

- **Email**: *(lamvanna@gmail.com*
- **GitHub**: [github.com/Lamvanna](https://github.com/Lamvanna)

---

> **Ghi chú**: Dự án này được phát triển trong khuôn khổ khóa luận tốt nghiệp. Mọi đóng góp và phản hồi đều được hoan nghênh.
