# Flutter ProGuard rules

# Keep native methods
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Whisper native methods
-keep class com.voiceai.app.whisper.** { *; }
-keepclassmembers class * {
    native <methods>;
}

# Keep Hive models
-keep class * extends com.hive.** { *; }

# General rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions