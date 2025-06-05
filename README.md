# LifeLink+

A modern emergency health assistance application built with Flutter. LifeLink+ helps users access emergency medical services, store health information, and get first aid guidance quickly and efficiently.

## Features

- 🏥 **Nearby Hospitals**: Find and get directions to nearby medical facilities
- 🤖 **First Aid Bot**: Get instant first aid guidance and medical advice
- 💳 **Emergency Health Card**: Store and access critical medical information
- 🆘 **SOS Button**: Quick access to emergency services
- ⚙️ **Customizable Settings**: Personalize your experience with theme and language options

## Screenshots

(Screenshots will be added once the app is running)

## Getting Started

### Prerequisites

- Flutter SDK (3.8.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/lifelink.git
   ```

2. Navigate to the project directory:
   ```bash
   cd lifelink
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Architecture

The app follows a clean architecture pattern with the following structure:

```
lib/
  ├── core/
  │   ├── router/        # Navigation setup
  │   ├── theme/         # App theme configuration
  │   └── widgets/       # Shared widgets
  │
  ├── features/
  │   ├── home/          # Home screen
  │   ├── hospitals/     # Nearby hospitals feature
  │   ├── first_aid/     # First aid bot feature
  │   ├── health_card/   # Health card feature
  │   └── settings/      # App settings
  │
  └── main.dart          # App entry point
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Material Design 3 for the modern UI components
- Flutter team for the amazing framework
- All contributors who help improve the app
