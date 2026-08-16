import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenziali della chiave di firma, lette da android/key.properties.
//
// Il file non è versionato: contiene la password del keystore. Chi clona il
// progetto deve ricrearlo, oppure potrà produrre solo build di debug.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "it.tndigit.clinical_results"

    // Segue la versione indicata da Flutter.
    //
    // L'SDK installato contiene la piattaforma 37 in una cartella chiamata
    // "android-37.0", mentre Gradle la cerca come "android-37". Si è creata
    // una giunzione con il nome atteso:
    //
    //   mklink /J "%LOCALAPPDATA%\Android\Sdk\platforms\android-37" ^
    //             "%LOCALAPPDATA%\Android\Sdk\platforms\android-37.0"
    //
    // Va rifatta su una macchina nuova finché l'SDK non sarà allineato.
    // Fissare qui la 36 non è un'alternativa: alcuni plugin, fra cui
    // flutter_secure_storage, richiedono la 37 e la build release fallisce.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "it.tndigit.clinical_results"
        // ML Kit richiede almeno il livello 21.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // Le librerie native vengono estratte su disco all'installazione.
            //
            // Con il comportamento predefinito restano compresse dentro l'APK
            // e il linker le carica direttamente da lì, ma solo se allineate
            // alla dimensione di pagina del dispositivo. Su Android 15 e
            // successivi, dove le pagine sono da 16 KB, `libsqlite3mc.so` non
            // risulta caricabile e il database cifrato non si apre affatto:
            // verificato su un dispositivo Android 16, dove la cartella delle
            // librerie installate risultava vuota e `dlopen` falliva.
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Nessun ripiego silenzioso sulle chiavi di debug.
            //
            // Un APK firmato con una chiave diversa non può aggiornare quello
            // installato: va disinstallato, e disinstallando si perdono i dati
            // e le voci del portachiavi che aprono il database cifrato. Meglio
            // che la build si fermi, piuttosto che produrre un pacchetto che
            // a un certo punto costringerà a cancellare l'archivio.
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Manca android/key.properties: senza la chiave di firma " +
                    "non è possibile produrre una release installabile in " +
                    "aggiornamento. Vedere README, sezione Firma."
                )
            }
            signingConfig = signingConfigs.getByName("release")

            // Regole aggiuntive per R8: senza, la minificazione si interrompe
            // sui riconoscitori ML Kit non inclusi.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
