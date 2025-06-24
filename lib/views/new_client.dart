// modal para crear un nuevo proyecto

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class NewClientScreen extends StatefulWidget {
  const NewClientScreen({super.key});

  @override
  State<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends State<NewClientScreen> {
  final FirestoreService _servicioFirestore = FirestoreService();

  // Controladores para los campos de entrada
  final TextEditingController _controladorTitulo = TextEditingController();
  final TextEditingController _controladorDescripcion = TextEditingController();
  final TextEditingController _controladorFecha = TextEditingController();

  // Controladores para la información del cliente
  final TextEditingController _controladorNombreCliente = TextEditingController();
  final TextEditingController _controladorEmailCliente = TextEditingController();
  final TextEditingController _controladorTelefonoCliente = TextEditingController();
  final TextEditingController _controladorNotasCliente = TextEditingController();

  // Estado de las variables para fases y cliente
  bool _tieneFases = false;
  bool _tieneCliente = false;

  // Lista para almacenar los datos de las fases
  final List<Map<String, String>> _fases = [];

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescripcion.dispose();
    _controladorFecha.dispose();

    _controladorNombreCliente.dispose();
    _controladorEmailCliente.dispose();
    _controladorTelefonoCliente.dispose();
    _controladorNotasCliente.dispose();

    super.dispose();
  }

  // Método para crear un campo de entrada reutilizable
  Widget _campoEntrada({
    required TextEditingController controlador,
    required String textoAyuda,
    int maxLines = 1,
    TextInputType tipoTeclado = TextInputType.text,
  }) {
    return TextFormField(
      controller: controlador,
      maxLines: maxLines,
      keyboardType: tipoTeclado,
      decoration: InputDecoration(
        hintText: textoAyuda,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Método para agregar una nueva fase al proyecto
  void _addPhase() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nueva fase', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    labelStyle: TextStyle(color: mediumGrey),
                  ),
                  style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    labelStyle: TextStyle(color: mediumGrey),
                  ),
                  style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'date': 'N/A', // Default date
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text('Agregar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
            ),
          ],
          elevation: 10,
        );
      },
    );

    if (result != null && result['title'] != null && result['title']!.isNotEmpty) {
      setState(() {
        _fases.add(result);
      });
    }
  }

  // Método para eliminar una fase por su índice
  void _eliminarFase(int indice) {
    setState(() {
      _fases.removeAt(indice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Proyecto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 24),

            const Text('Título', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
            const SizedBox(height: 6),
            _campoEntrada(controlador: _controladorTitulo, textoAyuda: 'Título'),
            const SizedBox(height: 16),

            const Text('Descripción', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
            const SizedBox(height: 6),
            _campoEntrada(
                controlador: _controladorDescripcion,
                textoAyuda: 'Descripción',
                maxLines: 3),
            const SizedBox(height: 16),

            const Text('Fecha de Entrega', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
            const SizedBox(height: 6),
            TextFormField(
              controller: _controladorFecha,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'dd/mm/aaaa',
                filled: true,
                fillColor: Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Icon(Icons.calendar_today, color: mediumGrey),
              ),
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: primaryGreen, 
                          onPrimary: whiteColor,
                          onSurface: darkGrey, 
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: primaryGreen,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  _controladorFecha.text =
                      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                }
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Checkbox(
                  value: _tieneFases,
                  onChanged: (bool? valor) {
                    setState(() {
                      _tieneFases = valor ?? false;
                      if (!_tieneFases) {
                        _fases.clear(); 
                      }
                    });
                  },
                  activeColor: primaryGreen,
                ),
                const Text('Fases', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              ],
            ),
            const SizedBox(height: 24),

            if (_tieneFases) ...[ // Mostrar campos de fases si se selecciona
              const Divider(height: 1, color: lightGreen),
              const SizedBox(height: 16),
              const Text(
                'Fases del Proyecto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fases.length,
                itemBuilder: (context, indice) {
                  final phase = _fases[indice];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fase ${indice + 1}: ${phase['title'] ?? 'Sin título'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: errorRed),
                              onPressed: () => _eliminarFase(indice),
                              tooltip: 'Eliminar Fase',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          phase['description'] ?? 'Sin descripción',
                          style: const TextStyle(color: mediumGrey, fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addPhase,
                  icon: const Icon(Icons.add, color: whiteColor),
                  label: const Text('Agregar fase', style: TextStyle(color: whiteColor, fontFamily: 'Montserrat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Checkbox(
                  value: _tieneCliente,
                  onChanged: (bool? valor) {
                    setState(() {
                      _tieneCliente = valor ?? false;
                      if (!_tieneCliente) {
                        _controladorNombreCliente.clear();
                        _controladorEmailCliente.clear();
                        _controladorTelefonoCliente.clear();
                        _controladorNotasCliente.clear();
                      }
                    });
                  },
                  activeColor: primaryGreen,
                ),
                const Text('Cliente', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              ],
            ),
            const SizedBox(height: 24),

            if (_tieneCliente) ...[
              const Divider(height: 1, color: lightGreen),
              const SizedBox(height: 16),
              const Text(
                'Información del Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 16),
              const Text('Nombre', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorNombreCliente, textoAyuda: 'Nombre completo'),
              const SizedBox(height: 16),

              const Text('Email', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorEmailCliente, textoAyuda: 'correo@ejemplo.com', tipoTeclado: TextInputType.emailAddress),
              const SizedBox(height: 16),

              const Text('Teléfono', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorTelefonoCliente, textoAyuda: '123456789', tipoTeclado: TextInputType.phone),
              const SizedBox(height: 16),

              const Text('Notas', style: TextStyle(color: darkGrey, fontFamily: 'Montserrat')),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorNotasCliente, textoAyuda: 'Notas adicionales', maxLines: 3),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_controladorTitulo.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El título del proyecto es obligatorio.')),
                    );
                    return;
                  }

                  Map<String, String>? datosCliente;
                  if (_tieneCliente) {
                    datosCliente = {
                      'nombre': _controladorNombreCliente.text,
                      'email': _controladorEmailCliente.text,
                      'telefono': _controladorTelefonoCliente.text,
                      'notas': _controladorNotasCliente.text,
                    };
                  }

                  try {
                    await _servicioFirestore.addProject(
                      title: _controladorTitulo.text,
                      description: _controladorDescripcion.text,
                      date: _controladorFecha.text,
                      hasPhases: _tieneFases,
                      phases: _fases, 
                      hasClient: _tieneCliente,
                      clientInfo: datosCliente,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proyecto creado con éxito!')),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear proyecto: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: primaryGreen.withOpacity(0.4),
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return whiteColor.withOpacity(0.2);
                      }
                      return primaryGreen;
                    },
                  ),
                ),
                child: const Text(
                  'CREAR',
                  style: TextStyle(fontSize: 18, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}