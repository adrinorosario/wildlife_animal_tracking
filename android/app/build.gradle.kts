plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// apply(from = project(":flutter_config_plus").projectDir.path + "/dotenv.gradle")

// Check if the plugin exists before trying to apply its gradle script
// Line 11 (or thereabouts) in android/app/build.gradle.kts
// This works without needing the settings.gradle edit
// if (File("${rootProject.projectDir}/../.env").exists()) {
//     apply(from = "../../node_modules/flutter_config_plus/android/dotenv.gradle") 
// }

android {
    namespace = "com.example.wildlife_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.wildlife_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 30
        targetSdk = 30
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = if (project.extra.has("env")) {
             val env = project.extra["env"] as Map<*, *>
             (env["GOOGLE_MAPS_API_KEY"] ?: "").toString()
        } else {
            ""
        }

    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
