# TwentyOne — Documentazione dell'applicazione

## Panoramica

TwentyOne è un'app mobile sviluppata in Flutter, disponibile per Android e iOS, pensata per aiutare l'utente a costruire nuove abitudini attraverso un percorso di 21 giorni. Il nome si ispira alla teoria popolare secondo cui ci vogliono 21 giorni di costanza per formare un'abitudine duratura.

L'app permette di organizzare la giornata tramite note/eventi, tracciare la propria streak giornaliera, ricevere frasi motivazionali e visualizzare un calendario personale.

---

## Tecnologie utilizzate

- **Flutter** — framework cross-platform per Android e iOS
- **Firebase Authentication** — gestione login, registrazione e autenticazione utente
- **Cloud Firestore** — database cloud per il salvataggio delle note
- **Firebase Core** — inizializzazione dei servizi Firebase
- **flutter_local_notifications** — notifiche locali schedulate
- **shared_preferences** — salvataggio locale di preferenze e streak
- **timezone** — gestione fuso orario (Europe/Rome) per le notifiche
- **google_fonts** — tipografia (Playfair Display)
- **table_calendar** — widget calendario interattivo

---

## Struttura della navigazione

L'app è strutturata attorno a una bottom navigation bar personalizzata (`MyBottomBar`) con quattro sezioni principali:

| Tab | Schermata | Descrizione |
|-----|-----------|-------------|
| Home | `Home` | Dashboard principale con streak, obiettivo, citazione del giorno e note del giorno |
| Note | `Note` | Gestione delle note/eventi personali |
| Profilo | `WidgetTree` | Autenticazione e profilo utente |
| Ispirati | `Inspo` | Sezione dedicata all'ispirazione |

---

## Schermate principali

### Home (`Home.dart`)

La schermata principale mostra una panoramica della giornata dell'utente.

**Contenuti visualizzati:**

- **Card Streak** — mostra il numero di giorni consecutivi in cui l'utente ha aperto l'app. La streak viene calcolata confrontando la data odierna con l'ultima data di accesso salvata in `SharedPreferences`. Viene incrementata di 1 se l'accesso è avvenuto il giorno precedente, azzerata a 1 se è passato più di un giorno.

- **Card Obiettivo 21 giorni** — mostra i giorni rimanenti al completamento del percorso di 21 giorni. Il calcolo si basa sulla data di creazione dell'account Firebase (`user.metadata.creationTime`).

- **Citazione del giorno** — una frase motivazionale selezionata in modo deterministico in base al giorno dell'anno (stessa frase per tutto il giorno, cambia ogni giorno).

- **Agenda del giorno** — le note dell'utente vengono recuperate in tempo reale da Firestore e suddivise in tre fasce orarie:
    - **Mattina** — eventi con orario di inizio tra le 06:00 e le 11:59
    - **Pomeriggio** — eventi tra le 12:00 e le 17:59
    - **Sera** — eventi dalle 18:00 in poi

  Ogni nota mostra l'orario di inizio, il testo e l'orario di fine.

---

### Profilo (`Profilo.dart`)

Schermata di gestione dell'account utente.

**Sezione Account:**
- Email dell'utente
- Stato di verifica email (Sì / No)
- Data di registrazione

**Sezione Impostazioni:**
- **Cambia password** — naviga alla schermata `CambioPassword`
- **Notifiche** — naviga alla schermata `Notifiche` per gestire le preferenze
- **Informazioni sull'app** — mostra un dialog con versione (1.0.0) e descrizione dell'app

**Logout** — pulsante con conferma tramite dialog. Alla conferma viene eseguito il logout da Firebase Authentication.

L'avatar utente mostra le iniziali del nome (massimo 2 lettere) su sfondo blu.

---

### Calendario (`Calendario.dart`)

Schermata accessibile dall'icona calendario nella AppBar della Home. Mostra un calendario mensile interattivo tramite il widget `TableCalendar`.

**Caratteristiche:**
- Navigazione tra i mesi con frecce
- Evidenziazione del giorno corrente
- Prima settimana dal lunedì
- Stile personalizzato coerente con il design dell'app

---

## Autenticazione (`Auth.dart` e `WidgetTree`)

La classe `Auth` è un wrapper attorno a `FirebaseAuth` che espone:

- `currentUser` — utente attualmente autenticato
- `authStateChanges` — stream per ascoltare i cambiamenti di stato dell'autenticazione
- `isEmailVerified` — verifica se l'email è confermata
- `signInWithEmailAndPassword` — login con email e password
- `createUserWithEmailAndPassword` — registrazione nuovo utente
- `reloadUser` — aggiorna i dati dell'utente da Firebase
- `signOut` — logout

Il `WidgetTree` gestisce il routing automatico: se l'utente è autenticato mostra il profilo, altrimenti mostra la schermata di login/registrazione.

---

## Notifiche (`servizio_notifiche.dart`)

Il servizio notifiche è implementato come singleton (`NotificationService`) e gestisce due tipologie di notifiche locali.

### Notifiche eventi
Schedulate automaticamente all'avvio dell'app (solo se l'utente è autenticato). Per ogni nota salvata su Firestore che ha un campo `inizio` (orario in formato `HH:mm`), viene programmata una notifica **15 minuti prima** dell'evento. Le notifiche vengono riprogrammate ogni giorno alla stessa ora.

### Notifiche motivazionali
Una notifica con una frase motivazionale casuale, schedulata con un ritardo casuale tra 4 e 10 ore dall'avvio dell'app.

### Preferenze notifiche
L'utente può attivare/disattivare separatamente le notifiche eventi e quelle motivazionali dalla schermata `Notifiche`. Le preferenze vengono salvate in `SharedPreferences`.

### Fuso orario
Tutte le notifiche usano il fuso orario `Europe/Rome`.

---

## Frasi motivazionali (`quotes_data.dart`)

Il file contiene una collezione di circa 100 citazioni suddivise per categoria:

- **Disciplina** — citazioni sulla costanza e il lavoro quotidiano
- **Abitudini** — citazioni sulla formazione di abitudini positive
- **Mindset** — citazioni sulla mentalità e la crescita personale
- **Cambiamento** — citazioni sulla trasformazione personale
- **Coraggio** — citazioni sull'iniziare e perseverare
- **Gratitudine** — citazioni sul riconoscere il valore di ciò che si ha

La funzione `getQuoteOfDay()` seleziona deterministicamente una citazione basandosi sul giorno dell'anno, garantendo che la stessa frase venga mostrata per tutta la giornata e cambi il giorno successivo.

---

## Database Firestore

La struttura del database è la seguente:

```
utenti/
  {uid}/
    note/
      {docId}/
        inizio: "HH:mm"
        fine: "HH:mm"
        testo: "descrizione dell'evento"
```

Ogni utente ha la propria collezione di note identificata dal suo `uid` Firebase.

---

## Avvio dell'app (`main.dart`)

Al lancio dell'app vengono eseguite in sequenza le seguenti operazioni:

1. Inizializzazione dei binding Flutter
2. Inizializzazione di Firebase con le opzioni della piattaforma corrente (`DefaultFirebaseOptions.currentPlatform`)
3. Inizializzazione del servizio notifiche (timezone, plugin)
4. Richiesta permessi notifiche all'utente
5. Avvio dell'app (`runApp`)
6. Dopo il login, scheduling delle notifiche eventi e motivazionali

Tutto è wrappato in `runZonedGuarded` per intercettare eventuali errori runtime non gestiti.

---

## Informazioni sull'app

- **Nome:** TwentyOne
- **Versione:** 1.0.0
- **Sviluppatore:** Massimo Minni
- **Anno:** 2026
- **Piattaforme:** Android, iOS