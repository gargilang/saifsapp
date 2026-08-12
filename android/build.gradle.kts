allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Paksa semua modul (app + plugin) memakai build-tools yang lengkap di cache lokal
// (host Android Maven lambat; hindari auto-download revisi 36.0.0).
subprojects {
    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
            buildToolsVersion = "36.1.0"
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            buildToolsVersion = "36.1.0"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
