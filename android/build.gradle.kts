allprojects {
    repositories {
        google()
        mavenCentral()

        maven {
            name = "MineSecMaven"
            url = uri(
                "https://maven.pkg.github.com/theminesec/ms-registryclient"
            )

            credentials {
                username =
                    project.findProperty(
                        "MINESEC_REGISTRY_LOGIN"
                    ) as String?

                password =
                    project.findProperty(
                        "MINESEC_REGISTRY_TOKEN"
                    ) as String?
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(
    newBuildDir
)

subprojects {

    repositories {
        google()
        mavenCentral()

        maven {
            name = "MineSecMaven"
            url = uri(
                "https://maven.pkg.github.com/theminesec/ms-registryclient"
            )

            credentials {
                username =
                    project.findProperty(
                        "MINESEC_REGISTRY_LOGIN"
                    ) as String?

                password =
                    project.findProperty(
                        "MINESEC_REGISTRY_TOKEN"
                    ) as String?
            }
        }
    }

    val newSubprojectBuildDir =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(
        newSubprojectBuildDir
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
