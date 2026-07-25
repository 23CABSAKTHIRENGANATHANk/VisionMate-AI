## Android Release Signing — One-Time Setup

Run this single command in your terminal to generate the release keystore:

```powershell
keytool -genkeypair `
  -keystore "c:\workspace\visionmate_ai\android\app\upload-keystore.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload `
  -storepass VisionMate2026 `
  -keypass VisionMate2026 `
  -dname "CN=VisionMateAI,OU=Engineering,O=VisionMate,L=Chennai,S=TamilNadu,C=IN"
```

The `key.properties`, `build.gradle.kts`, and `proguard-rules.pro` are already configured.
Keep `upload-keystore.jks` and `key.properties` SECRET — never commit them to git.
