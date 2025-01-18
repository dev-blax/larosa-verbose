import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';

class CustomSearchDelegate extends SearchDelegate {
  final String apiUrl = '${LarosaLinks.baseurl}/search/suggestive';

  Future<List<dynamic>> fetchSearchResults(String query) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'profileId': AuthService.getProfileId(),
        'keyword': query,
        'countryId': 1,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 403 || response.statusCode == 302) {
      await AuthService.refreshToken();
      return await fetchSearchResults(query);
    } else {
      LogService.logError('Failed: response = ${response.statusCode}');
      throw Exception('Failed to load search results');
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(
        Iconsax.arrow_left_2,
        color: LarosaColors.primary,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: fetchSearchResults(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SpinKitCircle(
            color: LarosaColors.primary,
          ));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var result = snapshot.data![index];
              return ListTile(
                leading: result['profilePicture'] != null
                    ? Image.network(result['profilePicture'])
                    : CircleAvatar(
                        child: Text(result['username'][0]),
                      ),
                title: Text(result['name']),
                subtitle: Text(result['username']),
                trailing: result['verificationStatus'] == 1
                    ? const Icon(Icons.verified, color: Colors.blue)
                    : null,
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
        future: fetchSearchResults(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SpinKitCircle(
              color: LarosaColors.primary,
            ));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Cannot load suggestions...'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No suggestions found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var result = snapshot.data![index];
                return Animate(
                  effects: [
                    SlideEffect(
                      begin: const Offset(0, -1),
                      end: const Offset(0, 0),
                      curve: Curves.elasticOut,
                      duration: const Duration(seconds: 3),
                      delay: Duration(milliseconds: 100 * index),
                    )
                  ],
                  child: ListTile(
                    leading: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Powersize',
                          style: TextStyle(
                            color: LarosaColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          result['powerSize'].toString(),
                          style: const TextStyle(
                            color: LarosaColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                    title: Row(
                      children: [
                        Text(result['name']),
                        const Gap(5),
                        if (result['verificationStatus'] != 1)
                          SvgPicture.asset(
                            'assets/svg_icons/IcSharpVerified.svg',
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.secondary,
                              BlendMode.srcIn,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('@${result['username']}'),
                    trailing: result['profilePicture'] != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: result['profilePicture'],
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : ClipOval(
                            child: Image.asset(
                              'assets/images/EXPLORE.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                    onTap: () {
                      final token = AuthService.getToken();
                      if (token.isEmpty) {
                        context.pushNamed('login');
                        return;
                      }

                      final int accountType = result['account_type'];
                      LogService.logDebug('account type: $accountType');

                      if (AuthService.getProfileId() == result['profileId']) {
                        context.pushNamed('homeprofile');
                        return;
                      }
                      context.push(
                        '/profilevisit/?profileId=${result['profileId']}&accountType=$accountType',
                      );
                    },
                  ),
                );
              },
            );
          }
        });
  }
}
