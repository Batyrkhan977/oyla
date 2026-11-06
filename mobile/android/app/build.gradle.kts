plugins { id("com.android.application"); id("kotlin-android"); id("dev.flutter.flutter-gradle-plugin") }
android {
    namespace = "com.oyla.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig { applicationId = "com.oyla.app"; minSdk = 24; targetSdk = flutter.targetSdkVersion; versionCode = flutter.versionCode; versionName = flutter.versionName }
    buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
}
flutter { source = "../.." }

dependencies {
    implementation("com.pierfrancescosoffritti.androidyoutubeplayer:core:13.0.0")
    implementation("com.google.mlkit:digital-ink-recognition:19.0.0")
}
