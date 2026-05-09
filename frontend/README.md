# Invoice Management Flutter App

Flutter frontend for the invoice management backend. It includes shop auth, dashboard metrics, POS barcode entry, product management, invoices, reports, and shop settings.

## Setup

Install Flutter, then from this folder run:

```bash
flutter create . --platforms android,ios,web
flutter pub get
flutter run -d chrome --web-hostname 192.168.29.39 --web-port 8080 --dart-define=API_BASE_URL=http://192.168.29.39:3000/api
```

For Android or iOS, keep the same backend URL when your device is on the same Wi-Fi network:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.29.39:3000/api
```

The app default API URL is already `http://192.168.29.39:3000/api`, so the `--dart-define` flag is optional unless you change IP or port.

Camera scanning works best in the Android/iOS app. Some desktop/mobile browsers block camera access on plain HTTP LAN addresses; if web scanning is blocked, run on a device build or allow the origin in the browser's camera/security settings.

## Release APK

For a Render backend, build the APK with the Render HTTPS API URL:

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://your-render-service.onrender.com/api
```

Install the generated APK from:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The Android manifest includes internet and camera permissions for API calls and barcode scanning.

## Current Screens

- Auth: login and shop registration.
- Dashboard: daily revenue, orders, average order value, low stock count, recent orders.
- POS: barcode entry, cart, payment mode, checkout.
- Products: list, search, add, edit.
- Invoices: recent orders and void action.
- Reports: daily sales, payment modes, top products, low stock.
- Settings: shop name, tax rate, sign out.

## Backend Assumption

The app expects the backend created in `../backend` to be reachable at `API_BASE_URL`.
