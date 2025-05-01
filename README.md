# 📱 CampusConnect

A modern social media application built with Flutter and Firebase, designed to connect students and faculty within a campus environment.

## 🚀 Features

- 🔐 Secure Authentication with Firebase
- 👥 User Profile Management
- 💬 Real-time Messaging
- 🔍 User Search Functionality
- 📱 Cross-platform Support (Android, iOS, Web)
- 🔔 Push Notifications
- 📸 Image Upload Capabilities
- 🔗 LinkedIn Integration

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- Flutter SDK (^3.5.4)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase Account
- Git

## 🛠️ Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/campus_connect.git
```

2. Navigate to the project directory:
```bash
cd campus_connect
```

3. Install dependencies:
```bash
flutter pub get
```

4. Configure Firebase:
   - Create a new Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files
   - Enable Authentication, Firestore, and Cloud Messaging in Firebase Console

5. Run the application:
```bash
flutter run
```

## 🔧 Project Structure

```
lib/
├── main.dart              # Application entry point
├── screens/               # UI screens
├── services/              # Firebase and API services
├── models/                # Data models
├── widgets/               # Reusable widgets
└── utils/                 # Utility functions
```

## 📦 Dependencies

- firebase_core: ^3.8.1
- firebase_auth: ^5.3.1
- cloud_firestore: ^5.3.4
- firebase_messaging: ^15.1.6
- image_picker: ^1.1.2
- shared_preferences: ^2.1.0
- permission_handler: ^10.0.0
- url_launcher: ^6.0.0

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- Md Fakruddin S- Initial work

## 🙏 Acknowledgments

- Flutter Team
- Firebase Team
- All contributors and supporters

## 📞 Support

For support, email zayed.fakruddin@gmail.com or open an issue in the repository.

---

Made with ❤️ using Flutter
