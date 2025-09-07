# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep notification related classes
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Flutter notification plugin classes
-keep class io.flutter.plugins.** { *; }

# Keep timezone data
-keep class org.threeten.** { *; }

# Keep notification service
-keep class **NotificationService { *; }
-keep class **notification** { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
