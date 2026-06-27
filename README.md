# TwentyOne

**TwentyOne** è un'app mobile cross-platform (Android e iOS) sviluppata in Flutter, pensata per aiutare l'utente a costruire nuove abitudini attraverso un percorso strutturato di 21 giorni. Il nome si ispira alla teoria secondo cui 21 giorni di costanza sono sufficienti per formare un'abitudine duratura.

---

## Funzionalità principali

- **Streak giornaliero** — Conta i giorni consecutivi di utilizzo dell'app. Se accedi ogni giorno, la streak aumenta di 1; se salti un giorno, riparte da 1.
- **Countdown 21 giorni** — Mostra i giorni rimanenti al completamento del percorso a partire dalla data di registrazione account.
- **Agenda del giorno** — Visualizza le note/eventi dell'utente suddivisi per fascia oraria (mattina, pomeriggio, sera), sincronizzate in tempo reale con Firestore.
- **Citazione del giorno** — Una frase motivazionale selezionata deterministicamente in base al giorno dell'anno (cambia ogni giorno, stessa per tutta la giornata).
- **Calendario mensile** — Navigazione tra i mesi con evidenziazione del giorno corrente tramite `table_calendar`.
- **Notifiche locali** — Due tipologie: notifiche evento (15 min prima di ogni nota con orario), e notifiche motivazionali giornaliere a orario personalizzabile.
- **Schermata Ispirati** — Raccolta di citazioni motivazionali categorizzate (Disciplina, Abitudini, Mindset, Cambiamento, Coraggio, Gratitudine).
- **Gestione account** — Visualizzazione email, stato verifica, data registrazione, cambio password, logout con conferma.
- **Emoji + avatar** — Avatar utente con iniziali su sfondo personalizzabile.
- **Schermata completamento ciclo** — Al termine dei 21 giorni, opzione di reset o continuazione.

---

## Tech stack

| Layer | Tecnologia |
|---|---|
| Framework | Flutter (Dart) |
| Autenticazione | Firebase Authentication (email + password) |
| Database | Cloud Firestore |
| Notifiche | `flutter_local_notifications` + `timezone` |
| Preferenze locali | `shared_preferences` |
| UI / Font | `google_fonts` (Playfair Display) |
| Calendario | `table_calendar` |
| Icona app | `flutter_launcher_icons` |
| CI/CD | GitHub Actions (build IPA + release automatico) |

---

## Struttura del progetto

```
lib/
├── main.dart                    # Entry point, init Firebase + notifiche
├── firebase_options.dart        # Configurazione Firebase generata da FlutterFire CLI
├── auth/
│   └── auth.dart                # Wrapper FirebaseAuth (login, signup, logout, reload)
├── pages/
│   ├── widget_tree.dart         # AuthGate: routing automatico login ↔ app
│   ├── home.dart                # Dashboard: streak, countdown, citazione, agenda
│   ├── note.dart                # Gestione note/eventi (CRUD Firestore)
│   ├── profilo.dart             # Account utente + impostazioni
│   ├── calendario.dart          # Calendario mensile interattivo
│   ├── inspo.dart               # Sezione citazioni motivazionali
│   ├── notifiche.dart           # Preferenze notifiche (toggle on/off + orario)
│   └── cambio_password.dart     # Cambio password via Firebase
├── widgets/
│   └── my_bottom_bar.dart       # Bottom navigation bar (liquid glass, iOS/Android)
└── services/
    ├── servizio_notifiche.dart  # NotificationService singleton
    └── quotes_data.dart         # ~100 citazioni categorizzate + getQuoteOfDay()
```

---

## Struttura Firestore

```
utenti/
  {uid}/
    note/
      {docId}/
        inizio: "HH:mm"
        fine:   "HH:mm"
        testo:  "descrizione dell'evento"
    profilo/
      {docId}/
        avatar_emoji: "🦊"
        avatar_color: "#FF6B35"
        nome:         "Massimo"
    check_in/
      {YYYY-MM-DD}/
        completato: true
        mood:       "😊"
        timestamp:  Timestamp
```

---

## Navigazione

L'app usa una `IndexedStack` con una bottom navigation bar personalizzata (`MyBottomBar`) a quattro tab con platform branching (liquid glass su iOS, Material su Android):

| Tab | Schermata | Descrizione |
|---|---|---|
| Home | `Home` | Dashboard principale |
| Note | `Note` | Gestione note/eventi |
| Profilo | `WidgetTree` | Account e impostazioni |
| Ispirati | `Inspo` | Citazioni motivazionali |

---

## Autenticazione (AuthGate pattern)

Il `WidgetTree` ascolta lo stream `FirebaseAuth.authStateChanges()`. Se l'utente è autenticato e ha verificato l'email, accede all'app; altrimenti viene mostrata la schermata di login/registrazione. Il ricaricamento dell'utente (`reloadUser`) viene eseguito periodicamente per aggiornare lo stato di verifica email.

---

## Notifiche

Il `NotificationService` è implementato come singleton e gestisce:

**Notifiche evento** — Schedulate automaticamente al login per ogni nota Firestore che contiene un campo `inizio` (`HH:mm`). La notifica arriva 15 minuti prima dell'evento, riprogrammata ogni giorno.

**Notifica motivazionale giornaliera** — L'utente imposta un orario preferito tramite uno slider (20:00–00:00, step 10 min). La notifica arriva ogni giorno a quell'ora con una frase casuale da `quotes_data.dart`.

Le preferenze (on/off per ciascuna tipologia + orario) vengono salvate in `SharedPreferences`. Tutto il fuso orario è gestito tramite il package `timezone` con zona `Europe/Rome`.

---

## CI/CD — GitHub Actions

Il workflow `.github/workflows/` esegue automaticamente:

1. Checkout del codice e setup Flutter (canale stable, Java 17)
2. `flutter pub get` e `flutter build ipa --no-codesign`
3. Creazione di una GitHub Release con tag dinamico `v${{ github.run_number }}`
4. Upload dell'IPA come release asset

---

## Setup locale

### Prerequisiti

- Flutter SDK ≥ 3.5.0
- Dart SDK ≥ 3.5.0
- Account Firebase con progetto configurato
- Xcode (per build iOS) / Android Studio (per build Android)

### Installazione

```bash
# 1. Clona la repository
git clone https://github.com/ERciabbatta/TwentyOne.git
cd TwentyOne

# 2. Installa le dipendenze
flutter pub get

# 3. Configura Firebase
# Scarica GoogleService-Info.plist (iOS) e google-services.json (Android)
# dal tuo progetto Firebase e posizionali nelle rispettive cartelle

# 4. Avvia l'app
flutter run
```

### Generare l'icona app (solo iOS)

```bash
dart run flutter_launcher_icons
```

---

## Dipendenze principali

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.0
  flutter_local_notifications: ^21.0.0
  shared_preferences: ^2.5.5
  table_calendar: ^3.2.0
  google_fonts: ^8.1.0
  timezone: ^0.11.0

dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_lints: ^6.0.0
```

---

## Versioni

| Versione | Note |
|---|---|
| v1.0.0 | Release iniziale — autenticazione, note, streak, citazioni |
| v1.1.0 | Notifiche locali, calendario, schermata Ispirati |
| v1.2.1 | Bottom bar liquid glass, IndexedStack, fix notifiche iOS |

---

## Autore

Sviluppato da **Massimo Minni** — 2026

Progetto presentato come elaborato finale all'Esame di Stato (Maturità) 2026.

---

## Licenza

Questo progetto è privato. Tutti i diritti riservati.
