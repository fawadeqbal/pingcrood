# PingCrood Chat Application

A high-performance, real-time chat application built with Flutter and NestJS, featuring a professional UI and robust communication features.

## 🚀 Key Features

### 💬 Real-time Messaging
- **Instant Communication**: Powered by Socket.io for sub-millisecond message delivery.
- **Message Status**: Real-time Sent, Delivered, and Seen indicators.
- **Typing Indicators**: Visual feedback when your partner is typing.
- **Pinned Messages**: Easily pin and access important information in any chat.
- **Message Reactions**: Express yourself with a wide range of interactive emoji reactions.

### 👥 Social & Networking
- **Presence Tracking**: Real-time Online/Offline status indicators.
- **Friend Management**: Full friend request system (Send, Accept, Decline).
- **QR Code Networking**: Unique QR codes for seamless user identification and networking.
- **Unified Profile**: Personalized profile with custom avatars and biographical info.

### 🎨 User Experience
- **Premium Design**: Modern, responsive UI with advanced animations and glassmorphism.
- **Theme Engine**: Support for both vibrant Light and professional Dark modes.
- **Web & Mobile**: Fully cross-platform experience optimized for Chrome and Android.
- **Push Notifications**: Integrated local notifications to never miss a message.

## 🛠 Technical Stack

### Frontend (Flutter)
- **State Management**: Provider with a structured notification architecture.
- **Networking**: Dio (HTTP) + Socket.io Client (Real-time).
- **Theme System**: Dynamic ThemeProvider for visual consistency.
- **Asset Handling**: Integrated image picker and file upload support.

### Backend (NestJS)
- **Framework**: NestJS for a scalable, modular architecture.
- **Real-time Gateway**: Custom Socket.io gateway for event-driven networking.
- **ORM & Database**: Prisma with PostgreSQL for efficient data management.
- **Presence Engine**: Redis-backed presence tracking for high-volume status updates.
- **Security**: JWT-based authentication with robust guard verification.
- **File Storage**: Professional static file serving with automated upload management.

## 📁 Project Structure

- `chat_flutter_app/`: Flutter mobile and web frontend.
- `chat-nest-backend/`: NestJS API and real-time backend service.

## ⚙️ Quick Start

1. **Backend Setup**:
   - `cd chat-nest-backend`
   - `npm install`
   - Configure `.env` with your PostgreSQL and SMTP details.
   - `npx prisma db push`
   - `npm run start:dev`

2. **Frontend Setup**:
   - `cd chat_flutter_app`
   - `flutter pub get`
   - Update `baseUrl` in `ApiClient` to point to your backend.
   - `flutter run`
