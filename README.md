# TwentyOne 🔥

**TwentyOne** è un'app mobile cross-platform (Android & iOS) realizzata in **Flutter**, pensata per aiutarti a costruire nuove abitudini sfruttando la celebre "regola dei 21 giorni". L'app ti accompagna giorno per giorno con streak, agenda personale, citazioni motivazionali e notifiche, per non perdere la costanza nel tuo percorso.

---

## ✨ Funzionalità principali

- **Autenticazione utente** tramite Firebase Authentication (registrazione, login, verifica email, cambio password)
- **Streak giornaliera**: traccia per quanti giorni consecutivi apri e usi l'app
- **Percorso di 21 giorni**: conto alla rovescia calcolato dalla data di creazione dell'account
- **Agenda del giorno**: gestione di note/eventi personali divisi in Mattina, Pomeriggio e Sera, sincronizzati in tempo reale su Cloud Firestore
- **Citazione motivazionale del giorno**: una frase diversa ogni giorno, scelta da una raccolta di circa 100 citazioni
- **Notifiche locali**:
    - Reminder 15 minuti prima di ogni evento in agenda
    - Notifiche motivazionali casuali durante la giornata
    - Preferenze attivabili/disattivabili dall'utente
- **Calendario mensile interattivo** per la navigazione tra i giorni
- **Profilo utente** con dati account, stato verifica email e logout

---

## 🛠️ Stack tecnologico

| Tecnologia | Utilizzo |
|---|---|
| [Flutter](https://flutter.dev) | Framework UI cross-platform (Android/iOS) |
| [Firebase Authentication](https://firebase.google.com/products/auth) | Login e registrazione utenti |
| [Cloud Firestore](https://firebase.google.com/products/firestore) | Database cloud per le note |
| [Firebase Core](https://firebase.google.com/docs/flutter/setup) | Inizializzazione servizi Firebase |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Notifiche locali schedulate |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Persistenza locale di streak e preferenze |
| [timezone](https://pub.dev/packages/timezone) | Gestione fuso orario `Europe/Rome` |
| [google_fonts](https://pub.dev/packages/google_fonts) | Tipografia (Playfair Display) |
| [table_calendar](https://pub.dev/packages/table_calendar) | Widget calendario interattivo |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | Generazione icona app |

---

## 📂 Struttura del progetto

```
lib/
├── main.dart                  # Entry point, init Firebase e notifiche
├── pages/
│   ├── home.dart               # Dashboard: streak, obiettivo, agenda, citazione
│   ├── note.dart                # Gestione note/eventi
│   ├── calendario.dart          # Calendario mensile
│   ├── profilo.dart             # Profilo utente e impostazioni
│   ├── notifiche.dart           # Preferenze notifiche
│   ├── login_register.dart      # Login e registrazione
│   ├── cambia_password.dart     # Cambio password
│   ├── checkin.dart              # Check-in giornaliero
│   ├── completamento.dart        # Completamento percorso 21 giorni
│   ├── non_iscritto.dart          # Schermata utente non autenticato
│   └── inspo.dart                 # Sezione ispirazione
└── widget/
    ├── MyBottomBar.dart          # Bottom navigation bar
    ├── auth.dart                  # Wrapper Firebase Authentication
    ├── widget_tree.dart            # Routing in base allo stato auth
    ├── crea_nota.dart               # Creazione/editing nota
    ├── servizio_notifiche.dart       # Servizio notifiche locali (singleton)
    └── quotes_data.dart               # Raccolta citazioni motivazionali
```

---

## 🗄️ Struttura del database Firestore

```
utenti/
  {uid}/
    note/
      {docId}/
        inizio: "HH:mm"
        fine: "HH:mm"
        testo: "descrizione dell'evento"
```

Ogni utente possiede la propria collezione di note, identificata dal suo `uid` Firebase.

---

## 📱 Navigazione dell'app

L'app utilizza una bottom navigation bar (`MyBottomBar`) con quattro sezioni principali:

| Tab | Schermata | Descrizione |
|---|---|---|
| 🏠 Home | `Home` | Streak, obiettivo, citazione del giorno e agenda |
| 📝 Note | `Note` | Gestione note ed eventi personali |
| 👤 Profilo | `WidgetTree` | Autenticazione e profilo utente |
| ✨ Ispirati | `Inspo` | Sezione dedicata all'ispirazione |

---

## ℹ️ Informazioni

- **Nome:** TwentyOne
- **Versione:** 1.3.0
- **Piattaforme:** Android, iOS
- **Autore:** Massimo Minni


```
 _____  ____         _         _      _             _    _          
| ____||  _ \   ___ (_)  __ _ | |__  | |__    __ _ | |_ | |_   __ _ 
|  _|  | |_) | / __|| | / _` || '_ \ | '_ \  / _` || __|| __| / _` |
| |___ |  _ < | (__ | || (_| || |_) || |_) || (_| || |_ | |_ | (_| |
|_____||_| \_\ \___||_| \__,_||_.__/ |_.__/  \__,_| \__| \__| \__,_|
```


