# Project specific ProGuard rules.
# Keep this file even if empty because it is referenced by build.gradle.kts.
#
# Add keep rules here only when minification removes required classes.

# ============================================================
# google_sign_in_android v7+ uses AndroidX Credential Manager
# + Google Identity Services. All of the following are required
# for release builds.
# ============================================================

# --- AndroidX Credential Manager (core API) ---
-keep class androidx.credentials.** { *; }
-keepclassmembers class androidx.credentials.** { *; }

# --- AndroidX Credential Manager Play Services backend ---
# This is the actual provider that fulfills credential requests on most
# devices. R8 strips it because it's loaded via reflection/service-loader.
-keep class androidx.credentials.playservices.** { *; }
-keepclassmembers class androidx.credentials.playservices.** { *; }

# --- Google Identity / GoogleId (credential types) ---
# GoogleIdTokenCredential, GetGoogleIdOption, GetSignInWithGoogleOption
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keepclassmembers class com.google.android.libraries.identity.googleid.** { *; }

# --- Google Identity Services (Authorization / Identity API) ---
-keep class com.google.android.gms.auth.api.identity.** { *; }

# --- Google Play Services Auth (legacy, still used for scopes) ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }

# --- Prevent R8 from stripping error/exception classes needed at runtime ---
-keep class com.google.android.gms.common.api.ApiException { *; }
-keep class com.google.android.gms.common.api.Status { *; }

# --- Firebase Auth ---
-keep class com.google.firebase.auth.** { *; }

# --- Flutter Google Sign-In plugin classes ---
-keep class io.flutter.plugins.googlesignin.** { *; }

# --- credential_manager plugin (used for One-Tap / saved passwords) ---
-keep class com.google.android.libraries.credentials.** { *; }

# --- Keep Kotlin Result and Function types used in plugin callbacks ---
-keep class kotlin.Result { *; }
-keep class kotlin.jvm.functions.** { *; }

# --- Prevent R8 from optimizing away classes accessed via Bundle/getData() ---
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * extends com.google.android.libraries.identity.googleid.GoogleIdTokenCredential {
    *;
}
