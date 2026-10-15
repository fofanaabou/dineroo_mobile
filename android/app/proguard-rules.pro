# Flutter & Kotlin safe defaults
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.**

# Keep your app’s main classes
-keep class com.dineroo.** { *; }

# Optional: Firebase, Google Maps
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }