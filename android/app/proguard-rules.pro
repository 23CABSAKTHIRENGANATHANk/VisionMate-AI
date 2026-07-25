# VisionMate AI — ProGuard / R8 Rules
# These rules prevent R8 from stripping or renaming TFLite and camera classes
# that are loaded reflectively at runtime in a release build.

# ── TensorFlow Lite ──────────────────────────────────────────────────────────

# Keep all TFLite Interpreter and delegate classes
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep GPU delegate (if present in the build)
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Keep NNAPI delegate
-keep class org.tensorflow.lite.nnapi.** { *; }
-dontwarn org.tensorflow.lite.nnapi.**

# ── Flutter Plugins (Camera + TTS) ───────────────────────────────────────────

# Keep all camera plugin classes
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Keep flutter_tts plugin
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# ── Flutter Engine ────────────────────────────────────────────────────────────

# Flutter embedding classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# ── General Android Safety ────────────────────────────────────────────────────

# Preserve Parcelables
-keep class * implements android.os.Parcelable { *; }

# Keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
