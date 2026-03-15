import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import 'create_meal_page.dart';
import 'create_member_page.dart';
import 'decide_dishwasher_page.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});

  final ApiService api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  List<Member> _members = const [];
  List<Meal> _meals = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.fetchMembers(),
        widget.api.fetchMeals(),
      ]);

      if (!mounted) return;
      setState(() {
        _members = results[0] as List<Member>;
        _meals = results[1] as List<Meal>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateMember() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateMemberPage(api: widget.api)),
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openCreateMeal() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateMealPage(api: widget.api)),
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openDecideDishwasher() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DecideDishwasherPage(api: widget.api)),
    );
    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cucinometro Mobile'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Errore API: $_error'),
                  ),
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Home'),
                          Tab(text: 'Statistiche'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildHomeContent(),
                            StatisticsPage(meals: _meals),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _buildActions(),
    );
  }

  Widget _buildHomeContent() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Membri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _members.map((m) => Chip(label: Text(m.name))).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Pasti recenti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._meals.map(
          (meal) => Card(
            child: ListTile(
              title: Text('${meal.date} - ${meal.kind == 'lunch' ? 'Pranzo' : 'Cena'}'),
              subtitle: Text('Partecipanti: ${meal.participants.join(', ')}'),
              trailing: Text(meal.dishwasher ?? '-'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle),
      onSelected: (value) {
        if (value == 'member') {
          _openCreateMember();
        } else if (value == 'meal') {
          _openCreateMeal();
        } else if (value == 'decide') {
          _openDecideDishwasher();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'member', child: Text('Nuovo membro')),
        PopupMenuItem(value: 'meal', child: Text('Nuovo pasto')),
        PopupMenuItem(value: 'decide', child: Text('Decidi lavapiatti')),
      ],
    );
  }
}
