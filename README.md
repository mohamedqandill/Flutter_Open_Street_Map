# Masar - Modern Smart Navigation & Mapping App 🗺️🚀

Masar is a high-performance, feature-rich Flutter mapping application built using **OpenStreetMap (OSM)** and **OpenRouteService**. It delivers a premium user experience similar to Google Maps while maintaining the data richness of OSM.

## ✨ Key Features

### 📍 Real-Time Location Tracking
- **Live User Icon:** Smoothly moving user location marker with a modern blue pulsing effect.
- **Auto-Following Camera:** The camera automatically centers and follows the user during movement.
- **Lifecycle Smart Sync:** Automatically re-checks and prompts for location permissions and GPS service status whenever the app resumes from the background.

### 🛣️ Smart Routing & Navigation
- **Point-to-Point Routing:** Calculate the fastest driving route between any two points.
- **Interactive Map Selection:** Long-press or tap on the map to set an origin or destination.
- **Automatic Camera Framing:** Automatically zooms and pans to perfectly fit the entire calculated route within the screen (FitBounds logic).

### 🔍 Search & Geocoding
- **Autocomplete Search:** Real-time place suggestions as you type, powered by Pelias/ORS.
- **Smart Address Formatting:** Cleanly formatted addresses (Title & Subtitle) that remove redundant text for a professional look.
- **Reverse Geocoding:** Tap anywhere on the map to instantly see the real-world address of that point.

### 💨 Performance & Cache
- **Offline Tile Caching:** Uses `CachedNetworkImage` to store map tiles locally. This makes the map incredibly smooth, reduces data usage, and eliminates loading lag in Release mode.
- **State Management:** Fully refactored using the **Provider pattern** for a clean separation between UI and business logic.

### 💎 Premium UI/UX
- **Dynamic Route Details:** A bottom sheet showing estimated travel time (minutes) and distance (kilometers).
- **Time Bubbles:** An interactive floating bubble appears directly on the route line showing the travel time at the midpoint.
- **One-Tap Reset (Clear Layers):** A dedicated button to clear all routes, markers, and search results to reset the view.

---

## 🛠️ Tech Stack
- **Framework:** [Flutter](https://flutter.dev)
- **Map Engine:** [flutter_map](https://pub.dev/packages/flutter_map) (OSM based)
- **API Provider:** [OpenRouteService](https://openrouteservice.org/)
- **Data Model:** [Geolocator](https://pub.dev/packages/geolocator) for precise positioning.
- **State Management:** [Provider](https://pub.dev/packages/provider).
- **Networking:** [Dio](https://pub.dev/packages/dio) with [Pretty Dio Logger](https://pub.dev/packages/pretty_dio_logger).

## 🚀 How to Run
1. Get an API Key from [OpenRouteService](https://openrouteservice.org/dev/#/signup).
2. Add your key to `lib/utils/constants.dart`.
3. Run `flutter pub get`.
4. Run `flutter run --release` for the smoothest experience.

---
*Developed with ❤️ for precision and speed.*
