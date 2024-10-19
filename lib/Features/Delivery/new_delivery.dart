import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Utils/svg_paths.dart';

class NewDelivery extends StatefulWidget {
  const NewDelivery({super.key});

  @override
  State<NewDelivery> createState() => _NewDeliveryState();
}

class _NewDeliveryState extends State<NewDelivery> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title: const Text('Delivery'),
      ),
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://images.pexels.com/photos/28975090/pexels-photo-28975090/free-photo-of-tranquil-boat-ride-on-yamuna-river-at-dusk.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MENS GRENET TITANIUM WATCH'),
                      const Gap(05),
                      Row(
                        children: [
                          Text(
                            'Mitra Collections',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                          const Gap(5),
                          SvgPicture.asset(
                            SvgIconsPaths.sharpVerified,
                            colorFilter: const ColorFilter.mode(
                              Colors.blue,
                              BlendMode.srcIn,
                            ),
                            height: 18,
                          )
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.location_searching,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://images.pexels.com/photos/28975090/pexels-photo-28975090/free-photo-of-tranquil-boat-ride-on-yamuna-river-at-dusk.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MENS GRENET TITANIUM WATCH'),
                      const Gap(05),
                      Row(
                        children: [
                          Text(
                            'Mitra Collections',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                          const Gap(5),
                          SvgPicture.asset(
                            SvgIconsPaths.sharpVerified,
                            colorFilter: const ColorFilter.mode(
                              Colors.blue,
                              BlendMode.srcIn,
                            ),
                            height: 18,
                          )
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.location_searching),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
