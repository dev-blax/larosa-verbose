import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/auth_service.dart';
import '../Utils/colors.dart';

enum ActivePage {
  feeds,
  search,
  newPost,
  delivery,
  account,
}

class BottomNavigation extends StatefulWidget {
  final ActivePage activePage;
  final ScrollController? scrollController;

  const BottomNavigation({
    super.key,
    required this.activePage,
    this.scrollController,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null) return;

    if (widget.scrollController!.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isVisible) setState(() => _isVisible = false);
    } else if (widget.scrollController!.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isVisible) setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        height: _isVisible ? 60 : 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LarosaColors.primary.withOpacity(.3),
                LarosaColors.purple.withOpacity(.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), // Top left corner curve
              topRight: Radius.circular(20), // Top right corner curve
              bottomLeft: Radius.circular(50), // Bottom left corner curve
              bottomRight: Radius.circular(50), // Bottom right corner curve
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isActive: widget.activePage == ActivePage.feeds,
                  onTap: () => context.goNamed('home'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.search_outlined,
                  label: 'Search',
                  isActive: widget.activePage == ActivePage.search,
                  onTap: () => context.push('/search'),
                ),
                _buildFloatingActionButton(context),
                _buildNavItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery',
                  isActive: widget.activePage == ActivePage.delivery,
                  onTap: () {
                    if (AuthService.getToken().isEmpty) {
                      context.pushNamed('login');
                      return;
                    }
                    context.pushNamed('maindelivery');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isActive: widget.activePage == ActivePage.account,
                  onTap: () {
                    if (AuthService.getToken().isNotEmpty) {
                      context.pushNamed('homeprofile');
                    } else {
                      context.pushNamed('login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            // height: isActive ? 28 : 22, // Larger size for active
            // width: isActive ? 28 : 22,
            child: Icon(
              icon,
              // size: isActive ? 30 : 22,
              // color: isActive ? LarosaColors.secondary : Colors.black87,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
          // if (isActive) ...[
          //   // const SizedBox(height: 4), // Spacing between icon and label
          //   Text(
          //     label,
          //     style: TextStyle(
          //       fontSize: 12, // Adjust font size as needed
          //       fontWeight: FontWeight.bold,
          //       color: Colors.white,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (AuthService.getToken().isEmpty) {
          context.pushNamed('login');
          return;
        }
        context.pushNamed('main-post');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LarosaColors.secondary, LarosaColors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LarosaColors.purple.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
