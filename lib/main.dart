import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/homepage.dart';
import 'screens/impacto.dart';
import 'screens/inventario.dart';
import 'screens/lista_compras.dart';
import 'screens/receitas.dart';
import 'screens/admin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frigorífico',
      // tema global, em theme/app_theme.dart
      theme: appTheme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  // _ = privado a este ficheiro
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;
  //so o homeShellState precisa de aceder ao _ecras
  final List<Widget> _ecras = const [
    Homepage(),
    Inventario(),
    Receitas(),
    Impacto(),
    ListaCompras(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frigu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Admin()),
              );
            },
          ),
        ],
      ),
      // IndexedStack mantém os ecrãs vivos ao trocar de separador
      body: IndexedStack(index: _indice, children: _ecras),
      // o separador tocado muda o _indice e o ecrã visível
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          setState(() {
            _indice = i;
          });
        },
        // mesma ordem que _ecras
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'), // 0
          NavigationDestination(
            icon: Icon(Icons.kitchen),
            label: 'Inventário',
          ), // 1
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ), // 2
          NavigationDestination(icon: Icon(Icons.eco), label: 'Impacto'), // 3
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ), // 4
        ],
      ),
    );
  }
}
