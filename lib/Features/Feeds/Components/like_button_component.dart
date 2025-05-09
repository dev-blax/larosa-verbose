import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:like_button/like_button.dart';
import 'package:larosa_block/Utils/colors.dart';

class LarosaLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final Function(bool) onTap;
  final double size;
  final bool showBackground;

  const LarosaLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.size = 23.0,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: showBackground 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : EdgeInsets.zero,
      decoration: showBackground ? BoxDecoration(
        color: isLiked 
            ? LarosaColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ) : null,
      child: LikeButton(
        size: size,
        isLiked: isLiked,
        likeCount: likeCount,
        animationDuration: const Duration(milliseconds: 500),
        bubblesColor: const BubblesColor(
          dotPrimaryColor: Color.fromRGBO(180, 23, 12, 1),
          dotSecondaryColor: Colors.orange,
          dotThirdColor: Colors.yellow,
          dotLastColor: Colors.red,
        ),
        circleColor: const CircleColor(
          start: Color.fromRGBO(255, 204, 0, 1),
          end: Color.fromRGBO(180, 23, 12, 1),
        ),
        likeBuilder: (bool isLiked) {
          return SvgPicture.asset(
            isLiked
                ? 'assets/icons/SolarHeartAngleBold.svg'
                : 'assets/icons/SolarHeartAngleLinear.svg',
            colorFilter: ColorFilter.mode(
              isLiked
                  ? const Color.fromRGBO(180, 23, 12, 1)
                  : Theme.of(context).colorScheme.secondary,
              BlendMode.srcIn,
            ),
            semanticsLabel: 'Like icon',
          );
        },
        likeCountPadding: const EdgeInsets.only(left: 4.0),
        countBuilder: (int? count, bool isLiked, String text) {
          if (count == 0) return const SizedBox.shrink();
          return Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:  Colors.grey,
            ),
          );
        },
        onTap: (bool isLiked) async {
          onTap(isLiked);
          return !isLiked;
        },
      ),
    );
  }
}
