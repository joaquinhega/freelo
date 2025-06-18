import 'package:flutter/material.dart';
import '../views/login.dart';
import '../views/dashboard_screens.dart';
import '../views/register.dart';
import '../views/new_tarea.dart';
import '../views/calendar.dart';
import '../views/clientes.dart';
import '../views/estadisticas.dart';
import '../views/facturacion.dart';
import '../views/new_client.dart';
import '../views/settings.dart';
import '../views/tareas.dart';
import '../views/bienvenida.dart';
import '../views/detailsProject.dart';

class Routes{
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String register = '/register';  
  static const String new_tarea = '/nueva-tarea';
  static const String calendar = '/calendar';
  static const String clientes = '/clientes';
  static const String estadisticas = '/estadisticas';
  static const String facturacion = '/facturacion';
  static const String new_client = '/nuevo-cliente';
  static const String Settings = '/settings';
  static const String tareas = '/tareas';
  static const String bienvenida = '/bienvenida';
  static const String details_project = '/details_project';

  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const Login(), settings: settings);
      case register:
        return MaterialPageRoute(builder: (_) => const Register(), settings: settings);
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen(), settings: settings);
      case new_tarea:
        return MaterialPageRoute(builder: (_) => NewTaskScreen(), settings: settings);
      case calendar:
        return MaterialPageRoute(builder: (_) => CalendarScreen(), settings: settings);
      case clientes:
        return MaterialPageRoute(builder: (_) => ClientesScreen(), settings: settings);
      case estadisticas:
        return MaterialPageRoute(builder: (_) => EstadisticasScreen(), settings: settings);
      case facturacion:
        return MaterialPageRoute(builder: (_) => FacturacionScreen(), settings: settings);
      case new_client:
        return MaterialPageRoute(builder: (_) => NewClientScreen(), settings: settings);
      case Settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen(), settings: settings);
      case tareas:
        return MaterialPageRoute(builder: (_) => TareasScreen(), settings: settings);
      case bienvenida:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen(), settings: settings);
      case details_project:
        return MaterialPageRoute(
          builder: (_) => DetailsProjectScreen(projectData: {}, projectId: '',),
          settings: settings,
        );       
      default:
        return MaterialPageRoute(builder: (_) => const Login(), settings: settings);
    }
  }
}