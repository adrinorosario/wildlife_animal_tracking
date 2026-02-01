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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureNamespace = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val namespaceMethod = android.javaClass.getMethod("getNamespace")
                if (namespaceMethod.invoke(android) == null) {
                    val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    var packageName = "com.example.${project.name.replace("-", "_")}"
                    if (project.name == "flutter_config_plus") {
                        packageName = "com.chaunguyen.flutter_config_plus"
                    }
                    setNamespaceMethod.invoke(android, packageName)
                    println("Set namespace for ${project.name} to $packageName")
                }
            } catch (e: Exception) {
                // ignore
            }
        }
    }
    
    if (project.state.executed) {
        configureNamespace()
    } else {
        afterEvaluate { configureNamespace() }
    }
}
