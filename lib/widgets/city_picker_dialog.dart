import 'package:flutter/material.dart';
import '../models/city.dart';

class CityPickerDialog extends StatefulWidget {
  final List<City> allCities;
  final int? selectedCity;

  const CityPickerDialog({
    super.key,
    required this.allCities,
    this.selectedCity,
  });

  @override
  State<CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<CityPickerDialog> {
  late List<City> _filteredCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = [...widget.allCities];
  }

  void _filterCities(String text) {
    setState(() {
      _filteredCities = widget.allCities
          .where((c) => c.name.toLowerCase().contains(text.trim().toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите город'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск города',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: _filterCities,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredCities.isEmpty
                  ? const Center(
                child: Text(
                  'Города не найдены',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                itemCount: _filteredCities.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final city = _filteredCities[idx].name;
                  final id = _filteredCities[idx].id;
                  return ListTile(
                    title: Text(city),
                    trailing: widget.selectedCity == id
                        ? const Icon(
                      Icons.check,
                      color: Colors.blue,
                    )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(_filteredCities[idx]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('ОТМЕНА'),
        ),
      ],
    );
  }
}
