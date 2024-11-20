# Contact Tracing App

This is a **Contact Tracing App** built using **Flutter**, **Google Nearby API**, and **Firebase**. The app is designed to assist in tracking close contact interactions for better pandemic management and health monitoring.

## Features

- **Nearby Device Detection**: Uses Google Nearby API to detect and exchange encrypted identifiers with nearby devices.
- **Contact Logging**: Stores interactions with other devices securely in Firebase.

## Tech Stack

- **Frontend**: Built with Flutter for a seamless cross-platform experience.
- **Backend**: Firebase for real-time database and cloud storage.
- **Communication**: Google Nearby API for Bluetooth-based proximity detection.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/contact-tracing-app.git
   cd contact-tracing-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
   - Add your app's `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) files to the project.

4. Run the app:
   ```bash
   flutter run
   ```

## How It Works

1. When the app is running, it uses the Google Nearby API to detect other devices in proximity.
2. If a user reports a positive case, their interaction history is uploaded to Firebase.

## Future Enhancements

- Add geolocation-based contact tracking.
- Enable QR code-based check-ins for public spaces.
- Implement advanced analytics for health authorities.

## License

This project is licensed under the [MIT License](LICENSE).

---

Feel free to contribute or raise issues in the repository! 🎉
