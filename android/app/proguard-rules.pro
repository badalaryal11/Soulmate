# Project specific ProGuard rules.
# Keep this file even if empty because it is referenced by build.gradle.kts.
#
# Add keep rules here only when minification removes required classes.

# --- Google Sign-In / Google Play Services Auth ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }

# --- Firebase Auth ---
-keep class com.google.firebase.auth.** { *; }

# --- Google Identity Services (newer credential manager path) ---
-keep class com.google.android.libraries.identity.** { *; }

# --- Keep GoogleSignIn plugin classes ---
-keep class io.flutter.plugins.googlesignin.** { *; }

# --- Prevent R8 from stripping error/exception classes needed at runtime ---
-keep class com.google.android.gms.common.api.ApiException { *; }
-keep class com.google.android.gms.common.api.Status { *; }

# --- Keep Credential Manager classes (used by newer google_sign_in versions) ---
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.credentials.** { *; }
