import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../ticket/presentation/ticket_list_screen.dart';
import '../../trip/presentation/trip_search_screen.dart';

/// Main home screen for the passenger app with tab navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, this.initialTab = 0});

  final AuthController auth;
  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_tab == 0 ? 'Search Trips' : 'My Tickets'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'profile') {
              _showProfile();
            } else if (value == 'logout') {
              widget.auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
          ],
        ),
      ],
    ),
    body: IndexedStack(
      index: _tab,
      children: [
        TripSearchScreen(auth: widget.auth),
        TicketListScreen(auth: widget.auth),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'My Tickets',
        ),
      ],
    ),
  );

  void _showProfile() {
    final user = widget.auth.user;
    AppDialog.showInfo(
      context,
      title: 'Profile',
      content: [
        if (user?['first_name'] != null || user?['last_name'] != null)
          '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim(),
        'Phone: ${user?['phone_number'] ?? '-'}',
        if (user?['email'] != null) 'Email: ${user?['email']}',
      ].join('\n'),
      actionLabel: 'Close',
    );
  }
}
