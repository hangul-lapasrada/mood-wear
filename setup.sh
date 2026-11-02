#!/usr/bin/env bash
set -e
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is not installed or not on PATH. Install Flutter and try again.'
  exit 1
fi
flutter create --project-name mood_wear --platforms=android,ios .
flutter pub get
# Allow local HTTP calls to the development API on Android emulator.
python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/AndroidManifest.xml')
s=p.read_text()
s=s.replace('<application', '<application android:usesCleartextTraffic="true"', 1)
if 'android.permission.INTERNET' not in s:
    s=s.replace('<manifest', '<manifest',1)
    pos=s.index('>')+1
    s=s[:pos]+'\n    <uses-permission android:name="android.permission.INTERNET" />'+s[pos:]
p.write_text(s)
PY
echo 'Mood Wear Flutter setup complete.'
