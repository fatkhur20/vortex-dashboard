"""Set up the fresh Flutter project for CI build."""
import os
import subprocess
import sys

def run(cmd):
    print(f"+ {cmd}")
    subprocess.check_call(cmd, shell=True)

def main():
    fresh = sys.argv[1]
    run(f"flutter create --org com.vortex --project-name vortex_dashboard --platforms android {fresh}")

    # Pin Gradle to 8.7
    with open(f"{fresh}/android/gradle/wrapper/gradle-wrapper.properties", "w") as f:
        f.write("""distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
""")

    # Add Gradle Plugin Portal to project settings
    with open(f"{fresh}/android/settings.gradle.kts", "w") as f:
        f.write("""pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
rootProject.name = "vortex_dashboard"
include(":app")
""")

    # Global init script for Flutter SDK internal Gradle files
    gradle_home = os.path.expanduser("~/.gradle")
    os.makedirs(gradle_home, exist_ok=True)
    with open(f"{gradle_home}/init.gradle", "w") as f:
        f.write("""settingsEvaluated { settings ->
    settings.pluginManagement {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }
}
""")

if __name__ == "__main__":
    main()
