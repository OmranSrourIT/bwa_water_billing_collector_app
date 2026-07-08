import java.io.File

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use {
                properties.load(it)
            }

            val flutterSdkPath =
                properties.getProperty("flutter.sdk")

            require(flutterSdkPath != null) {
                "flutter.sdk not set in local.properties"
            }

            flutterSdkPath
        }

    includeBuild(
        "$flutterSdkPath/packages/flutter_tools/gradle"
    )

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

dependencyResolutionManagement {

  repositoriesMode.set(
    RepositoriesMode.PREFER_PROJECT
)

    repositories {

        google()
        mavenCentral()

        maven {

            name = "MineSecMaven"

            url = uri(
                "https://maven.pkg.github.com/theminesec/ms-registryclient"
            )

            credentials {

                val props = java.util.Properties()

                val gradlePropsFile = File(
                    System.getProperty("user.home"),
                    ".gradle/gradle.properties"
                )

                if (gradlePropsFile.exists()) {
                    gradlePropsFile.inputStream().use {
                        props.load(it)
                    }
                }

                username =
                    props.getProperty(
                        "MINESEC_REGISTRY_LOGIN"
                    )

                password =
                    props.getProperty(
                        "MINESEC_REGISTRY_TOKEN"
                    )
            }
        }
    }
}

include(":app")
