import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../Components/loading_shimmer.dart';
import 'components/destination_card.dart';
import 'components/explore_header.dart';
import 'components/category_chips.dart';

class BeautifulWorldScreen extends StatefulWidget {
  const BeautifulWorldScreen({super.key});

  @override
  State<BeautifulWorldScreen> createState() => _BeautifulWorldScreenState();
}

class _BeautifulWorldScreenState extends State<BeautifulWorldScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: ExploreHeader(),
            ),
            const SliverToBoxAdapter(
              child: CategoryChips(),
            ),
            _isLoading
                ? SliverToBoxAdapter(
                    child: LoadingShimmer(
                      //height: MediaQuery.of(context).size.height * 0.7,
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemBuilder: (context, index) {
                        final animation = Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index * 0.1).clamp(0, 1),
                              ((index + 1) * 0.1).clamp(0, 1),
                              curve: Curves.easeOut,
                            ),
                          ),
                        );
                        
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(animation),
                            child: DestinationCard(
                              index: index,
                            ),
                          ),
                        );
                      },
                      childCount: 10, // Number of destinations
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
