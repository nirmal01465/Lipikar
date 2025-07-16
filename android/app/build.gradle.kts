import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from android/key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    } else {
        logger.warn("Keystore properties file not found at ${keystorePropertiesFile.absolutePath}")
    }
}

android {
    namespace = "com.visionlab.lipikar"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.visionlab.lipikar"
        minSdk = 24
        targetSdk = 36
        versionCode = 4
        versionName = flutter.versionName
    }

    // Define your release signing config
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystorePropertiesFile
                .let { File(it.parent, keystoreProperties["storeFile"] as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // Enable code shrinking, obfuscation, and optimization (optional but recommended)
            isMinifyEnabled = true
            // Use the release signing config
            signingConfig = signingConfigs.getByName("release")
            // Default ProGuard rules; adjust if you have custom proguard-rules.pro
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // leave debug as-is
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // If you have productFlavors or other blocks, keep them here
}

flutter {
    source = "../.."
}
