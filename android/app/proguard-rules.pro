# Flutter/plugin consumer rules are merged automatically.
# Keep native MapLibre entry points that may be reached through JNI/reflection.
-keep class org.maplibre.** { *; }
-dontwarn org.maplibre.**
