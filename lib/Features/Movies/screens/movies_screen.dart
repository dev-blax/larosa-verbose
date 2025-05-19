import 'package:flutter/material.dart';
import '../components/featured_movie_card.dart';
import '../components/movie_grid.dart';
import '../components/movies_header.dart';
import '../model/Movie.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _scrollController = ScrollController();
  bool isLoading = true;

  // movies list
  List<Movie> movies = [
    Movie(
      title: 'John Wick',
      posterPath:
          'https://i.pinimg.com/736x/25/82/b4/2582b4a9b2174193380ad366886ee5a3.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    Movie(
      title: 'The Killer',
      posterPath:
          'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    Movie(
      title: 'Kraven The Hunter',
      posterPath:
          'https://i.pinimg.com/736x/61/d9/6a/61d96a650ba37a16bcec8fa5e80e4eec.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    Movie(
      title: 'The Flash',
      posterPath:
          'https://i.pinimg.com/736x/78/a7/9b/78a79b3e28c3f10a23dc13bfa6a82f3f.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    Movie(
      title: 'The Fall Guy',
      posterPath:
          'https://i.pinimg.com/736x/c3/e0/98/c3e098b7f1b03fd1ae39d6486f3377ce.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    Movie(
      title: 'The Shadow Strays',
      posterPath:
          'https://i.pinimg.com/736x/6c/39/e0/6c39e0b0ba1337a2921daa488080d491.jpg',
      overview: 'Overview 1',
      rating: 4.5,
      releaseDate: 2022,
    ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
    // Movie(
    //   title: 'The Killer',
    //   posterPath:
    //       'https://i.pinimg.com/736x/c8/25/c5/c825c5a2e7e83912c43298b8d082591b.jpg',
    //   overview: 'Overview 1',
    //   rating: 4.5,
    //   releaseDate: 2022,
    // ),
  ];

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: MoviesHeader(),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 400,
                child: PageView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return const FeaturedMovieCard();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Trending Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: MovieGrid(
                movies: movies,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
