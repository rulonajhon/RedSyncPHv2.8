import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load secrets from properties file
val secretsPropertiesFile = rootProject.file("secrets.properties")
val secretsProperties = Properties()
if (secretsPropertiesFile.exists()) {
    secretsProperties.load(secretsPropertiesFile.inputStream())
}

android {
    namespace = "com.example.hemophilia_manager"
    compileSdk = 36  // Updated to 36 for plugin compatibility
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hemophilia_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdkVersion(24)  // Set to API level 24 as required by geolocator plugin
        targetSdk = 36  // Updated to match compileSdk for plugin compatibility
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Inject Google Maps API key from secrets
        manifestPlaceholders["googleMapsApiKey"] = secretsProperties.getProperty("GOOGLE_MAPS_API_KEY", "")
    }

    buildTypes {
        debug {
            // Debug build settings - more permissive for development
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
            // Debug builds are signed with debug key automatically
        }
        release {
            // Release build settings - optimized for production
            isDebuggable = false
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Disable code shrinking and obfuscation to prevent notification crashes
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Release-specific optimizations
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
