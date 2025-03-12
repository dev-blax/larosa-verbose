import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Utils/helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(20),

            InkWell(
              onTap: () => context.pushNamed('blockedList'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text(
                      'Blocked Users',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            
            const Gap(20),

            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            
            const Gap(20),

            InkWell(
              onTap: () {
                context.push('/verification');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.verify5, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Request Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            
            const Gap(20),
            InkWell(
              onTap: () async {
                var userbox = Hive.box('userBox');
                var onboardingBox = Hive.box('onboardingBox');
                await userbox.clear();
                await onboardingBox.clear();

                if (context.mounted) HelperFunctions.logout(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.logout_1, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),
            
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.trash, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}
