#!/usr/bin/env bash
# Run once inside this folder (needs Flutter SDK + Android SDK installed).
set -e
cp -r lib /tmp/da_lib; cp pubspec.yaml /tmp/da_pubspec.yaml
flutter create --platforms=android --org com.clinic.demo --project-name doctor_appointment_manager .
rm -rf lib; cp -r /tmp/da_lib lib; cp /tmp/da_pubspec.yaml pubspec.yaml
rm -f test/widget_test.dart
python3 - <<'PY'
import re,glob
p='android/app/src/main/AndroidManifest.xml'
s=open(p).read()
if 'RECORD_AUDIO' not in s:
    perms='<uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <uses-permission android:name="android.permission.INTERNET"/>'
    intent='<intent><action android:name="android.speech.RecognitionService"/></intent>'
    if '</queries>' in s:
        s=s.replace('</queries>','    '+intent+'\n    </queries>',1)
        s=s.replace('<application',perms+'\n    <application',1)
    else:
        s=s.replace('<application',perms+'\n    <queries>'+intent+'</queries>\n    <application',1)
    s=re.sub(r'android:label="[^"]*"','android:label="Doctor Appointments"',s,1)
    open(p,'w').write(s)
for g in glob.glob('android/app/build.gradle*'):
    t=open(g).read()
    if g.endswith('.kts'):
        t=re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion','minSdk = 23',t)
    else:
        t=re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion','minSdkVersion 23',t)
    open(g,'w').write(t)
PY
flutter pub get
echo "Done. Run: flutter run   |   flutter build apk --release"
