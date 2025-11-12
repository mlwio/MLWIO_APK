pluginManagement {
    val properties = java.util.Properties()
    val flutterSdkPath: String? = runCatching {
        val localProps = file("local.properties")
        if (localProps.exists()) {
            localProps.inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")
        } else null
    }.getOrNull() ?: System.getenv("FLUTTER_SDK")

    val flutterGradleDir = flutterSdkPath?.let { "$it/packages/flutter_tools/gradle" }
    if (flutterGradleDir != null && file(flutterGradleDir).exists()) {
        includeBuild(flutterGradleDir)
    } else {
        println("[settings.gradle] Warning: Flutter SDK gradle tooling not found. Using plugin portal.")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
