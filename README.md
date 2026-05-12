# Miami Notes

A Flutter notes app with live Miami weather integration. The weather card at the top updates based on current conditions, and each note is stamped with the weather at the time it was written.

## Features

- Live weather card for Miami, FL (temperature, condition, humidity, wind)
- Dynamic gradient background that changes with weather conditions
- Create and persist notes locally
- Each note records the weather when it was written
- Swipe left to delete a note

## Screenshots

> _Add screenshots here_

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A free [OpenWeatherMap](https://openweathermap.org/api) API key

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/Antoniodeoliveirasegura/miami_notes_test_app.git
   cd miami_notes_test_app
   ```

2. Copy the example env file and add your API key:
   ```bash
   cp .env.example .env
   ```
   Then open `.env` and replace `your_openweathermap_api_key_here` with your actual key.

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart            # App entry point, loads .env
├── home_screen.dart     # Main UI (weather card + notes list)
├── note.dart            # Note model with JSON serialization
└── weather_service.dart # OpenWeatherMap API integration
```

## Built With

- [Flutter](https://flutter.dev)
- [http](https://pub.dev/packages/http) — API calls
- [shared_preferences](https://pub.dev/packages/shared_preferences) — local note persistence
- [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) — environment variable management
- [OpenWeatherMap API](https://openweathermap.org/api)
