# Bacheca lavoro

App Flutter per una bacheca di annunci di lavoro, fatta per il corso di Enterprise Mobile Application Development.

Le aziende si registrano, pubblicano annunci e consultano le candidature ricevute. I candidati, senza registrarsi, vedono gli annunci e si candidano inviando i propri dati e il curriculum.

Il back-end è in un repository separato: https://github.com/francescoambrosiosviluppo/bacheca-lavoro-backend

Per avviarla, con il back-end in esecuzione:

```
flutter pub get
flutter run --dart-define=API_URL=http://IP_DEL_COMPUTER:8090
```
