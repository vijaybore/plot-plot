import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plot_plot/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlotPlotApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}