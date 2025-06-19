import 'package:flutter/material.dart'; // Importa la biblioteca fundamental de Flutter para construir interfaces de usuario.
import 'routes/routes.dart'; // Importa la definición de las rutas de la aplicación.
import 'firebase_options.dart'; // Importa las opciones de configuración de Firebase generadas automáticamente.
import 'package:firebase_core/firebase_core.dart'; // Importa el paquete central de Firebase para Flutter.

// La función `main` es el punto de entrada de cualquier aplicación Flutter.
// Es asíncrona porque realizará una inicialización de Firebase.
Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados. Esto es necesario
  // antes de realizar cualquier operación asíncrona o interactuar con el motor de Flutter.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase para la aplicación.
  // Utiliza `DefaultFirebaseOptions.currentPlatform` para cargar las opciones de configuración
  // adecuadas para la plataforma en la que se está ejecutando la aplicación (web, Android, iOS, etc.).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Una vez que Firebase ha sido inicializado, ejecuta la aplicación Flutter.
  runApp(MyApp());
}

// `MyApp` es el widget raíz de la aplicación. Es un `StatelessWidget`
// porque su estado no cambia durante la vida útil del widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor de la clase.

  @override
  Widget build(BuildContext context) {
    // `MaterialApp` es un widget que envuelve una serie de widgets que implementan
    // Material Design. Es esencial para la mayoría de las aplicaciones Flutter.
    return MaterialApp(
      // Define la ruta inicial de la aplicación cuando se inicia.
      // Aquí se establece como la ruta 'bienvenida' definida en `Routes.dart`.
      initialRoute: Routes.bienvenida,
      // Define cómo se generarán las rutas de la aplicación.
      // `Routes().generateRoute` es una función que mapea nombres de ruta a widgets de pantalla.
      onGenerateRoute: Routes().generateRoute,
      // Define el tema visual de la aplicación.
      theme: ThemeData(
        // Establece el "primary swatch" (una paleta de colores basada en un color principal)
        // para la aplicación. Aquí se usa el azul por defecto de Material Design.
        primarySwatch: Colors.blue,
      ),
    );
  }
}