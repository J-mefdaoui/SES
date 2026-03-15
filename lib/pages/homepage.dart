import 'package:flutter/material.dart';
import 'package:my_first_project/pages/debugmap.dart';
import 'package:my_first_project/pages/Auth/login.dart';
import 'package:my_first_project/pages/mapPage.dart'; // Adjust import path

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const Text(
              'Login Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate back to login - REMOVED 'const' here
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), // Removed const
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Log Out'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate back to login - REMOVED 'const' here
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => offlineMap(),
                  ), // Removed const
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('MAP'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate back to login - REMOVED 'const' here
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DebugMbtilesPage(),
                  ), // Removed const
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('MAP'),
            ),
          ],
        ),
      ),
    );
  }
}
