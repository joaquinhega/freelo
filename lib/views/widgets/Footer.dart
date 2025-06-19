import 'package:flutter/material.dart'; // Importa la biblioteca fundamental de Flutter para construir interfaces de usuario.
import '../../routes/routes.dart'; // Importa el archivo que define las rutas de la aplicación.

// `Footer` es un widget sin estado (`StatelessWidget`) que representa la barra de navegación inferior.
// Recibe un `currentIndex` para saber qué ítem debe estar activo.
class Footer extends StatelessWidget {
  final int currentIndex; // Índice del ítem actualmente seleccionado en la barra de navegación.

  // Constructor del widget, requiere el `currentIndex`.
  const Footer({
    Key? key, // Key para identificar el widget de forma única, útil en listas.
    required this.currentIndex, // Parámetro obligatorio: el índice del elemento activo.
  }) : super(key: key); // Llama al constructor de la clase padre.

  // Método privado `_onTap` que se ejecuta cuando se toca un ítem de la barra de navegación.
  // Recibe el contexto y el índice del ítem que fue tocado.
  void _onTap(BuildContext context, int index) {
    // Si el índice tocado es el mismo que el actual, no hace nada (evita recargar la misma página).
    if (index == currentIndex) return;

    // Un `switch` para navegar a la ruta correspondiente según el índice tocado.
    switch (index) {
      case 0:
        // Navega a la ruta 'dashboard' reemplazando la ruta actual en la pila de navegación.
        // `pushReplacementNamed` es útil para evitar que el usuario vuelva a la página anterior
        // usando el botón de retroceso del dispositivo.
        Navigator.pushReplacementNamed(context, Routes.dashboard);
        break;
      case 1:
        // Navega a la ruta 'tareas'.
        Navigator.pushReplacementNamed(context, Routes.tareas);
        break;
      case 2:
        // Navega a la ruta 'clientes'.
        Navigator.pushReplacementNamed(context, Routes.clientes);
        break;
      case 3:
        // Navega a la ruta 'estadisticas'.
        Navigator.pushReplacementNamed(context, Routes.estadisticas);
        break;
      case 4:
        // Navega a la ruta 'Settings'.
        Navigator.pushReplacementNamed(context, Routes.Settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // `BottomNavigationBar` es el widget de Flutter que implementa la barra de navegación inferior.
    return BottomNavigationBar(
      currentIndex: currentIndex, // Establece el índice del ítem seleccionado actualmente.
      onTap: (index) => _onTap(context, index), // Define la función a llamar cuando se toca un ítem.
      selectedItemColor: Colors.green[800], // Color de los iconos y etiquetas del ítem seleccionado.
      unselectedItemColor: Colors.grey, // Color de los iconos y etiquetas de los ítems no seleccionados.
      items: const [
        // Lista de `BottomNavigationBarItem`, que son los ítems individuales en la barra.
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'), // Ítem para la pantalla de inicio.
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tareas'), // Ítem para la pantalla de tareas.
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Proyectos'), // Ítem para la pantalla de proyectos/clientes.
        BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Métricas'), // Ítem para la pantalla de estadísticas.
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'), // Ítem para la pantalla de perfil/configuración.
      ],
    );
  }
}