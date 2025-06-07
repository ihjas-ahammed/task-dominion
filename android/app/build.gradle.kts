// Step 1: Define a variable to load the keystore properties
def keystoreProperties = new Properties()
// The `rootProject` in this context is the `android` directory.
// This line looks for `key.properties` inside the `android/` folder.
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.arcane"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Step 2: Add the signing configuration for release builds
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                // The `storeFile` path is relative to the `android` directory because we use `rootProject.file()`.
                storeFile rootProject.file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
            }
        }
    }

    defaultConfig {
        applicationId = "me.ihjas.arcane"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Step 3: Assign the new signing configuration to the release build type.
            signingConfig signingConfigs.release
        }
    }
}