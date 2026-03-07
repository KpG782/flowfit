import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsify/screens/dashboard_screen.dart' as ds;
import 'package:pulsify/models/daily_mood.dart';
import 'package:pulsify/core/providers/providers.dart' as core_providers;
import 'package:pulsify/providers/dashboard_providers.dart' as dashboard_providers;

void main() {
  testWidgets('AI Activity shows connect message when watch disconnected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          core_providers.watchConnectionStateProvider.overrideWith((ref) => Stream<bool>.value(false)),
          // Override dailyMoodProvider
          // Using a FutureProvider that resolves quickly to a simple DailyMood
          // NOTE: Use provider override to avoid Supabase instance requirement
          // by bypassing the default implementation
          dashboard_providers.dailyMoodProvider.overrideWith((ref) => Future.value(DailyMood(stressMinutes: 0, calmMinutes: 24 * 60))),
          // Override heart rate stream provider so it's deterministic
          core_providers.currentHeartRateProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp(home: ds.HomeTab()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Watch not connected'), findsOneWidget);
    expect(find.text('Connect'), findsWidgets);
  });
}
