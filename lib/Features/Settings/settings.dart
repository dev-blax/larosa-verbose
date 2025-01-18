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
            // const Text('Account Settings'),
            // TextFormField(
            //   decoration: const InputDecoration(hintText: 'Username'),
            // ),
            // const Gap(20),
            // TextFormField(
            //   decoration: const InputDecoration(hintText: 'Email'),
            // ),
            const Gap(20),
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change Password'),
                        Text(
                          'A verification request will be sent to you',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        )
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Iconsax.lock,
                        color: Colors.blue,
                      ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Verification'),
                        Text(
                          'Stand Out from Others with a verification badge',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        )
                      ],
                    ),
                    IconButton(
                      onPressed: () async {
                        //Get.to(const BusinessVerificationScreen());
                      },
                      icon: const Icon(
                        Iconsax.verify5,
                        color: Colors.blue,
                      ),
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

                // Get.offAll(const SigninScreen());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        HelperFunctions.logout(context);
                      },
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Logout'),
                          Text(
                            'Current Session data will be destroyed',
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        var userbox = Hive.box('userBox');
                        var onboardingBox = Hive.box('onboardingBox');
                        await userbox.clear();
                        await onboardingBox.clear();

                        // Get.offAll(const SigninScreen());
                      },
                      icon: const Icon(
                        Iconsax.logout_1,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Account'),
                        Text(
                          'All of your data on our platform will be deleted',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        )
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Iconsax.trash,
                        color: Colors.red,
                      ),
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
