import 'package:flutter/material.dart';

class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selectedIndex = 0;
  
  final List<String> _categories = [
    'All',
    'Nature',
    'Cities',
    'Beaches',
    'Mountains',
    'Historical',
    'Adventure'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: _selectedIndex == index,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedIndex = index);
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: _selectedIndex == index ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Colors.grey[100],
            ),
          );
        },
      ),
    );
  }
}
