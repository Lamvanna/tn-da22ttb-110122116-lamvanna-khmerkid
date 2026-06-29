# 🎓 KhmerKid API Reference Manual

Welcome to the **KhmerKid Backend API** documentation. This API is designed to serve a gamified educational mobile application for children learning the Khmer language.

---

## 🛠️ Global API Standard

### Base URL
```
http://localhost:5000/api
```

### Protocol & Headers
- All requests must be sent over **HTTPS** (production) or **HTTP** (local).
- Content Type: `application/json`
- Authentication Header format: `Authorization: Bearer <JWT_ACCESS_TOKEN>`

### Standard Response Structure

#### Success Response (200 OK, 201 Created)
```json
{
  "success": true,
  "message": "Mô tả kết quả thực hiện thành công",
  "data": { ... }
}
```

#### Error Response (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 500 Server Error)
```json
{
  "success": false,
  "message": "Chi tiết lỗi xảy ra",
  "errors": [ ... ] // Danh sách lỗi chi tiết từ Express Validator (nếu có)
}
```

---

## 🔒 1. Authentication (`/api/auth`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **POST** | `/auth/register` | Đăng ký tài khoản thường | ❌ | - |
| **POST** | `/auth/login` | Đăng nhập tài khoản thường | ❌ | - |
| **POST** | `/auth/logout` | Đăng xuất người dùng | ✅ | user / admin |
| **POST** | `/auth/refresh-token` | Refresh Access Token hết hạn | ❌ | - |
| **GET** | `/auth/google` | Đăng nhập bằng Google OAuth | ❌ | - |

### 1.1 Đăng ký tài khoản (`POST /auth/register`)
- **Body Params:**
  ```json
  {
    "name": "KhmerKid Student",
    "email": "student@khmerkid.com",
    "password": "Password123"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Đăng ký thành công!",
    "data": {
      "user": {
        "id": "60d0fe2c5311236168a109a1",
        "name": "KhmerKid Student",
        "email": "student@khmerkid.com",
        "role": "user",
        "level": 1,
        "xp": 0,
        "stars": 0
      },
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
  ```

### 1.2 Đăng nhập tài khoản (`POST /auth/login`)
- **Body Params:**
  ```json
  {
    "email": "student@khmerkid.com",
    "password": "Password123"
  }
  ```
- **Response (200 OK):** (Cấu trúc tương tự như Đăng ký)

---

## 🧑‍🎓 2. User & Profile (`/api/users`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **GET** | `/users/profile` | Lấy thông tin cá nhân | ✅ | user / admin |
| **PUT** | `/users/profile` | Cập nhật thông tin cá nhân | ✅ | user / admin |
| **GET** | `/users/rank` | Lấy xếp hạng của cá nhân | ✅ | user |

### 2.1 Xem thông tin hồ sơ (`GET /users/profile`)
- **Headers:** `Authorization: Bearer <Token>`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Lấy dữ liệu thành công!",
    "data": {
      "user": {
        "id": "60d0fe2c5311236168a109a1",
        "name": "KhmerKid Student",
        "email": "student@khmerkid.com",
        "avatar": "",
        "level": 3,
        "xp": 280,
        "stars": 35,
        "streak": 5,
        "badges": ["60d0fe2c5311236168a109b0"],
        "learningProgress": {
          "totalLessonsCompleted": 12,
          "totalGamesPlayed": 8,
          "listeningLevel": 1,
          "speakingLevel": 2,
          "readingLevel": 1,
          "writingLevel": 1
        }
      }
    }
  }
  ```

---

## 📚 3. Lessons (`/api/lessons`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **GET** | `/lessons` | Xem danh sách bài học | ✅ | user / admin |
| **GET** | `/lessons/:id` | Xem chi tiết bài học | ✅ | user / admin |
| **POST** | `/lessons` | Tạo bài học mới | ✅ | admin |
| **PUT** | `/lessons/:id` | Cập nhật bài học | ✅ | admin |
| **DELETE** | `/lessons/:id` | Xóa bài học | ✅ | admin |

---

## 🎧 4. Skill - Listening (`/api/listening`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **GET** | `/listening/lessons` | Lấy các bài luyện nghe | ✅ | user |
| **POST** | `/listening/result` | Nộp kết quả bài luyện nghe | ✅ | user |

### 4.1 Nộp kết quả nghe (`POST /listening/result`)
- **Body Params:**
  ```json
  {
    "lessonId": "60d0fe2c5311236168a109c1",
    "score": 90,
    "correctAnswers": 9,
    "totalQuestions": 10
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Kết quả đã được lưu!",
    "data": {
      "result": {
        "userId": "60d0fe2c5311236168a109a1",
        "lessonId": "60d0fe2c5311236168a109c1",
        "score": 90,
        "stars": 3,
        "passed": true
      },
      "rewards": {
        "xpGained": 10,
        "starsGained": 3,
        "levelUp": false,
        "newLevel": 3
      },
      "unlockedBadges": []
    }
  }
  ```

---

## ✍️ 6. Skill - Writing (`/api/writing`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **POST** | `/writing/check` | Chấm nét chữ tập viết | ✅ | user |

### 6.1 Chấm nét tập viết (`POST /writing/check`)
- **Body Params:**
  ```json
  {
    "lessonId": "60d0fe2c5311236168a109c3",
    "imageUrl": "https://cloudinary.com/images/user_draw_123.png"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Nét vẽ chữ Khmer đã được chấm điểm!",
    "data": {
      "score": 92,
      "accuracy": 92,
      "feedback": "Cực kỳ xuất sắc! Cả 3 nét bút của bạn đều rất chuẩn so với hình mẫu chữ Khmer ក.",
      "rewards": {
        "xpGained": 15,
        "starsGained": 3,
        "levelUp": true,
        "newLevel": 4
      }
    }
  }
  ```

---

## 📖 7. Skill - Reading (`/api/reading`)

| Method | Endpoint | Description | Auth Required | Role |
| :--- | :--- | :--- | :---: | :---: |
| **GET** | `/reading/lessons` | Lấy danh sách bài tập đọc | ✅ | user |
| **POST** | `/reading/result` | Nộp kết quả đọc thành công | ✅ | user |

---

## 🎮 8. Gamification & Features

### 8.1 Games (`/api/games`)
- **POST `/games/result`**: Nộp kết quả chơi game.
- **GET `/games/history`**: Xem lịch sử chơi game của tài khoản.

### 8.2 Rankings (`/api/rank`)
- **GET `/rank/top`**: Bảng xếp hạng toàn cầu (Global).
- **GET `/rank/weekly`**: Bảng xếp hạng tuần hiện tại.
- **GET `/rank/monthly`**: Bảng xếp hạng tháng.

### 8.3 Daily/Weekly Missions (`/api/missions`)
- **GET `/missions`**: Lấy danh sách nhiệm vụ của user và trạng thái tiến độ hiện tại.
- **POST `/missions/claim`**: Nhận phần thưởng khi hoàn thành nhiệm vụ.

---

## 🔌 Realtime WebSockets (`Socket.io`)

Realtime WebSockets được bảo vệ bằng token JWT. Client kết nối cần gửi token trong trường `auth.token`.

### Client-to-Server Events
| Event Name | Parameter | Description |
| :--- | :--- | :--- |
| `ping` | - | Kiểm tra kết nối với server |

### Server-to-Client Events
| Event Name | Payload | Trigger |
| :--- | :--- | :--- |
| `xp:update` | `{ xp: number }` | Khi người dùng được cộng XP |
| `level:update` | `{ level: number, xp: number }` | Khi người dùng thăng cấp |
| `streak:update` | `{ streak: number }` | Khi chuỗi ngày học được cập nhật |
| `badge:unlock` | `{ badge: Object, xpReward: number, starsReward: number }` | Khi mở khóa thành công một huy hiệu |
| `notification:new`| `{ notification: Object }` | Đẩy thông báo tức thời |
| `rank:update` | `{ rank: number }` | Khi thứ hạng hàng tuần thay đổi |
