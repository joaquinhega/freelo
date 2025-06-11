import 'package:flutter/material.dart';
import 'package:myapp/services/auth_service.dart';
import 'widgets/Footer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool tareas = true;
    bool plazos = true;
    bool pagos = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoTile('Correo electrónico', 'ignacio@example.com'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Cambiar contraseña'),
          ),
          ElevatedButton(
            onPressed: () async{
              await AuthService().logout();
              if(context.mounted) {
                Navigator.pushReplacementNamed(context, '/bienvenida');
              }
            },
            child: const Text('Cerrar sesión'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Notificaciones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: tareas,
            onChanged: (v) {},
            title: const Text('Tareas'),
          ),
          SwitchListTile(
            value: plazos,
            onChanged: (v) {},
            title: const Text('Plazos'),
          ),
          SwitchListTile(
            value: pagos,
            onChanged: (v) {},
            title: const Text('Pagos'),
          ),

          const SizedBox(height: 24),
          ListTile(
            tileColor: const Color(0xFFF2F2F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Gestionar categorías de ingresos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: const Footer(
        currentIndex: 3,
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
