# Add project specific ProGuard rules here.

# Keep all classes from Vanstone SDK (POS device SDK)
-keep class com.vanstone.** { *; }
-dontwarn com.vanstone.**

# Ignore missing JPOS classes (not needed for this SDK)
-dontwarn org.jpos.**
-dontwarn jdbm.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter wrapper classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep method channel classes
-keep class com.example.fuels_app.MainActivity { *; }
-keep class com.example.fuels_app.SplashActivity { *; }

# Keep all reflection-based classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson rules (if using JSON serialization)
-keepattributes Signature
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep crash reporting
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Telephony Manager (for IMEI reading)
-keep class android.telephony.TelephonyManager { *; }
-dontwarn android.telephony.**

# Printer API and POS SDK
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
