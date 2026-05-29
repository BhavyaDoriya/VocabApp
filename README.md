# 🧠 Daily Vocab: Tactical Memory Engine

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)

A cross-platform (Android & Web) vocabulary acquisition engine designed with a dark, tactical HUD aesthetic. This application leverages a secure Supabase backend for data retention and integrates LLaMA 3.3 AI for dynamic, contextual data decryption (definitions and field examples).

---

## 🚀 Core Features

*   **Secure Authorization:** Full integration with Supabase Auth, including Email/Password, Google OAuth, and secure password recalibration (reset).
*   **Tactical Memory Bank:** A chronological, grid-based calendar UI for reviewing archived vocabulary. Filter intel by Global Cycle (Year), Month, and exact Day.
*   **AI Data Decryption:** Seamless integration with LLaMA 3.3 70B (via custom proxy) to dynamically generate JSON-formatted definitions and contextual usage examples for any saved word.
*   **Immersive Audio Engine:** Custom, platform-aware audio management featuring ambient background tracks and tactile UI sound effects (clicks/thumps).
*   **Cross-Platform Architecture:** Fully optimized to run natively on Android devices and compile to Google Chrome for web access.
*   **Atmospheric UI/UX:** Custom-built "Dusty Atmosphere" particle physics engine, neon-accented borders, and tactical typography.

---
## 🔐 Security Architecture (Zero-Trust Client)

This application is built with a strict security posture to protect both user data and proprietary API keys.

* **No Client-Side Secrets:** The application client holds **zero** sensitive AI API keys. Reverse-engineering the APK or Web Build will yield no exploitable credentials.
* **JWT Verification Handshake:** When requesting AI decryption, the client securely attaches the user's active Supabase Session Token (`Bearer $token`).
* **Stateless Edge Proxy:** Requests are routed through a custom-built Vercel Serverless Proxy. The proxy intercepts the request, mathematically verifies the JWT signature against the Supabase secret, and only forwards the request to the LLaMA model if the user is authenticated.
* **Row Level Security (RLS):** The PostgreSQL database enforces strict RLS policies. A user's `known_words` and `profiles` data is physically isolated at the database level and can only be queried by the authenticated user who owns it.

🔗 **[View the Secure Vercel Proxy Repository Here](https://github.com/BhavyaDoriya/Vocab_Proxy)**

## 🛠️ Technical Stack

*   **Frontend:** Flutter (Dart)
*   **Backend & Database:** Supabase (PostgreSQL)
*   **AI Orchestration:** LLaMA 3.3 70B (via Vercel Proxy API)
*   **Audio Management:** `audioplayers` package
*   **Network:** `http` package for REST API communication

---

## ⚙️ Initialization & Setup

### 1. Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.10+ recommended)
*   A [Supabase](https://supabase.com/) Project
*   Android Studio / VS Code (for deployment)

### 2. Clone the Repository
```bash
git clone [https://github.com/BhavyaDoriya/VocabApp.git](https://github.com/BhavyaDoriya/VocabApp.git)
cd VocabApp
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Database Configuration (Supabase)
Ensure your Supabase PostgreSQL database contains the following tables:
*   `profiles`: Stores `id` (references auth.users), `active_category`, `daily_goal`, `words_cleared_today`, and `last_completed_date`.
*   `known_words`: Stores `user_id`, `word`, and `created_at` (TIMESTAMPTZ DEFAULT NOW()).

### 5. Environment Variables
You will need to connect the app to your Supabase instance. Initialize Supabase in your `main.dart` with your specific credentials:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```
*(Note: Ensure your `vocabapp://callback` redirect URI is authorized in your Supabase Auth dashboard for mobile OAuth/Password resets).*

---

## 📱 Deployment

**To compile for Android (APK):**
```bash
flutter build apk --release
```

**To compile for Web (Chrome):**
```bash
flutter build web --release
```

---

## 📂 Project Structure Overview

```text
lib/
├── main.dart                 # Application entry point & Supabase init
├── auth_screen.dart          # Secure login/registration & OAuth
├── home_screen.dart          # Main tactical HUD & daily objectives
├── study_screen.dart         # Core vocabulary learning loop
├── test_screen.dart          # Arena for testing acquired intel
├── memory_bank_screen.dart   # Chronological calendar archive & AI decryption
├── audio_manager.dart        # Platform-aware singleton audio controller
├── dusty_atmosphere.dart     # Custom background physics engine
└── tactical_button.dart      # Standardized UI components
```

---

## 🛡️ License

This project is licensed under the [MIT License](https://choosealicense.com/licenses/mit/). See the [LICENSE](LICENSE) file in the root directory for full details.
