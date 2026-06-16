import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:skyride/theme/app_theme.dart';
import '../Screens/Chat.dart';
import '../Screens/profile.dart';
import '../Screens/home.dart';

class Navigationbar extends StatefulWidget {
  final String sessionKey;

  const Navigationbar({super.key, required this.sessionKey});

  @override
  NavigationbarState createState() => NavigationbarState();
}

class NavigationbarState extends State<Navigationbar> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey<ChatState> _chatKey = GlobalKey<ChatState>();
  final GlobalKey<HomeState> _homeKey = GlobalKey<HomeState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    _refreshTab(index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
    _refreshTab(index);
  }

  void _refreshTab(int index) {
    if (index == 0) _homeKey.currentState?.reload();
    if (index == 1) _chatKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          Home(key: _homeKey, sessionKey: widget.sessionKey),
          Chat(key: _chatKey, sessionKey: widget.sessionKey),
          Profile(key: ValueKey('profile_${widget.sessionKey}')),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: AppTheme.background,
        color: AppTheme.background,
        buttonBackgroundColor: AppTheme.primary,
        height: 65,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        index: _selectedIndex,
        items: <Widget>[
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.chat, 'Chat', 1),
          _buildNavItem(Icons.person, 'Profile', 2),
        ],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30, color: isSelected ? Colors.white : Colors.black),
        if (!isSelected)
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
      ],
    );
  }
}
