import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:larosa_block/Utils/colors.dart';

class StatisticsComponent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final int followers;
  const StatisticsComponent({
    super.key,
    required this.isLoading,
    this.profile,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Powersize',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              isLoading
                  ? const SpinKitCircle(
                      size: 16,
                      color: LarosaColors.primary,
                    )
                  : Text(
                      profile!['powerSize'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    )
            ],
          ),
          Column(
            children: [
              Text(
                'Strings',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              isLoading
                  ? const SpinKitCircle(
                      size: 16,
                      color: LarosaColors.primary,
                    )
                  : Text(
                      profile!['posts'].toString(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
            ],
          ),
          Column(
            children: [
              Text(
                'Following',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              isLoading
                  ? const SpinKitCircle(
                      size: 16,
                      color: LarosaColors.primary,
                    )
                  : Text(
                      profile!['following'].toString(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
            ],
          ),
          Column(
            children: [
              Text(
                'Followers',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              isLoading
                  ? const SpinKitCircle(
                      size: 12,
                      color: LarosaColors.primary,
                    )
                  : Text(
                      followers.toString(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )
            ],
          ),
        ],
      ),
    );
  }
}
