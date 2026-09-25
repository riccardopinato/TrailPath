plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val storeFilePath = System.getenv("TRAILPATH_STORE_FILE")?.takeIf { it.isNotBlank() }
val storePasswordValue =
    System.getenv("TRAILPATH_STORE_PASSWORD")?.takeIf { it.isNotBlank() }
val keyAliasValue = System.getenv("TRAILPATH_KEY_ALIAS")?.takeIf { it.isNotBlank() }
val keyPasswordValue =
    System.getenv("TRAILPATH_KEY_PASSWORD")?.takeIf { it.isNotBlank() }
val requireStoreSigning =
    System.getenv("TRAILPATH_REQUIRE_STORE_SIGNING")?.equals("true", ignoreCase = true) == true

val hasStoreSigning =
    storeFilePath != null &&
        storePasswordValue != null &&
        keyAliasValue != null &&
        keyPasswordValue != null &&
        file(storeFilePath).isFile

if (requireStoreSigning && !hasStoreSigning) {
    throw GradleException(
        "Store signing was required but TRAILPATH_STORE_FILE, " +
            "TRAILPATH_STORE_PASSWORD, TRAILPATH_KEY_ALIAS and " +
            "TRAILPATH_KEY_PASSWORD were not all valid.",
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "com.riccardopinato.trail_path"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.riccardopinato.trail_path"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("storeRelease") {
            if (hasStoreSigning) {
                storeFile = file(checkNotNull(storeFilePath))
                storePassword = checkNotNull(storePasswordValue)
                keyAlias = checkNotNull(keyAliasValue)
                keyPassword = checkNotNull(keyPasswordValue)
            }
        }
    }

    buildTypes {
        release {
            // AppLab/CI APKs may use the debug key when store credentials are
            // intentionally absent. Store builds set
            // TRAILPATH_REQUIRE_STORE_SIGNING=true and fail closed.
            signingConfig =
                if (hasStoreSigning) {
                    signingConfigs.getByName("storeRelease")
                } else {
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
