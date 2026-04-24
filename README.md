# 🐾 Habitu (Habit U)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

**Habitu** is a delightful virtual pet companion that helps you build better habits while caring for your digital pet. Level up your life, level up your pet!

---

## ✨ Features

- **🐾 Virtual Pet Companion**: Choose between a cat or a dog and watch them grow as you progress.
- **📈 Evolution System**: Your pet evolves through 3 distinct stages as you reach level milestones (Level 10 and Level 30).
- **🏠 Isometric Room**: A beautiful isometric home for your pet that stays with you throughout your journey.
- **⏱️ Pomodoro Timer**: Stay focused on your tasks with a built-in Pomodoro timer to boost productivity.
- **💤 Sleep Tracker**: Track your sleep patterns to ensure you're getting the rest you need.
- **🏋️ Workout Mode**: Record your exercise sessions and stay active with your pet.
- **📅 Timeline & History**: Keep a record of your activities and pet's growth over time.
- **🎩 Style & Wardrobe**: Personalize your pet with various hats and accessories unlocked through the shop.
- **🏅 Achievement System**: Earn medals for your milestones and track your progress.
- **📸 Photo Feature**: Capture and save precious moments with your pet in beautifully composed photos.
- **🎵 Immersive Audio**: Relaxing background music and interactive sound effects for a better experience.
- **☁️ Firebase Integration**: Secure login and cloud synchronization for your pet's data and achievements.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Language**: [Dart](https://dart.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Authentication, Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Audio**: [audioplayers](https://pub.dev/packages/audioplayers)
- **Charts & UI**: [fl_chart](https://pub.dev/packages/fl_chart), [percent_indicator](https://pub.dev/packages/percent_indicator)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Firebase account](https://console.firebase.google.com/)
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sarankorn2547/habitu.git
   cd habitu/App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new project on [Firebase Console](https://console.firebase.google.com/).
   - Follow the FlutterFire CLI instructions to configure your project:
     ```bash
     flutterfire configure
     ```
   - Enable **Authentication** (Email/Password) and **Cloud Firestore** in the Firebase Console.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

- `lib/models`: Data models for Pet, User, Achievement, etc.
- `lib/screens`: All UI screens (Home, Login, Achievement, Style, etc.).
- `lib/services`: Firebase and local storage services.
- `lib/theme`: App theme and styling configurations.
- `assets/`: Images, icons, audio, and pet sprites.

---

## 🤝 Contributing

Contributions are welcome! If you'd like to improve Habitu, please feel free to fork the repo and create a pull request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git checkout -b feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

Developed with ❤️ by [Sarankorn2547](https://github.com/Sarankorn2547)