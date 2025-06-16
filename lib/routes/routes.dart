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
        return MaterialPageRoute(builder: (_) => const Login());
      case register:
        return MaterialPageRoute(builder: (_) => const Register());
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case new_tarea:
        return MaterialPageRoute(builder: (_) => NewTaskScreen());
      case calendar:
        return MaterialPageRoute(builder: (_) => CalendarScreen());
      case clientes:
        return MaterialPageRoute(builder: (_) => ClientesScreen());
      case estadisticas:
        return MaterialPageRoute(builder: (_) => EstadisticasScreen());
      case facturacion:
        return MaterialPageRoute(builder: (_) => FacturacionScreen());
      case new_client:
        return MaterialPageRoute(builder: (_) => NewClientScreen());
      case Settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case tareas:
        return MaterialPageRoute(builder: (_) => TareasScreen());
      case bienvenida:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case details_project:
      return MaterialPageRoute(builder: (_) => DetailsProjectScreen(projectData: {}, projectId: '',));       
      default:
        return MaterialPageRoute(builder: (_) => const Login());
    }
  }
}