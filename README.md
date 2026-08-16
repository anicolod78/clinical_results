# Risultati clinici

Archivio personale di referti di laboratorio. Acquisisce un referto da PDF,
galleria o fotocamera, ne estrae i singoli valori e li rende confrontabili nel
tempo, in tabella e in grafico.

Piattaforme: **Android** (destinazione principale) e **Web** (per le prove).

---

## Come sono protetti i dati

I referti sono dati sanitari. L'impianto di sicurezza è il seguente.

**Il database è cifrato per intero**, non campo per campo. Si usa la build
[SQLite3 Multiple Ciphers](https://github.com/utelle/SQLite3MultipleCiphers),
selezionata nel `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

È l'unica variante disponibile sia come libreria nativa sia come modulo
WebAssembly, quindi la protezione è la stessa sulle due piattaforme.

> Nota: `sqlcipher_flutter_libs` **non** va usato. Dalla versione 0.7.0 è un
> pacchetto vuoto, rimasto solo per impedire alle vecchie build script di
> attivarsi.

**Il codice di sicurezza non viene mai memorizzato**, né in chiaro né come
hash. Lo schema è:

1. alla configurazione si genera una chiave dati casuale di 32 byte (DEK);
2. dal PIN si deriva una chiave di protezione con PBKDF2-HMAC-SHA256
   (150.000 iterazioni, sale casuale);
3. la DEK viene incapsulata con AES-256-GCM sotto quella chiave, e solo il
   risultato finisce nell'archivio protetto del sistema.

La verifica del PIN avviene per costruzione: con un codice sbagliato
l'autenticazione GCM fallisce e la chiave non si ottiene. Non esiste alcun
verificatore estraibile dal dispositivo. Cambiare PIN re-incapsula la stessa
DEK, quindi non richiede di ricifrare l'archivio.

**Difesa dai tentativi ripetuti.** Un PIN a sei cifre è un milione di
combinazioni: dopo quattro errori l'attesa raddoppia a ogni tentativo
successivo, fino a un'ora. Il conteggio sta nell'archivio protetto, quindi
riavviare l'app non lo azzera.

**Il riconoscimento del testo avviene sul dispositivo**: ML Kit su Android,
tesseract.js nel browser. Le immagini dei referti non vengono inviate ad alcun
servizio.

**Backup disattivati.** `allowBackup="false"` e regole di esclusione per il
trasferimento su nuovo dispositivo: l'archivio non deve uscire dal dispositivo
su cui è stato creato.

### Stato della verifica

**Android: verificato sul dispositivo.** Su un Android 16 il database creato
dall'app è stato estratto e ispezionato byte per byte: non inizia con
`SQLite format 3` e non contiene in chiaro alcun nome di tabella. È stato
percorso anche l'intero flusso reale — codice, paziente, importazione di un
referto PDF, tabella dei risultati.

Due difetti emersi **solo** sul dispositivo, invisibili ai test e alle build:

- `libsqlite3mc.so` non era caricabile. Con l'impacchettamento predefinito le
  librerie restano dentro l'APK e su Android 15+ (pagine da 16 KB) il linker
  non le carica: la cartella delle librerie installate risultava vuota.
  Risolto con `useLegacyPackaging = true`, che le estrae su disco.
- Cancellare a mano `build/native_assets/` porta Gradle a considerare la
  fusione delle librerie già aggiornata, e l'APK successivo esce **senza**
  `libsqlite3mc.so`. In caso di dubbio, `flutter clean` prima di ricostruire.

**Web: verificato nel browser.** L'archivio IndexedDB è stato letto byte per
byte: non contiene l'intestazione `SQLite format 3` né i nomi delle tabelle in
chiaro, esattamente come su Android.

Il punto delicato è **quale file system virtuale si usa per aprire il
database**. Registrare `IndexedDbFileSystem` e aprire con il VFS predefinito
fa fallire `PRAGMA hexkey` con `Encryption is not supported by the VFS`.
SQLite3 Multiple Ciphers crea però un involucro cifrante attorno a ogni VFS
registrato, con il prefisso `multipleciphers-`: aprendo con quel nome la
cifratura funziona.

Serve `WasmDatabase.opened`, che accetta un database già aperto, perché il
costruttore ordinario non permette di scegliere il VFS:

```dart
final db = sqlite3.open(path, vfs: 'multipleciphers-indexeddb');
db.execute("PRAGMA hexkey = '$hexKey';");
return WasmDatabase.opened(db);
```

Se nessuna via applica la chiave l'apertura non finge: il database viene
aperto in chiaro e la sessione marcata come non cifrata, e le impostazioni
mostrano **"Archivio NON cifrato"** con l'avviso di non inserire dati reali.
Lo stato è sempre visibile in *Impostazioni → Come sono protetti i dati*.

### Altri limiti da conoscere

- Se si dimentica il codice, **i dati non sono recuperabili**. È una
  conseguenza voluta dello schema, non un difetto.
- Su Web il database viene aperto nel contesto principale e non in un web
  worker. `WasmDatabase.open` delega quasi sempre a un worker, e in quel caso
  drift non invoca la funzione di inizializzazione, quindi il `PRAGMA key` non
  verrebbe applicato nemmeno risolvendo il problema del VFS.
- Su Web la derivazione del PIN gira sul thread principale (Flutter Web non ha
  isolate) e blocca l'interfaccia per un paio di secondi allo sblocco.
- L'archivio protetto è configurato con `resetOnError: false`. Il valore
  predefinito cancella il dato quando la decifratura fallisce, e qui il dato è
  l'unica chiave dell'archivio sanitario: meglio un errore visibile che una
  perdita silenziosa.

---

## Estrazione dei valori

Il percorso è: documento → testo → analisi → **revisione dell'utente** →
archivio. Nulla viene salvato senza conferma: su misure di laboratorio un
punto decimale letto male cambia il significato clinico di un valore, e chi
rilegge lo storico mesi dopo non ha modo di accorgersene.

Per i PDF si tenta sempre prima la lettura del livello testo: quando c'è, è
molto più fedele di un riconoscimento ottico.

Il parser (`lib/features/parsing/`) è una macchina a stati riga per riga,
calibrata su referti reali. Casi che gestisce:

| Caso | Esempio |
|---|---|
| Nome e valore incollati | `Leucociti5.0`, `Piastrine180` |
| Trattini Unicode | `S−Colesterolo`, `4.0−10.0` (U+2212) |
| Apici resi con spazi | `x10 9 /L` → `x10^9/L` |
| Valore su tre righe | `Leucociti7.9` / `x10^9/L` / `4.0 - 10.0` |
| Sezione incollata all'esame | `CHIMICA CLINICAS−Colesterolo` |
| Nome spezzato dalla nota di metodo | `S−ALT (Alan. Amino Transf.)(` … |
| Soglie eterogenee | `(4.0−10.0)`, `<15`, `(<= 14.9)`, `Valore desiderabile: <190` |
| Note scambiabili per esami | `Alterata glicemia a digiuno per valori compresi tra 100 e 125…` |

### Riconoscimento da foto

L'estrazione da immagine ha vincoli diversi da quella da PDF, e il parser li
gestisce esplicitamente perché sono emersi provando su una foto reale:

- ML Kit non restituisce righe di tabella ma frammenti con la loro posizione.
  Le colonne vanno riunite in righe (`text_layout.dart`) usando una soglia
  **relativa all'altezza del testo**: una soglia fissa funziona solo per una
  risoluzione, e nelle foto scattate a mano le celle di una riga sono sempre
  un po' disallineate.
- **L'ordine delle colonne cambia da laboratorio a laboratorio.** Alcuni
  referti stampano `valore unità intervallo`, altri `valore intervallo unità`.
  L'intervallo viene quindi cercato ovunque si trovi, e l'unità è ciò che
  resta ai lati.
- **Il trattino dell'intervallo si perde spesso**: `13.5 - 18` arriva come
  `13.5 18`. Due numeri separati dal solo spazio vengono interpretati come
  intervallo, ma solo se il primo non supera il secondo.
- **Le cifre sgranate restano attaccate all'unità** (`0.4x10^9/L`). Vanno
  tolte: un'unità sporca cambia la chiave della serie storica, e il valore
  non si unirebbe più allo stesso esame letto da un PDF.
- Alcuni caratteri si perdono comunque (`fL` letto come `f`). Non è
  recuperabile in modo affidabile: è uno dei motivi per cui la revisione
  manuale è obbligatoria.

Due scelte non ovvie:

- **L'unità fa parte dell'identità della serie.** Sui referti `Neutrofili`
  compare sia in `%` sia in `x10^9/L`: unirli produrrebbe un grafico privo di
  senso clinico. La chiave di confronto è quindi nome canonico + unità.
- **Un "valore desiderabile" non è un limite di normalità.** Il colesterolo
  con obiettivo `<190` non viene marcato come patologico: è un obiettivo, non
  un intervallo di riferimento di laboratorio.

**Data del prelievo.** Si preferisce sempre la data del prelievo a quella di
produzione del referto: possono differire di giorni e usare la seconda
sfalserebbe l'asse temporale. Quando il documento non la contiene, la
schermata di revisione impedisce il salvataggio finché non viene inserita a
mano.

---

## Struttura

```
lib/
  app/            sessione, provider, tema
  core/
    db/           schema drift, connessioni cifrate (native/web), repository
    security/     PIN, derivazione, vault, archivio protetto
  features/
    parsing/      normalizzazione, catalogo analiti, parser
    import/       acquisizione, lettura PDF, OCR per piattaforma
    review/       conferma dei valori prima del salvataggio
    results/      vista tabellare
    charts/       andamenti nel tempo
    lock/         configurazione e sblocco
    patients/     anagrafica e scheda paziente
    settings/     sicurezza e gestione dell'archivio
```

---

## Avvio

```bash
flutter pub get
```

```bash
dart run build_runner build
```

```bash
flutter run -d android
```

Per le prove nel browser:

```bash
flutter run -d chrome
```

I file `web/sqlite3mc.wasm` e `web/drift_worker.js` sono già presenti. Se si
aggiorna `drift` o `sqlite3`, vanno riscaricati dalle release corrispondenti,
altrimenti le versioni non combaciano.

### Test

```bash
flutter test
```

I test sui referti reali leggono la cartella `esempi/`, che **non è
versionata** perché contiene dati sanitari personali. Se manca, quei test
vengono saltati e gli altri restano validi.

---

## Cosa non c'è ancora

- **PDF scansionati** (senza livello testo): vengono riconosciuti come tali e
  l'app lo dice chiaramente, ma le pagine non vengono ancora convertite in
  immagini per il riconoscimento ottico. Nel frattempo si può fotografare il
  referto.
- **Fotocamera**: provato il percorso galleria → ML Kit → parser su una foto
  reale, non ancora lo scatto diretto. Il codice è lo stesso, cambia solo la
  provenienza dell'immagine.
- **Sblocco biometrico**: `local_auth` è già fra le dipendenze, la funzione
  non è implementata.
- **Esportazione** dello storico (CSV o PDF).
- Su Android l'APK di debug include tutte le ABI e supera i 190 MB. Per la
  distribuzione servono `--split-per-abi` o un app bundle.
