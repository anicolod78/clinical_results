# Regole di offuscamento per la build release.

# ---------------------------------------------------------------------------
# ML Kit — riconoscitori di scrittura non inclusi
# ---------------------------------------------------------------------------
# Il plugin google_mlkit_text_recognition può usare cinque alfabeti, e li
# referenzia tutti. Nel progetto è incluso solo quello latino, l'unico che
# serve per i referti italiani: gli altri quattro non sono fra le dipendenze
# e R8 interrompe la compilazione trovandoli mancanti.
#
# Le assenze sono volute. Includere anche gli altri alfabeti aggiungerebbe
# decine di megabyte di modelli per una capacità che non verrebbe mai usata.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Il riconoscitore latino viene raggiunto per riflessione dal codice del
# plugin: senza questa regola l'offuscamento ne rinominerebbe le classi e il
# riconoscimento fallirebbe solo nella build release, non in quella di debug.
-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text** { *; }
