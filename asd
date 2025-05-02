[1mdiff --git a/android/app/build.gradle.kts b/android/app/build.gradle.kts[m
[1mindex b95c9f3..d6b5aa2 100644[m
[1m--- a/android/app/build.gradle.kts[m
[1m+++ b/android/app/build.gradle.kts[m
[36m@@ -1,38 +1,66 @@[m
[32m+[m[32m// Thêm plugin google-services và kotlin-android ở đầu[m
 plugins {[m
[31m-    id("com.android.application")[m
[31m-    // START: FlutterFire Configuration[m
[31m-    id("com.google.gms.google-services")  // Bổ sung Google Services plugin[m
[31m-    // END: FlutterFire Configuration[m
[31m-    id("kotlin-android")[m
[31m-    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.[m
[31m-    id("dev.flutter.flutter-gradle-plugin")[m
[32m+[m[32m    id "com.android.application"[m
[32m+[m[32m    id "kotlin-android"[m
[32m+[m[32m    id "com.google.gms.google-services" // Thêm plugin google-services[m
[32m+[m[32m    id "dev.flutter.flutter-gradle-plugin"[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mdef localProperties = new Properties()[m
[32m+[m[32mdef localPropertiesFile = rootProject.file('local.properties')[m
[32m+[m[32mif (localPropertiesFile.exists()) {[m
[32m+[m[32m    localPropertiesFile.withReader('UTF-8') { reader ->[m
[32m+[m[32m        localProperties.load(reader)[m
[32m+[m[32m    }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mdef flutterVersionCode = localProperties.getProperty('flutter.versionCode')[m
[32m+[m[32mif (flutterVersionCode == null) {[m
[32m+[m[32m    flutterVersionCode = '1'[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mdef flutterVersionName = localProperties.getProperty('flutter.versionName')[m
[32m+[m[32mif (flutterVersionName == null) {[m
[32m+[m[32m    flutterVersionName = '1.0'[m
 }[m
 [m
 android {[m
     namespace = "com.example.workmanagement"[m
     compileSdk = flutter.compileSdkVersion[m
[31m-    ndkVersion = "27.0.12077973"[m
[32m+[m[32m    ndkVersion = flutter.ndkVersion[m
 [m
     compileOptions {[m
[31m-        sourceCompatibility = JavaVersion.VERSION_11[m
[31m-        targetCompatibility = JavaVersion.VERSION_11[m
[32m+[m[32m        coreLibraryDesugaringEnabled = true // Bật Desugaring[m
[32m+[m[32m        sourceCompatibility = JavaVersion.VERSION_1_8 // Đặt Java 8[m
[32m+[m[32m        targetCompatibility = JavaVersion.VERSION_1_8 // Đặt Java 8[m
     }[m
 [m
     kotlinOptions {[m
[31m-        jvmTarget = JavaVersion.VERSION_11.toString()[m
[32m+[m[32m        jvmTarget = '1.8' // Đặt Java 8[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    sourceSets {[m
[32m+[m[32m        main.java.srcDirs += 'src/main/kotlin'[m
     }[m
 [m
     defaultConfig {[m
         applicationId = "com.example.workmanagement"[m
[31m-        minSdkVersion(23)[m
[32m+[m[32m        minSdk = 23 // flutter.minSdkVersion[m
         targetSdk = flutter.targetSdkVersion[m
[31m-        versionCode = flutter.versionCode[m
[31m-        versionName = flutter.versionName[m
[32m+[m[32m        versionCode = flutterVersionCode.toInteger()[m
[32m+[m[32m        versionName = flutterVersionName[m
[32m+[m[32m        multiDexEnabled = true // Bật MultiDex[m
     }[m
 [m
[32m+[m[32m     signingConfigs { // Đảm bảo có khối này[m
[32m+[m[32m         debug {[m
[32m+[m[32m            // Flutter tự quản lý debug signing[m
[32m+[m[32m         }[m
[32m+[m[32m     }[m
[32m+[m
     buildTypes {[m
         release {[m
[31m-            signingConfig = signingConfigs.getByName("debug")[m
[32m+[m[32m            signingConfig = signingConfigs.debug // Sử dụng debug key cho release (NÊN THAY BẰNG KEY RIÊNG)[m
         }[m
     }[m
 }[m
[36m@@ -41,5 +69,9 @@[m [mflutter {[m
     source = "../.."[m
 }[m
 [m
[31m-// Bổ sung plugin Firebase[m
[31m-apply(plugin = "com.google.gms.google-services")  // Áp dụng Google Services plugin ở đây[m
[32m+[m[32mdependencies {[m
[32m+[m[32m    implementation platform('com.google.firebase:firebase-bom:33.1.1') // Firebase BOM[m
[32m+[m[32m    implementation 'com.google.firebase:firebase-analytics' // Analytics (nếu dùng)[m
[32m+[m
[32m+[m[32m    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' // Dependency Desugaring (dùng 2.1.4)[m
[32m+[m[32m}[m
\ No newline at end of file[m
[1mdiff --git a/android/app/google-services.json b/android/app/google-services.json[m
[1mdeleted file mode 100644[m
[1mindex 72cb125..0000000[m
[1m--- a/android/app/google-services.json[m
[1m+++ /dev/null[m
[36m@@ -1,62 +0,0 @@[m
[31m-{[m
[31m-  "project_info": {[m
[31m-    "project_number": "362988978831",[m
[31m-    "project_id": "mobileapp-33dc4",[m
[31m-    "storage_bucket": "mobileapp-33dc4.firebasestorage.app"[m
[31m-  },[m
[31m-  "client": [[m
[31m-    {[m
[31m-      "client_info": {[m
[31m-        "mobilesdk_app_id": "1:362988978831:android:49355f5c486769eb55a6fa",[m
[31m-        "android_client_info": {[m
[31m-          "package_name": "com.example.workmanagement"[m
[31m-        }[m
[31m-      },[m
[31m-      "oauth_client": [[m
[31m-        {[m
[31m-          "client_id": "362988978831-0ofpms3uhtcg22tdusvu4457rcgrsm26.apps.googleusercontent.com",[m
[31m-          "client_type": 1,[m
[31m-          "android_info": {[m
[31m-            "package_name": "com.example.workmanagement",[m
[31m-            "certificate_hash": "fecafbfaa50a965df597e0edacfd235c7d5c4df1"[m
[31m-          }[m
[31m-        },[m
[31m-        {[m
[31m-          "client_id": "362988978831-jj9p8duef6adaa22h2fptlu53stgrred.apps.googleusercontent.com",[m
[31m-          "client_type": 1,[m
[31m-          "android_info": {[m
[31m-            "package_name": "com.example.workmanagement",[m
[31m-            "certificate_hash": "a9273f60f38e50515a777b2edea16cc5999a1f6c"[m
[31m-          }[m
[31m-        },[m
[31m-        {[m
[31m-          "client_id": "362988978831-voi2t7tnkoitlm9h54n1hbmpv29hdpc9.apps.googleusercontent.com",[m
[31m-          "client_type": 3[m
[31m-        }[m
[31m-      ],[m
[31m-      "api_key": [[m
[31m-        {[m
[31m-          "current_key": "AIzaSyC_S9LbXhCO5OlWuyomecsaJTycNafvFGY"[m
[31m-        }[m
[31m-      ],[m
[31m-      "services": {[m
[31m-        "appinvite_service": {[m
[31m-          "other_platform_oauth_client": [[m
[31m-            {[m
[31m-              "client_id": "362988978831-voi2t7tnkoitlm9h54n1hbmpv29hdpc9.apps.googleusercontent.com",[m
[31m-              "client_type": 3[m
[31m-            },[m
[31m-            {[m
[31m-              "client_id": "362988978831-g8ng57gujc20t7b7tmko2pjrqisbqe7f.apps.googleusercontent.com",[m
[31m-              "client_type": 2,[m
[31m-              "ios_info": {[m
[31m-                "bundle_id": "com.example.workmanagement"[m
[31m-              }[m
[31m-            }[m
[31m-          ][m
[31m-        }[m
[31m-      }[m
[31m-    }[m
[31m-  ],[m
[31m-  "configuration_version": "1"[m
[31m-}[m
\ No newline at end of file[m
[1mdiff --git a/android/app/src/main/AndroidManifest.xml b/android/app/src/main/AndroidManifest.xml[m
[1mindex 444eb70..5ffe67d 100644[m
[1m--- a/android/app/src/main/AndroidManifest.xml[m
[1m+++ b/android/app/src/main/AndroidManifest.xml[m
[36m@@ -1,45 +1,38 @@[m
 <manifest xmlns:android="http://schemas.android.com/apk/res/android">[m
[31m-    <application[m
[31m-        android:label="workmanagement"[m
[31m-        android:name="${applicationName}"[m
[31m-        android:icon="@mipmap/ic_launcher">[m
[31m-        <activity[m
[31m-            android:name=".MainActivity"[m
[31m-            android:exported="true"[m
[31m-            android:launchMode="singleTop"[m
[31m-            android:taskAffinity=""[m
[31m-            android:theme="@style/LaunchTheme"[m
[31m-            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"[m
[31m-            android:hardwareAccelerated="true"[m
[31m-            android:windowSoftInputMode="adjustResize">[m
[31m-            <!-- Specifies an Android theme to apply to this Activity as soon as[m
[32m+[m[32m<application android:label="workmanagement" android:name="${applicationName}" android:icon="@mipmap/ic_launcher">[m
[32m+[m[32m<activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:taskAffinity="" android:theme="@style/LaunchTheme" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode" android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">[m
[32m+[m[32m<!--  Specifies an Android theme to apply to this Activity as soon as[m
                  the Android process has started. This theme is visible to the user[m
                  while the Flutter UI initializes. After that, this theme continues[m
[31m-                 to determine the Window background behind the Flutter UI. -->[m
[31m-            <meta-data[m
[31m-              android:name="io.flutter.embedding.android.NormalTheme"[m
[31m-              android:resource="@style/NormalTheme"[m
[31m-              />[m
[31m-            <intent-filter>[m
[31m-                <action android:name="android.intent.action.MAIN"/>[m
[31m-                <category android:name="android.intent.category.LAUNCHER"/>[m
[31m-            </intent-filter>[m
[31m-        </activity>[m
[31m-        <!-- Don't delete the meta-data below.[m
[31m-             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->[m
[31m-        <meta-data[m
[31m-            android:name="flutterEmbedding"[m
[31m-            android:value="2" />[m
[31m-    </application>[m
[31m-    <!-- Required to query activities that can process text, see:[m
[32m+[m[32m                 to determine the Window background behind the Flutter UI.  -->[m
[32m+[m[32m<meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme"/>[m
[32m+[m[32m<intent-filter>[m
[32m+[m[32m<action android:name="android.intent.action.MAIN"/>[m
[32m+[m[32m<category android:name="android.intent.category.LAUNCHER"/>[m
[32m+[m[32m</intent-filter>[m
[32m+[m[32m</activity>[m
[32m+[m[32m<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>[m
[32m+[m[32m<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">[m
[32m+[m[32m<intent-filter>[m
[32m+[m[32m<action android:name="android.intent.action.BOOT_COMPLETED"/>[m
[32m+[m[32m<action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>[m
[32m+[m[32m<action android:name="android.intent.action.QUICKBOOT_POWERON"/>[m
[32m+[m[32m<action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>[m
[32m+[m[32m</intent-filter>[m
[32m+[m[32m</receiver>[m
[32m+[m[32m<!--  Don't delete the meta-data below.[m
[32m+[m[32m             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java  -->[m
[32m+[m[32m<meta-data android:name="flutterEmbedding" android:value="2"/>[m
[32m+[m[32m</application>[m
[32m+[m[32m<!--  Required to query activities that can process text, see:[m
          https://developer.android.com/training/package-visibility and[m
          https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.[m
 [m
[31m-         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->[m
[31m-    <queries>[m
[31m-        <intent>[m
[31m-            <action android:name="android.intent.action.PROCESS_TEXT"/>[m
[31m-            <data android:mimeType="text/plain"/>[m
[31m-        </intent>[m
[31m-    </queries>[m
[31m-</manifest>[m
[32m+[m[32m         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin.  -->[m
[32m+[m[32m<queries>[m
[32m+[m[32m<intent>[m
[32m+[m[32m<action android:name="android.intent.action.PROCESS_TEXT"/>[m
[32m+[m[32m<data android:mimeType="text/plain"/>[m
[32m+[m[32m</intent>[m
[32m+[m[32m</queries>[m
[32m+[m[32m</manifest>[m
\ No newline at end of file[m
[1mdiff --git a/android/build.gradle.kts b/android/build.gradle.kts[m
[1mindex dbc24ca..4897f91 100644[m
[1m--- a/android/build.gradle.kts[m
[1m+++ b/android/build.gradle.kts[m
[36m@@ -1,3 +1,17 @@[m
[32m+[m[32m// Top-level build file where you can add configuration options common to all sub-projects/modules.[m
[32m+[m[32mbuildscript {[m
[32m+[m[32m    ext.kotlin_version = '1.8.22' // <--- Đặt phiên bản Kotlin ở đây (thử 1.8.22 trước)[m
[32m+[m[32m    repositories {[m
[32m+[m[32m        google()[m
[32m+[m[32m        mavenCentral()[m
[32m+[m[32m    }[m
[32m+[m[32m    dependencies {[m
[32m+[m[32m        classpath 'com.android.tools.build:gradle:7.4.2' // <-- Đặt phiên bản AGP tương thích[m
[32m+[m[32m        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"[m
[32m+[m[32m        classpath 'com.google.gms:google-services:4.4.1' // <-- Classpath cho google-services[m
[32m+[m[32m    }[m
[32m+[m[32m}[m
[32m+[m
 allprojects {[m
     repositories {[m
         google()[m
[36m@@ -5,30 +19,18 @@[m [mallprojects {[m
     }[m
 }[m
 [m
[31m-val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()[m
[31m-rootProject.layout.buildDirectory.value(newBuildDir)[m
[32m+[m[32m// Xóa hoặc giữ lại các khối tùy chỉnh nếu bạn cần (newBuildDir, subprojects, clean)[m
[32m+[m[32m// Ví dụ giữ lại:[m
[32m+[m[32mdef newBuildDir = new File(rootProject.buildDir.parentFile, "build")[m
[32m+[m[32mrootProject.buildDir = newBuildDir[m
 [m
 subprojects {[m
[31m-    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)[m
[31m-    project.layout.buildDirectory.value(newSubprojectBuildDir)[m
[32m+[m[32m    project.buildDir = "${rootProject.buildDir}/${project.name}"[m
 }[m
[31m-[m
 subprojects {[m
[31m-    project.evaluationDependsOn(":app")[m
[32m+[m[32m    project.evaluationDependsOn(':app')[m
 }[m
 [m
[31m-tasks.register<Delete>("clean") {[m
[31m-    delete(rootProject.layout.buildDirectory)[m
[31m-}[m
[31m-[m
[31m-// Bổ sung classpath cho google-services plugin[m
[31m-buildscript {[m
[31m-    repositories {[m
[31m-        google()[m
[31m-        mavenCentral()[m
[31m-    }[m
[31m-    dependencies {[m
[31m-        // Thêm classpath cho google-services plugin[m
[31m-        classpath("com.google.gms:google-services:4.3.10")  // Thêm dòng này[m
[31m-    }[m
[31m-}[m
[32m+[m[32mtasks.register("clean", Delete) {[m
[32m+[m[32m    delete rootProject.buildDir[m
[32m+[m[32m}[m
\ No newline at end of file[m
[1mdiff --git a/android/gradle.properties b/android/gradle.properties[m
[1mindex eeb9d9d..f018a61 100644[m
[1m--- a/android/gradle.properties[m
[1m+++ b/android/gradle.properties[m
[36m@@ -1,4 +1,3 @@[m
 org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError[m
 android.useAndroidX=true[m
 android.enableJetifier=true[m
[31m-org.gradle.java.home=C:/Program Files/Eclipse Adoptium/jdk-17.0.15.6-hotspot[m
\ No newline at end of file[m
[1mdiff --git a/android/settings.gradle.kts b/android/settings.gradle.kts[m
[1mindex 9e2d35c..a439442 100644[m
[1m--- a/android/settings.gradle.kts[m
[1m+++ b/android/settings.gradle.kts[m
[36m@@ -19,9 +19,6 @@[m [mpluginManagement {[m
 plugins {[m
     id("dev.flutter.flutter-plugin-loader") version "1.0.0"[m
     id("com.android.application") version "8.7.0" apply false[m
[31m-    // START: FlutterFire Configuration[m
[31m-    id("com.google.gms.google-services") version("4.3.15") apply false[m
[31m-    // END: FlutterFire Configuration[m
     id("org.jetbrains.kotlin.android") version "1.8.22" apply false[m
 }[m
 [m
