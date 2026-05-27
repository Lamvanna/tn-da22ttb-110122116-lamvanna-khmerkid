# 🚀 KhmerKid Backend Setup Guide

This document covers installing, configuring, seeding, and running the **KhmerKid Backend Node.js Server**.

---

## 📋 Prerequisites

Ensure you have the following installed on your developer machine:
- **Node.js** >= 18.0.0
- **npm** >= 9.0.0
- **MongoDB Atlas** account (or local MongoDB Community Server)
- **Cloudinary** account (for image/audio hosting)
- **Google Cloud Console** account (for Google Sign-in OAuth credentials)

---

## 🛠️ Installation & Setup Steps

### Step 1: Install Dependencies
Open your terminal in the backend project root folder and execute:
```bash
npm install
```

### Step 2: Configure Environment Variables
Create a file named `.env` in the root of the `backend` directory (copy from `.env.example`).
```bash
cp .env.example .env
```

Open `.env` and configure the following parameters:

```env
# Server
PORT=5000
NODE_ENV=development
CLIENT_URL=http://localhost:3000

# Database
MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/khmerkid?retryWrites=true&w=majority

# JWT Configurations
JWT_SECRET=YOUR_SUPER_SECRET_ACCESS_KEY_32_CHARS
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=YOUR_SUPER_SECRET_REFRESH_KEY_32_CHARS
JWT_REFRESH_EXPIRES_IN=7d

# Google OAuth 2.0 (For Mobile App Auth)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=http://localhost:5000/api/auth/google/callback

# Cloudinary CDN Storage (For uploads)
CLOUDINARY_CLOUD_NAME=your-cloudinary-name
CLOUDINARY_API_KEY=your-cloudinary-key
CLOUDINARY_API_SECRET=your-cloudinary-secret
```

---

## 📦 Database Seeding

The backend includes automated seeding scripts to easily populate the database with educational materials, achievements, and tasks.

### Seed Everything (Recommended)
This runs badges, missions, and lessons seeding sequentially.
```bash
npm run seed
```

### Seed Separately
If you only want to reset and seed a specific module:
- **Badges seeder**: `npm run seed:badges` (Seeds 24 gamified badges)
- **Missions seeder**: `npm run seed:missions` (Seeds daily/weekly missions)
- **Lessons seeder**: `npm run seed:lessons` (Seeds 33 consonants, 24 vowels, and vocabulary)

---

## 🚀 Running the Server

### Development Mode (with hot reloading via Nodemon)
```bash
npm run dev
```

### Production Mode
```bash
npm run start
```

---

## 🧪 Testing the API

To verify that the setup is completely functional, you can run the following health-check request:

```bash
curl -X GET http://localhost:5000/api/health
```

Expected response structure:
```json
{
  "success": true,
  "message": "KhmerKid API is running! 🚀",
  "data": {
    "version": "1.0.0",
    "environment": "development",
    "timestamp": "2026-05-27T16:47:00Z"
  }
}
```
