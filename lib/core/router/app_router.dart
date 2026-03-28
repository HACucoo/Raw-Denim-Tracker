import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/item_form/item_form_screen.dart';
import '../../screens/item_detail/item_detail_screen.dart';
import '../../screens/nfc/nfc_link_screen.dart';
import '../../screens/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  // Catch-all: any URI that go_router doesn't recognise (e.g. rawdenim://wear/…
  // from an NFC NDEF intent that Android also passes as the initial location)
  // is silently redirected to the home screen. The actual NFC handling happens
  // via the MethodChannel in app.dart, not through the router.
  onException: (_, GoRouterState state, GoRouter router) => router.go('/'),
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/item/new',
      builder: (_, __) => const ItemFormScreen(),
    ),
    GoRoute(
      path: '/item/:id/edit',
      builder: (context, state) => ItemFormScreen(itemId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) => ItemDetailScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/item/:id/nfc',
      builder: (context, state) => NfcLinkScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
