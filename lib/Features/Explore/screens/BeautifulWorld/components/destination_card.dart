import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DestinationCard extends StatelessWidget {
  final int index;
  
  const DestinationCard({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data - in a real app, this would come from a data source
    final List<Map<String, dynamic>> destinations = [
      {
        'name': 'Santorini, Greece',
        'description': 'Iconic white-washed buildings with blue domes',
        'image': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff',
        'rating': 4.8,
      },
      {
        'name': 'Machu Picchu, Peru',
        'description': 'Ancient Incan city in the clouds',
        'image': 'https://images.pexels.com/photos/3706960/pexels-photo-3706960.jpeg',
        'rating': 4.9,
      },
      {
        'name': 'Bali, Indonesia',
        'description': 'Tropical paradise with rich culture',
        'image': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4',
        'rating': 4.7,
      },
      {
        'name': 'Venice, Italy',
        'description': 'City of canals and romance',
        'image': 'https://images.unsplash.com/photo-1514890547357-a9ee288728e0',
        'rating': 4.6,
      },
      {
        'name': 'Great Barrier Reef',
        'description': 'World\'s largest coral reef system',
        'image': 'https://images.unsplash.com/photo-1582967788606-a171c1080cb0',
        'rating': 4.9,
      },
    ];
    
    final destination = destinations[index % destinations.length];

    return GestureDetector(
      onTap: () {
        // Handle destination tap
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: index.isEven ? 3/4 : 4/3,
                      child: CachedNetworkImage(
                        imageUrl: destination['image']!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                        
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination['rating'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination['description']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
