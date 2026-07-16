plugins {
    id("com.android.application")
}

android {
    namespace = "io.github.daylight00.molstarandroid"
    compileSdk = 36

    defaultConfig {
        applicationId = "io.github.daylight00.molstarandroid"
        minSdk = 24
        targetSdk = 36
        versionCode = 5
        versionName = "0.1.4"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    implementation("androidx.webkit:webkit:1.16.0")
}
