import 'dart:convert';

import 'package:bacheca_lavoro_app/api_client.dart';
import 'package:bacheca_lavoro_app/app_state.dart';
import 'package:bacheca_lavoro_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Esegue gli scenari S1, S2 e S3 sull'app vera, contro il back-end in esecuzione.
/// Avvio: `flutter test integration_test -d <simulatore>` con il server attivo.
/// L'unico passo non automatizzabile è la scelta del file nel selettore di sistema:
/// la candidatura con il CV viene quindi inviata tramite le API.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 15}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Non trovato: $finder');
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await waitFor(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextFormField, label);
    await waitFor(tester, field);
    await tester.ensureVisible(field.first);
    await tester.enterText(field.first, text);
    await tester.pump();
  }

  testWidgets('S1, S2, S3', (tester) async {
    (await SharedPreferences.getInstance()).clear();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'hr$stamp@prova.it';
    final title = 'Sviluppatore Flutter $stamp';

    await app.main();
    await tester.pumpAndSettle();

    // ---------------- S1: registrazione, login, nuovo annuncio
    await tap(tester, find.text('Area aziende'));
    await tap(tester, find.text('Registrati'));
    await type(tester, 'Nome azienda', 'Prova Srl');
    await type(tester, 'Email', email);
    await type(tester, 'Password', 'prova123');
    await type(tester, 'Conferma password', 'prova123');
    await tap(tester, find.text('Crea account'));
    await waitFor(tester, find.textContaining('Account creato'));

    await type(tester, 'Password', 'prova123');
    await tap(tester, find.text('Accedi').last);
    await waitFor(tester, find.text('Area riservata'));
    expect(find.text('Prova Srl'), findsOneWidget);

    await tap(tester, find.text('Nuovo annuncio'));
    await type(tester, 'Titolo *', title);
    await type(tester, 'Descrizione *', 'Cerchiamo uno sviluppatore mobile junior.');
    await type(tester, 'Sede (facoltativa)', 'Salerno');
    await tap(tester, find.text('Pubblica annuncio'));
    await waitFor(tester, find.textContaining('pubblicato in bacheca'));
    await waitFor(tester, find.text(title));

    await tap(tester, find.byIcon(Icons.dashboard_outlined));
    await waitFor(tester, find.text(title));
    expect(find.text('Area riservata'), findsOneWidget, reason: 'pulsante in bacheca da loggati');

    // logout per tornare utente pubblico (verificato di nuovo alla fine di S3)
    await tap(tester, find.text('Area riservata'));
    await tap(tester, find.byIcon(Icons.logout));
    await tap(tester, find.widgetWithText(FilledButton, 'Esci'));
    await waitFor(tester, find.text('Area aziende'));

    // ---------------- S2: bacheca, dettaglio, form di candidatura
    await tap(tester, find.text(title));
    await waitFor(tester, find.text('Dettaglio annuncio'));
    expect(find.text('Cerchiamo uno sviluppatore mobile junior.'), findsOneWidget);
    await tap(tester, find.text('Candidati'));
    await type(tester, 'Nome *', 'Mario');
    await type(tester, 'Cognome *', 'Rossi');
    await type(tester, 'Email *', 'mario.rossi@example.com');
    await tap(tester, find.text('Invia candidatura'));
    expect(find.text('Allega il curriculum'), findsOneWidget, reason: 'senza CV non si invia');

    // invio con CV tramite API (il selettore file è nativo)
    final api = ApiClient(baseUrl: AppState.defaultServerUrl);
    final job = (await api.listJobs()).firstWhere((j) => j.title == title);
    await api.apply(
      jobId: job.id,
      firstName: 'Mario',
      lastName: 'Rossi',
      email: 'mario.rossi@example.com',
      cvFilename: 'cv_mario_rossi.pdf',
      cvBytes: utf8.encode('%PDF-1.4\n%%EOF'),
    );
    await tap(tester, find.byType(BackButton));
    await tap(tester, find.byType(BackButton));

    // ---------------- S3: candidature ricevute e logout
    await tap(tester, find.text('Area aziende'));
    await type(tester, 'Email', email);
    await type(tester, 'Password', 'prova123');
    await tap(tester, find.text('Accedi').last);
    await waitFor(tester, find.text(title));
    await tap(tester, find.text(title));
    await waitFor(tester, find.text('Candidature ricevute'));
    await tap(tester, find.text('Mario Rossi'));
    await waitFor(tester, find.text('cv_mario_rossi.pdf'));
    expect(find.text('mario.rossi@example.com'), findsOneWidget);
    expect(find.text('Apri curriculum'), findsOneWidget);

    await tap(tester, find.byType(BackButton));
    await tap(tester, find.byType(BackButton));
    await tap(tester, find.byIcon(Icons.logout));
    await tap(tester, find.widgetWithText(FilledButton, 'Esci'));
    await waitFor(tester, find.text('Logout effettuato.'));
    expect(find.text('Bacheca Lavoro'), findsOneWidget);

    // l'area riservata non è più accessibile: si apre il login
    await tap(tester, find.text('Area aziende'));
    await waitFor(tester, find.text('Non hai un account?'));
    expect(find.text('Area riservata'), findsNothing);
  });
}
