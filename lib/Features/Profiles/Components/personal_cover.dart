import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';

class PersonalCoverComponent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  const PersonalCoverComponent({
    super.key,
    required this.isLoading,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        isLoading
            ? Image.asset(
                'assets/gifs/loader.gif',
                height: 200,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              )
            : CachedNetworkImage(
                imageUrl: isLoading
                    ? 'https://images.pexels.com/photos/1590549/pexels-photo-1590549.jpeg?auto=compress&cs=tinysrgb&w=600'
                    : profile!['coverPhoto'] ??
                        'https://images.pexels.com/photos/1590549/pexels-photo-1590549.jpeg?auto=compress&cs=tinysrgb&w=600',
                height: 200,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          left: 10,
          child: isLoading
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    Text(
                      profile!['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    if (profile!['verificationStatus'] != 'UNVERIFIED')
                      const Icon(
                        Iconsax.verify5,
                        color: Colors.blue,
                      )
                  ],
                ),
        ),

        // profile image
        Positioned(
          right: 12,
          bottom: -70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: isLoading
                ? Image.asset(
                    'assets/images/EXPLORE.png',
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  )
                : profile!['profilePicture'] != null
                    ? CachedNetworkImage(
                        imageUrl: profile!['profilePicture'],
                        fit: BoxFit.cover,
                        height: 140,
                        width: 140,
                        filterQuality: FilterQuality.low,
                      )
                    : Image.asset(
                        'assets/images/EXPLORE.png',
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
          ),
        ),
      ],
    );
  }
}
