import 'package:flutter/material.dart';

class MoviesHeader extends StatelessWidget {
  const MoviesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Movies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  // Implement search
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGenreChip('All', true),
                _buildGenreChip('Action', false),
                _buildGenreChip('Drama', false),
                _buildGenreChip('Comedy', false),
                _buildGenreChip('Sci-Fi', false),
                _buildGenreChip('Horror', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          // Implement genre filter
        },
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.white,
        checkmarkColor: Colors.transparent,
      ),
    );
  }
}
