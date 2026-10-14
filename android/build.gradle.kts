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

// Solo in CI: compila le librerie native dei plugin per le sole ABI indicate,
// invece delle tre che dichiarano (arm64-v8a, armeabi-v7a, x86_64).
System.getenv("ROKKO_NATIVE_ABIS")?.takeIf { it.isNotBlank() }?.let { abis ->
    subprojects {
        afterEvaluate {
            extensions
                .findByType(com.android.build.api.dsl.LibraryExtension::class.java)
                ?.defaultConfig
                ?.ndk
                ?.abiFilters
                ?.apply {
                    clear()
                    addAll(abis.split(",").map { it.trim() })
                }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
