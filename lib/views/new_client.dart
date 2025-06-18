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

  // Lista para almacenar los controladores de las fases
  final List<Map<String, TextEditingController>> _controladoresFases = [];

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescripcion.dispose();
    _controladorFecha.dispose();

    // Liberar controladores de fases
    for (var fase in _controladoresFases) {
      fase['titulo']?.dispose();
      fase['descripcion']?.dispose();
    }

    // Liberar controladores de cliente
    _controladorNombreCliente.dispose();
    _controladorEmailCliente.dispose();
    _controladorTelefonoCliente.dispose();
    _controladorNotasCliente.dispose();

    super.dispose();
  }

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

  void _agregarFase() {
    setState(() {
      _controladoresFases.add({
        'titulo': TextEditingController(),
        'descripcion': TextEditingController(),
      });
    });
  }

  void _eliminarFase(int indice) {
    setState(() {
      _controladoresFases[indice]['titulo']?.dispose();
      _controladoresFases[indice]['descripcion']?.dispose();
      _controladoresFases.removeAt(indice);
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text('Título'),
            const SizedBox(height: 6),
            _campoEntrada(controlador: _controladorTitulo, textoAyuda: 'Título'),
            const SizedBox(height: 16),

            const Text('Descripción'),
            const SizedBox(height: 6),
            _campoEntrada(
                controlador: _controladorDescripcion,
                textoAyuda: 'Descripción',
                maxLines: 3),
            const SizedBox(height: 16),

            const Text('Fecha de Entrega'),
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
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
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
                      if (_tieneFases && _controladoresFases.isEmpty) {
                        _agregarFase();
                      }
                      if (!_tieneFases) {
                        for (var fase in _controladoresFases) {
                          fase['titulo']?.clear();
                          fase['descripcion']?.clear();
                        }
                        _controladoresFases.clear();
                      }
                    });
                  },
                ),
                const Text('Fases'),
              ],
            ),
            const SizedBox(height: 24),

            if (_tieneFases) ...[
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Fases del Proyecto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controladoresFases.length,
                itemBuilder: (context, indice) {
                  final controladorTituloFase = _controladoresFases[indice]['titulo']!;
                  final controladorDescripcionFase = _controladoresFases[indice]['descripcion']!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fase ${indice + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarFase(indice),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Título'),
                        const SizedBox(height: 6),
                        _campoEntrada(controlador: controladorTituloFase, textoAyuda: 'Título de la fase'),
                        const SizedBox(height: 16),
                        const Text('Descripción'),
                        const SizedBox(height: 6),
                        _campoEntrada(controlador: controladorDescripcionFase, textoAyuda: 'Descripción de la fase', maxLines: 3),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _agregarFase,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Agregar fase', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                ),
                const Text('Cliente'),
              ],
            ),
            const SizedBox(height: 24),

            if (_tieneCliente) ...[
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Información del Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Nombre'),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorNombreCliente, textoAyuda: 'Nombre completo'),
              const SizedBox(height: 16),

              const Text('Email'),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorEmailCliente, textoAyuda: 'correo@ejemplo.com', tipoTeclado: TextInputType.emailAddress),
              const SizedBox(height: 16),

              const Text('Teléfono'),
              const SizedBox(height: 6),
              _campoEntrada(controlador: _controladorTelefonoCliente, textoAyuda: '123456789', tipoTeclado: TextInputType.phone),
              const SizedBox(height: 16),

              const Text('Notas'),
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

                  List<Map<String, String>> datosFases = [];
                  if (_tieneFases) {
                    for (var fase in _controladoresFases) {
                      datosFases.add({
                        'titulo': fase['titulo']?.text ?? '',
                        'descripcion': fase['descripcion']?.text ?? '',
                      });
                    }
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
                      phases: datosFases,
                      hasClient: _tieneCliente,
                      clientInfo: datosCliente,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proyecto creado con éxito!')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear proyecto: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CREAR',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}