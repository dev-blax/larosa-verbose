import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Delivery'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  label: const Text('Source'),
                  prefixIcon: const Icon(Ionicons.location),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Ionicons.locate,
                    ),
                  ),
                ),
              ),
              const Gap(10),
              const TextField(
                decoration: InputDecoration(
                  
                  prefixIcon: Icon(Ionicons.location_sharp),
                  contentPadding: EdgeInsets.all(8),
                  label: Text('Destination'),
                ),
              ),
              const Gap(10),
              FilledButton(
                onPressed: () {},
                child: const Text('Requst a Ride'),
              ),
              const Gap(20),
              const Text('Your Orders'),
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
          const Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: BottomNavigation(
                activePage: ActivePage.delivery,
              ),
            ),
        ],
      ),
    );
  }
}
