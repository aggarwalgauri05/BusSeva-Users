import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../screens/user_dashboard_screen.dart';
import '../screens/live_tracking_page.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../sign_in_screen.dart';
import '../sign_up_screen.dart';
import '../widgets/home_screen_content.dart';
class MainBottomNavigation extends StatefulWidget {
  const MainBottomNavigation({Key? key}) : super(key: key);

  @override
  State<MainBottomNavigation> createState() => _MainBottomNavigationState();
}

class _MainBottomNavigationState extends State<MainBottomNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // Check if user needs to be logged in for certain tabs
    if ((index == 1 || index == 3) && !AuthService.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.login, color: Color(0xFF667EEA)),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please sign in to access this feature. You can book tickets and manage trips after logging in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to your existing sign in screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
      return const HomeScreenContent(); // Changed from HomeScreenContent()
      case 1:
        return AuthService.isLoggedIn 
            ? const UserDashboardScreen() 
            : const LoginRequiredScreen(title: 'My Trips');
      case 2:
        return const LiveTrackingPage(busId: ''); // Your tracking screen
      case 3:
        return AuthService.isLoggedIn 
            ? const ProfileScreen() 
            : const LoginRequiredScreen(title: 'Profile');
      default:
        return const HomeScreenContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreenForIndex(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              activeIcon: Icon(Icons.location_on),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Login required screen for when user is not authenticated
class LoginRequiredScreen extends StatelessWidget {
  final String title;
  
  const LoginRequiredScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.login,
                  size: 64,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign in Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please sign in to access your trips, book tickets, and manage your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
