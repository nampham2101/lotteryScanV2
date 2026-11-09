# ML Kit text recognition (ticket #16). The Flutter add-on mentions the Chinese,
# Devanagari, Japanese and Korean recognizers but the app only bundles Latin, so
# the release build (R8) must not fail on the missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# The release build (R8) removes the no-argument constructor of ML Kit's
# component registrars, which ML Kit calls by name at start-up, so ML Kit
# starts with no components and crashes on the first read (ticket #20).
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
