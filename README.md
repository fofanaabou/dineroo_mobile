# Dineroo Mobile

## 📌 Description

Dineroo is a mobile application for meal delivery in Guinea. This project supports **Android and iOS**.

## 🛠 Prerequisites

- **Flutter SDK** installed → [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Android Studio** (or VS Code with the Flutter extension)
- **An Android emulator installed and configured**

## 🚀 Installation

Clone the project and install dependencies:

```bash
# Clone the repository
git clone https://github.com/dineroo-gn/dineroo_mobile.git
cd dineroo_mobile

# Install dependencies
flutter pub get
```

## 🔥 Run the Application

### API Base URL (Local/Production)

- Local: `make run dev` (alias: `make run-dev`)
- Production API: `make run prod` (alias: `make run-prod`)
- `run-dev` copies `.env.local.example` to `.env`, then runs `flutter run`
- `run-dev` starts a Cloudflare tunnel, writes the tunnel URL into `.env` as `API_BASE_URL`, then runs `flutter run`
- The tunnel is stopped automatically when `flutter run` exits (including Ctrl+C)
- `run-prod` copies `.env.production.example` to `.env`, then runs `flutter run`

### Dev mode (Android/iOS, physical/simulator)

- Run `make run dev`
- Requires `cloudflared` installed (`brew install cloudflared`)
- Uses one temporary HTTPS URL valid for all devices
- Avoids manual LAN IP setup and device-specific localhost mapping

### 📱 On an Android Emulator

1. Open Android Studio

2. Go to Tools > Device Manager

3. Start an existing emulator or create a new one

4. Once the emulator is running, execute the following command:

```bash
flutter run
```

### 📄 Project Structure

- `lib/` → Main Dart code

- `android/` → Android configuration

- `ios/` → iOS configuration

- `pubspec.yaml` → Flutter dependencies and configurations

## 📜 License

This project is licensed under the MIT License.
