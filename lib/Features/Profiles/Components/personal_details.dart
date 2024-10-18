import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:larosa_block/Utils/colors.dart';

class PersonaDetailsComponent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  const PersonaDetailsComponent({
    super.key,
    required this.isLoading,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isLoading
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 100,
                  ),
                  child: const SpinKitCircle(
                    size: 16,
                    color: LarosaColors.primary,
                  ),
                )
              : Text(
                  '@${profile!['username']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          isLoading
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 100,
                  ),
                  child: const SpinKitCircle(
                    size: 16,
                    color: LarosaColors.primary,
                  ),
                )
              : const Text(
                  'Everything i do i like it',
                )
        ],
      ),
    );
  }
}
