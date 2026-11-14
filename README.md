# Doctor Appointment Manager (Flutter, offline, SQLite)

## Demo logins
| Role      | Username  | Password    |
|-----------|-----------|-------------|
| Doctor    | doctor    | Doctor@123  |
| Assistant | assistant | Assist@123  |

Passwords are stored only as salted, iterated SHA-256 hashes in flutter_secure_storage (Android Keystore).

## Build & install
1. Install Flutter (3.22+) and Android SDK; enable USB debugging on the phone.
2. In this folder run: `./setup.sh`  (creates android/ project, adds mic permission, sets minSdk 23, runs pub get)
3. Test on phone: `flutter run`
4. Build APK: `flutter build apk --release`
   -> `build/app/outputs/flutter-apk/app-release.apk` (copy to phone and install; allow "unknown sources").

## Data
SQLite file `doctor_app.db` in the app's private internal storage (survives restarts). No network code except
the phone's own speech service. No SMS/messaging code exists.
Backup: menu -> "Backup / export database" (saves a copy and opens the share sheet). Restore (Doctor menu) picks a .db backup file.

## Voice input (Bangla)
Uses Android speech recognition with locale bn_BD. For offline use install the Bangla pack:
Settings -> Google -> Speech / Google app -> Offline speech recognition -> Bengali.
Say e.g. "নাম রহিম উদ্দিন বয়স ৩৫ ফোন ০১৭১২৩৪৫৬৭৮". Fields are filled only as a draft; nothing is saved until you press Confirm Appointment.
