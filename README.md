# Openfolio

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
</p>

## 📱 About

Openfolio is an open-source cryptocurrency portfolio tracker inspired by the original Blockfolio app. Built with Flutter, it provides a sleek, modern interface for tracking your crypto investments across multiple exchanges.

### ✨ Features

- **Portfolio Management**: Track holdings across multiple cryptocurrencies
- **Price Tracking**: View current prices with 24-hour change indicators
- **Interactive Charts**: View price history with 1D, 7D, 30D, and all-time ranges
- **Watchlist**: Monitor tokens without adding holdings
- **Search Functionality**: Easily find and add new tokens
- **Market Statistics**: View market cap, volume, and volume changes
- **Dark Theme**: Beautiful dark UI optimized for OLED displays
- **Offline Support**: Cached data for offline viewing

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS development setup (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/openfolio.git
   cd openfolio
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API credentials**
   
   Create a file `lib/config/secrets.dart` with your API configuration:
   ```dart
   // lib/config/secrets.dart
   const String baseUrl = 'YOUR_API_BASE_URL';
   const String authToken = 'YOUR_AUTH_TOKEN';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

The project follows a clean architecture pattern with the following structure:

```
lib/
├── config/           # API configuration
├── core/            
│   ├── theme/       # App theme and colors
│   └── utils/       # Utility functions and formatters
├── data/
│   ├── models/      # Data models
│   ├── repositories/# Data repositories
│   └── services/    # API and storage services
└── presentation/
    ├── providers/   # State management
    ├── screens/     # App screens
    └── widgets/     # Reusable widgets
```

### Key Technologies

- **State Management**: Provider
- **Networking**: Dio
- **Local Storage**: SharedPreferences
- **Charts**: fl_chart
- **Image Caching**: cached_network_image

## 📸 Screenshots

<p align="center">
  <img src="screenshots/portfolio.png" width="250" alt="Portfolio Screen">
  <img src="screenshots/token_detail.png" width="250" alt="Token Detail">
  <img src="screenshots/search.png" width="250" alt="Search Screen">
</p>

## 🔧 Configuration

### API Requirements

The app expects a backend API with the following endpoints:

- `GET /api/search/?query={query}` - Search for tokens
- `POST /api/portfolio/` - Get portfolio data with current prices

### API Response Format

**Search Response:**
```json
[
  {
    "id": 1,
    "name": "Bitcoin (BTC)",
    "logo": "https://...",
    "market_cap": 1000000000
  }
]
```

**Portfolio Response:**
```json
[
  {
    "token_id": 1,
    "ticker": "BTC",
    "name": "Bitcoin",
    "logo": "https://...",
    "price": 50000.00,
    "price_24h_change": 5.2,
    "market_cap": 1000000000,
    "volume": 50000000,
    "volume_24h_change": 10.5,
    "24h_price_history": [[timestamp, price], ...],
    "daily_price_history": [["2024-01-01", price], ...]
  }
]
```

## 🚀 Development

### Development Setup

1. **Enable Flutter web support** (for development)
   ```bash
   flutter config --enable-web
   ```

2. **Run with verbose output**
   ```bash
   flutter run -v
   ```

3. **Run tests**
   ```bash
   flutter test
   ```

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📧 Contact

Aaron Pardes - [@aaronpardes](https://x.com/aaronpardes)

Project Link: [https://openfolio.io](https://openfolio.io)

---

<p align="center">Made with ❤️ for the crypto community</p>