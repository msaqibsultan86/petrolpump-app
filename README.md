# Petrol Pump Management - Flutter App

## Setup Instructions

### 1. API Setup (on server)
1. Import `api/api_migration.sql` into your `petrolpump` database via phpMyAdmin
2. The API endpoints are at: `http://YOUR_SERVER/petrolpump/api/`
3. Test login: `POST http://YOUR_SERVER/petrolpump/api/login` with `{"username":"admin","password":"admin123"}`

### 2. Configure API URL
Edit `lib/config/api_config.dart` and set `baseUrl` to your server IP:
- Android Emulator: `http://10.0.2.2/petrolpump/api`
- Physical device (same WiFi): `http://192.168.X.X/petrolpump/api`
- Production: `https://yourdomain.com/petrolpump/api`

### 3. Build
```bash
flutter pub get
flutter run          # debug
flutter build apk    # release APK
```

## Features
- Login with token auth
- Dashboard with KPI cards, charts, tank levels
- Sales list with date filter
- Purchases list with date filter
- Expenses list with date filter
- Loans (given/taken) with tabs
- Tank levels with nozzle info
- Dip readings with variation
- Day Book with income/expense summary
- Multi-pump switcher
- Pull-to-refresh on all screens

## Default Login
- Username: `admin`
- Password: `admin123`
