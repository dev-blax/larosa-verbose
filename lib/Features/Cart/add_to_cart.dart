import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class AddToCartScreen extends StatefulWidget {
  const AddToCartScreen({super.key});

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  int itemCount = 1;

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
        title: const Text('Add To Cart'),
      ),
      body: ListView(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://images.pexels.com/photos/952629/pexels-photo-952629.jpeg',
                  height: 500,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      const SpinKitCircle(
                    color: Colors.blue,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                CachedNetworkImage(
                  imageUrl:
                      'https://images.pexels.com/photos/952629/pexels-photo-952629.jpeg',
                  height: 500,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      const SpinKitCircle(
                    color: Colors.blue,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vespera',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Colors.grey),
                ),
                Text(
                  'MENS GRENEM TITANIUM SUIT',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Gap(10),
                const Text('Description'),
                const Text(
                  'Some cool caption about the above suit to make the customr buy',
                ),
                const Gap(10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {
                        if (itemCount > 1) {
                          setState(() {
                            itemCount = itemCount - 1;
                          });
                        }
                      },
                      child: const Icon(Iconsax.minus),
                    ),
                    const Gap(20),
                    Text(itemCount.toString()),
                    const Gap(20),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = itemCount + 1;
                        });
                      },
                      child: const Text(
                        '+1',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const Gap(5),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = itemCount + 5;
                        });
                      },
                      child: const Text(
                        '+5',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const Gap(5),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = itemCount + 10;
                        });
                      },
                      child: const Text(
                        '+10',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Add To Cart'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel Order'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
