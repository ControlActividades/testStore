# Mantener todas las clases de la aplicación
-keep class com.example.aplicacion2.** { *; }

# Mantener clases de bibliotecas como Gson, Retrofit, etc.
-keep class com.google.gson.** { *; }
-keep class retrofit2.** { *; }

# Evitar eliminar anotaciones de bibliotecas
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
