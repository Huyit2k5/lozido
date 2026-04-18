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
    // Fix namespace for old plugins (runs when plugin is applied)
    plugins.withId("com.android.library") {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        if (android != null && android.namespace.isNullOrEmpty()) {
            val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val pkg = Regex("""package\s*=\s*"([^"]+)"""").find(manifest.readText())?.groupValues?.get(1)
                if (!pkg.isNullOrEmpty()) {
                    android.namespace = pkg
                }
            }
        }
    }
    // afterEvaluate: override JVM targets AFTER plugin's build.gradle has been processed
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            android?.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
