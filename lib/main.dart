// pubspec.yaml dependencies needed:
/*
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  fl_chart: ^0.65.0
  intl: ^0.19.0
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ljwyurgkbzrvwevwpkuv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxqd3l1cmdrYnpydndldndwa3V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3NDAwODksImV4cCI6MjA3MzMxNjA4OX0.-7huhbW-BJf_-diK7JgULzEDoTWFIgLPSCot5w4oH3I',
  );
  
  runApp(const GranizadosApp());
}

class GranizadosApp extends StatelessWidget {
  const GranizadosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Granizados',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = [
    VentasScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.icecream),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> with TickerProviderStateMixin {
  int chicleCount = 0;
  int kolitaCount = 0;
  final int precioUnitario = 1000;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animatePress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  int get totalGranizados => chicleCount + kolitaCount;
  int get totalPrecio => totalGranizados * precioUnitario;

  Future<void> _confirmarVenta() async {
    if (totalGranizados == 0) return;

    try {
      final supabase = Supabase.instance.client;
      
      if (chicleCount > 0) {
        await supabase.from('ventas').insert({
          'sabor': 'Chicle',
          'cantidad': chicleCount,
          'precio_unitario': precioUnitario,
          'total': chicleCount * precioUnitario,
          'fecha': DateTime.now().toIso8601String(),
        });
      }
      
      if (kolitaCount > 0) {
        await supabase.from('ventas').insert({
          'sabor': 'Kolita',
          'cantidad': kolitaCount,
          'precio_unitario': precioUnitario,
          'total': kolitaCount * precioUnitario,
          'fecha': DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        chicleCount = 0;
        kolitaCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Venta registrada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGranizadoButton({
    required String sabor,
    required Color color,
    required int count,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        _animatePress();
        onPressed();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.8),
                    color,
                    color.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sabor,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'es_CR',
      symbol: '₡',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Control de Granizados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Contador total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B4D8).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total de Granizados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$totalGranizados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatter.format(totalPrecio),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botones de granizados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildGranizadoButton(
                      sabor: 'Chicle',
                      color: const Color(0xFFFF006E),
                      count: chicleCount,
                      onPressed: () => setState(() => chicleCount++),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: chicleCount > 0 ? () => setState(() => chicleCount--) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF006E),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => chicleCount++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF006E),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    _buildGranizadoButton(
                      sabor: 'Kolita',
                      color: const Color(0xFF8338EC),
                      count: kolitaCount,
                      onPressed: () => setState(() => kolitaCount++),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: kolitaCount > 0 ? () => setState(() => kolitaCount--) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8338EC),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => kolitaCount++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8338EC),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Botón confirmar
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: totalGranizados > 0 ? _confirmarVenta : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06D6A0),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  totalGranizados > 0 
                      ? 'Confirmar Venta - ${formatter.format(totalPrecio)}'
                      : 'Selecciona granizados para continuar',
                  style: TextStyle(
                    color: totalGranizados > 0 ? Colors.white : Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> ventas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('ventas')
          .select()
          .order('fecha', ascending: false);
      
      setState(() {
        ventas = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _confirmarEliminarVenta(Map<String, dynamic> venta) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar esta venta?\n\n'
            'Sabor: ${venta['sabor']}\n'
            'Cantidad: ${venta['cantidad']}\n'
            'Total: ₡${NumberFormat('#,###').format(venta['total'])}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _eliminarVenta(venta['id']);
    }
  }

  Future<void> _eliminarVenta(int ventaId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('ventas')
          .delete()
          .eq('id', ventaId);
      
      // Recargar las ventas después de eliminar
      await _cargarVentas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, int> get ventasPorSabor {
    final Map<String, int> resultado = {};
    for (final venta in ventas) {
      final sabor = venta['sabor'] as String;
      final cantidad = venta['cantidad'] as int;
      resultado[sabor] = (resultado[sabor] ?? 0) + cantidad;
    }
    return resultado;
  }

  int get totalVentas {
    return ventas.fold(0, (sum, venta) => sum + (venta['total'] as int));
  }

  int get totalGranizados {
    return ventas.fold(0, (sum, venta) => sum + (venta['cantidad'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'es_CR',
      symbol: '₡',
      decimalDigits: 0,
    );

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ventasSabor = ventasPorSabor;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Dashboard de Ventas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarVentas,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Resumen general
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Ventas',
                      formatter.format(totalVentas),
                      const Color(0xFF06D6A0),
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Granizados Vendidos',
                      '$totalGranizados',
                      const Color(0xFF00B4D8),
                      Icons.icecream,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Gráfico de ventas por sabor
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ventas por Sabor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (ventasSabor.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'No hay datos de ventas',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: ventasSabor.entries.map((entry) {
                              final color = entry.key == 'Chicle' 
                                  ? const Color(0xFFFF006E) 
                                  : const Color(0xFF8338EC);
                              return PieChartSectionData(
                                color: color,
                                value: entry.value.toDouble(),
                                title: '${entry.value}',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ventasSabor.entries.map((entry) {
                        final color = entry.key == 'Chicle' 
                            ? const Color(0xFFFF006E) 
                            : const Color(0xFF8338EC);
                        return Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Historial de ventas recientes con opción de eliminar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ventas Recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ventas.isNotEmpty)
                          Text(
                            'Mantén presionado para eliminar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (ventas.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No hay ventas registradas',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...ventas.take(20).map((venta) {
                        final fecha = DateTime.parse(venta['fecha']);
                        final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: venta['sabor'] == 'Chicle' 
                                  ? const Color(0xFFFF006E) 
                                  : const Color(0xFF8338EC),
                              child: const Icon(Icons.icecream, color: Colors.white),
                            ),
                            title: Text('${venta['sabor']} (${venta['cantidad']})'),
                            subtitle: Text(fechaFormateada),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatter.format(venta['total']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmarEliminarVenta(venta),
                                  tooltip: 'Eliminar venta',
                                ),
                              ],
                            ),
                            onLongPress: () => _confirmarEliminarVenta(venta),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
}