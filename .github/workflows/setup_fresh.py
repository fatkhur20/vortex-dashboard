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

    # Pin Gradle to 8.7 (bundles org.gradle.kotlin.kotlin-dsl plugin)
    with open(f"{fresh}/android/gradle/wrapper/gradle-wrapper.properties", "w") as f:
        f.write("""distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.13-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
""")

    # Bump Kotlin plugin version for plugin compatibility
    import re

    KOTLIN_VERSION = "2.2.0"

    def bump_kotlin(content, label=""):
        before = content
        # Kotlin DSL: id("org.jetbrains.kotlin.android") version "X.Y.Z" apply false
        content = re.sub(
            r'(id\s*\(\s*["\']org\.jetbrains\.kotlin\.android["\']\s*\)\s+version\s+["\'])\d+\.\d+\.\d+(["\'])',
            rf'\g<1>{KOTLIN_VERSION}\g<2>',
            content
        )
        # Groovy: id "org.jetbrains.kotlin.android" version "X.Y.Z" apply false
        content = re.sub(
            r'(id\s+["\']org\.jetbrains\.kotlin\.android["\']\s+version\s+["\'])\d+\.\d+\.\d+(["\'])',
            rf'\g<1>{KOTLIN_VERSION}\g<2>',
            content
        )
        # Groovy: ext.kotlin_version = 'X.Y.Z'
        content = re.sub(
            r"(ext\.kotlin_version\s*=\s*['\"])\d+\.\d+\.\d+(['\"])",
            rf'\g<1>{KOTLIN_VERSION}\g<2>',
            content
        )
        # Version catalog (libs.versions.toml): kotlin = "X.Y.Z"
        content = re.sub(
            r'(^kotlin\s*=\s*["\'])\d+\.\d+\.\d+(["\'])',
            rf'\g<1>{KOTLIN_VERSION}\g<2>',
            content,
            flags=re.MULTILINE
        )
        # Check if anything changed
        changed = False
        for i, (a, b) in enumerate(zip(before.splitlines(), content.splitlines())):
            if a != b:
                changed = True
                print(f"[bump_kotlin:{label}] L{i+1}: {a} -> {b}")
        if not changed:
            print(f"[bump_kotlin:{label}] NO CHANGES (pattern didn't match)")
        return content

    # Flutter 3.29+ uses .kts (Kotlin DSL), earlier versions use .gradle (Groovy)
    for fn in [
        f"{fresh}/android/settings.gradle.kts",
        f"{fresh}/android/settings.gradle",
        f"{fresh}/android/build.gradle.kts",
        f"{fresh}/android/build.gradle",
        f"{fresh}/android/app/build.gradle.kts",
        f"{fresh}/android/app/build.gradle",
    ]:
        if os.path.exists(fn):
            with open(fn) as f:
                content = f.read()
            content = bump_kotlin(content, label=os.path.basename(fn))
            with open(fn, "w") as f:
                f.write(content)

    # Also patch version catalog if present
    toml = f"{fresh}/android/gradle/libs.versions.toml"
    if os.path.exists(toml):
        with open(toml) as f:
            content = f.read()
        content = bump_kotlin(content, label="libs.versions.toml")
        with open(toml, "w") as f:
            f.write(content)

    # Force Kotlin compiler version via gradle.properties
    gradle_props = f"{fresh}/android/gradle.properties"
    with open(gradle_props, "a") as f:
        f.write(f"\n# Force Kotlin compiler version\nkotlin.code.style=official\norg.gradle.jvmargs=-Xmx4g\n")

    # Print debug info about generated files
    print("=== Generated android/ files ===")
    for root, dirs, files in os.walk(f"{fresh}/android"):
        rel = os.path.relpath(root, fresh)
        for fn in sorted(files):
            if fn.endswith(".gradle") or fn.endswith(".kts") or fn in ("gradle.properties", "libs.versions.toml"):
                print(f"  {rel}/{fn}")
    for fn in [
        f"{fresh}/android/settings.gradle.kts",
        f"{fresh}/android/settings.gradle",
        f"{fresh}/android/build.gradle.kts",
        f"{fresh}/android/app/build.gradle.kts",
        f"{fresh}/android/gradle/libs.versions.toml",
    ]:
        if os.path.exists(fn):
            with open(fn) as f:
                content = f.read()
            print(f"--- {fn} ---")
            print(content)
            print(f"--- end {fn} ---")

    # Global init script as safety net for Flutter SDK internal Gradle files
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
