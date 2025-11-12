plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.tuturno.app"
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
        applicationId = "com.tuturno.app"
        minSdk = 26
        targetSdk = 35
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // Firma temporal para poder compilar -- cámbialo cuando tengas tu keystore
            signingConfig = signingConfigs.getByName("debug")

            // Activa minify + shrink para release
            isMinifyEnabled = true
            isShrinkResources = true

            // Usa reglas por defecto + tus reglas locales (crea android/app/proguard-rules.pro)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // Mantén debug sin minificación
            isMinifyEnabled = false
        }
    }

    // (Opcional) Si alguna lib trae archivos duplicados en META-INF, destápalo:
    // packaging {
    //     resources {
    //         excludes += setOf(
    //             "META-INF/DEPENDENCIES",
    //             "META-INF/LICENSE",
    //             "META-INF/LICENSE.txt",
    //             "META-INF/NOTICE",
    //             "META-INF/NOTICE.txt"
    //         )
    //     }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM — alinea versiones de Firebase nativo
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    // (No necesitas declarar explícitamente ML Kit/TFLite aquí;
    // las dependencias las arrastran los paquetes Flutter que ya agregaste.)
}
