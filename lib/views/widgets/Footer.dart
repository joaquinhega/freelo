import 'package:flutter/material.dart';
import '../../routes/routes.dart';

class Footer extends StatelessWidget {
  final int currentIndex;

  const Footer({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.dashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.tareas);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.clientes);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.Settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      selectedItemColor: Colors.green[800],
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tareas'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
      ],
    );
  }
}