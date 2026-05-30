# Flutter Starter Kit

A robust and scalable Flutter Starter Kit designed to accelerate the development of new Flutter applications. This starter kit is built with a clear folder structure and a layered architectural pattern.

## 🏗 Architecture & Folder Structure

This project follows a feature-based and layered architecture, ensuring separation of concerns and scalability.

Inside the `lib/` directory:

- **`features/`**: Contains modular features of the app. Each feature can have its own isolated logic, UI, and state.
- **`models/`**: Data models and serialization logic (e.g., classes representing your API data).
- **`providers/`**: State management classes using `provider`. Business logic is handled here to keep UI clean.
- **`screens/`**: The main UI pages/views of the application.
- **`services/`**: Network requests, API calls, and third-party integrations (e.g., Firebase, REST APIs).
- **`storage/`**: Local storage logic using `Hive` (NoSQL database).
- **`themes/`**: App-wide styling, colors, typography, and light/dark mode definitions.
- **`utils/`**: Helper functions, constants, extensions, and reusable logic.
- **`widgets/`**: Shared, reusable UI components used across multiple screens (e.g., custom buttons, text fields).

## 📦 Core Dependencies

This starter kit comes pre-configured with essential packages for modern Flutter development:

- **[Provider](https://pub.dev/packages/provider)**: Recommended state management.
- **[Hive](https://pub.dev/packages/hive)**: Blazing fast, lightweight key-value database for local storage.
- **[Google Fonts](https://pub.dev/packages/google_fonts)**: Easy typography management.
- **[Flutter Animate](https://pub.dev/packages/flutter_animate)**: Performant, beautiful animations.
- **UI Enhancements**: `glassmorphism_ui`, `liquid_glass_widgets`, and `blur` for modern, premium design aesthetics.

## 🚀 How to use this Starter Kit

To use this starter kit for a new project:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/USERNAME/flutter-starter-kit.git my_new_app
   ```
2. **Navigate into the directory:**
   ```bash
   cd my_new_app
   ```
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Rename the App:**
   Use a tool like [rename](https://pub.dev/packages/rename) to easily change the package name and app name to your new project's name.

## ✨ Design Philosophy
The design remains consistent across apps built with this kit. Focus on creating premium, dynamic interfaces by utilizing the pre-installed animation and glassmorphism packages.
