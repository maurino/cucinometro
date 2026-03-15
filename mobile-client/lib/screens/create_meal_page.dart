import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';

class CreateMealPage extends StatefulWidget {
  const CreateMealPage({super.key, required this.api});

  final ApiService api;

  @override
  State<CreateMealPage> createState() => _CreateMealPageState();
}

class _CreateMealPageState extends State<CreateMealPage> {
  DateTime _selectedDate = DateTime.now();
  String _kind = 'dinner';
  bool _loading = true;
  bool _saving = false;
  List<Member> _members = const [];
  final Set<String> _selectedParticipants = <String>{};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final members = await widget.api.fetchMembers();
      if (!mounted) return;
      setState(() {
        _members = members;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore caricamento membri: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un partecipante')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createMeal(
        date: _isoDate(_selectedDate),
        kind: _kind,
        participants: _selectedParticipants.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore creazione pasto: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo pasto')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Data: ${_isoDate(_selectedDate)}')),
                      TextButton(onPressed: _pickDate, child: const Text('Cambia')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _kind,
                    items: const [
                      DropdownMenuItem(value: 'lunch', child: Text('Pranzo')),
                      DropdownMenuItem(value: 'dinner', child: Text('Cena')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _kind = value);
                    },
                    decoration: const InputDecoration(labelText: 'Tipo pasto'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Partecipanti', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: _members.map((member) {
                        final selected = _selectedParticipants.contains(member.name);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(member.name),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedParticipants.add(member.name);
                              } else {
                                _selectedParticipants.remove(member.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Salvataggio...' : 'Crea pasto'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String _isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
