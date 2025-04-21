import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:http/http.dart' as http;

import '../../Services/auth_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/links.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _deleteAccount(String reason, {String? comments}) async {
    String token = AuthService.getToken();
    if (token.isEmpty) return false;

    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/api/v1/account-deletion');

    var body = {
      'reason': reason,
    };
    if (comments != null && comments.isNotEmpty) {
      body['comments'] = comments;
    }else {
      body['comments'] = 'Not Filled';
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return true;
      }
    } catch (e) {
      print("Account deletion exception: $e");
      return false;
    }
  }


Future<Map<String, String>?> _showDeletionDialog(BuildContext context) {
  String selectedReason = "USER_REQUESTED";
  TextEditingController commentsController = TextEditingController();

  // Define a common gradient to use for the header and buttons.
  final Gradient commonGradient = LinearGradient(
    colors: [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom header with a gradient background.
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: commonGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Dialog content.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    items: const [
                      DropdownMenuItem(
                        value: 'USER_REQUESTED',
                        child: Text('User Requested'),
                      ),
                      DropdownMenuItem(
                        value: 'TERMS_VIOLATION',
                        child: Text('Terms Violation'),
                      ),
                      DropdownMenuItem(
                        value: 'INACTIVITY',
                        child: Text('Inactivity'),
                      ),
                      DropdownMenuItem(
                        value: 'FRAUDULENT_ACTIVITY',
                        child: Text('Fraudulent Activity'),
                      ),
                      DropdownMenuItem(
                        value: 'OTHER',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedReason = value;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Additional Comments (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dialog actions with gradient buttons.
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button.
                  InkWell(
                    onTap: () => Navigator.of(context).pop(null),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: commonGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cancel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Confirm button.
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop({
                        'reason': selectedReason,
                        'comments': commentsController.text,
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: commonGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Confirm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


  // This method handles the deletion flow: confirmation, API call, and navigation.
  void _handleAccountDeletion(BuildContext context) async {
  final input = await _showDeletionDialog(context);
  if (input == null) return; // User canceled

  String reason = input['reason']!;
  String comments = input['comments'] ?? '';

  // Show a loading indicator while processing.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CupertinoActivityIndicator(color: LarosaColors.secondary,)),
  );

  bool success = await _deleteAccount(reason, comments: comments);

  // Hide the loading indicator.
  Navigator.of(context).pop();

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion successful.')),
    );
    // Navigate to home route.

    // context.go('/');
    HelperFunctions.simulateLogout(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion failed.')),
    );
  }
}


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
            
            // const Gap(20),

            // InkWell(
            //   onTap: () {},
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     decoration: BoxDecoration(
            //       color: Theme.of(context).colorScheme.surface,
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.lock, color: Colors.grey),
            //         const SizedBox(width: 12),
            //         const Text(
            //           'Change Password',
            //           style: TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.w500,
            //             color: Colors.grey,
            //           ),
            //         ),
            //         const Spacer(),
            //         Icon(
            //           Icons.chevron_right,
            //           color: Colors.grey[600],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            
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
              onTap: () {
                _handleAccountDeletion(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.trash, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
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


            // InkWell(
            //   onTap: () {
            //     _handleAccountDeletion(context);
            //   },
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         const Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text('Delete Account'),
            //             Text(
            //               'All of your data on our platform will be deleted',
            //               style: TextStyle(
            //                 fontSize: 10,
            //               ),
            //             )
            //           ],
            //         ),
            //         IconButton(
            //           onPressed: () {
            //             _handleAccountDeletion(context);
            //           },
            //           icon: const Icon(
            //             Iconsax.trash,
            //             color: Colors.red,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}
