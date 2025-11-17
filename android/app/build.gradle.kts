plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.najatak"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // دعم Java 8+ features
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.najatak"
        // minSdk 23 للتوافق مع الإشعارات
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // دعم المناطق الزمنية والإشعارات
        multiDexEnabled = true
    }
   
    buildTypes {
        release {
            // استخدام release signing في الإصدار النهائي
            signingConfig = signingConfigs.getByName("debug")
            
            // تحسينات للإصدار النهائي
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // إعدادات التطوير
            isDebuggable = true
        }
    }

    // دعم Kotlin وJava الحديثة
    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0"
            )
        }
    }
}

dependencies {
    // مكتبة Java 8+ desugaring للتوافق
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // MultiDex للتطبيقات الكبيرة
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
