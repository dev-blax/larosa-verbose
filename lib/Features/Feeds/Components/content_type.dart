import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Utils/colors.dart';

enum ContentType {
  string,
  snippet,
  story,
  live,
}

class ContentTypeComponent extends StatefulWidget {
  final ContentType contentType;
  const ContentTypeComponent({super.key, required this.contentType});

  @override
  State<ContentTypeComponent> createState() => _ContentTypeComponentState();
}

class _ContentTypeComponentState extends State<ContentTypeComponent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: Icon(
                Icons.image_rounded,
                color: widget.contentType == ContentType.string
                    ? LarosaColors.black
                    : Colors.white,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(
                  widget.contentType == ContentType.string
                      ? LarosaColors.light
                      : Colors.black,
                ),
              ),
              label: Text(
                'String',
                style: TextStyle(
                  color: widget.contentType == ContentType.string
                      ? LarosaColors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
              //   => Get.off(
              //   const CameraContent(),
              //   transition: Transition.fadeIn,
              // )
              },
            ),
            const Gap(5),
            TextButton.icon(
              icon: SvgPicture.asset(
                'assets/svg_icons/reels.svg',
                colorFilter: ColorFilter.mode(
                  widget.contentType == ContentType.snippet
                      ? LarosaColors.black
                      : Colors.white,
                  BlendMode.srcIn,
                ),
                height: 20,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(
                  widget.contentType == ContentType.snippet
                      ? LarosaColors.light
                      : Colors.black,
                ),
              ),
              label: Text(
                'Snippet',
                style: TextStyle(
                  color: widget.contentType == ContentType.snippet
                      ? LarosaColors.black
                      : Colors.white,
                ),
              ),
              onPressed: () {
                // Get.off(
                //   const ReelCameraScreen(),
                //   transition: Transition.fadeIn,
                // );
              },
            ),
            const Gap(5),
            TextButton.icon(
              icon: const Icon(
                Iconsax.timer_start,
                color: Colors.white,
              ),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
              ),
              label: const Text(
                'Story',
                style: TextStyle(
                  color: Colors.white,
                ),
              ), // Ensure text is visible on black background
              onPressed: () {},
            ),
            const Gap(5),
            TextButton.icon(
              icon: const Icon(
                Iconsax.wifi,
                color: Colors.white,
              ),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
              ),
              label: const Text(
                'Live',
                style: TextStyle(
                  color: Colors.white,
                ),
              ), // Ensure text is visible on black background
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
