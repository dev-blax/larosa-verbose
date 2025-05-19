import 'package:flutter/material.dart';
import 'movie_poster_card.dart';
import '../model/Movie.dart';

class MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  const MovieGrid({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return MoviePosterCard(movie: movies[index]);
        },
        childCount: movies.length,
      ),
    );
  }
}
