import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/auth_service.dart';

class TopBar1 extends StatelessWidget {
  const TopBar1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (AuthService.getToken().isEmpty) {
                context.pushNamed('login');
                return;
              }
              context.pushNamed('chatsland');
            },
            icon: SvgPicture.asset(
              'assets/svg_icons/chats-double.svg',
              width: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondary,
                BlendMode.srcIn,
              ),
              semanticsLabel: 'chat icon',
            ),
          ),
          Text(
            'Explore Larosa',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            onPressed: () {
              context.pushNamed('maincart');
            },
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
