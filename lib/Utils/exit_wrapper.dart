import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ExitWrapper extends StatelessWidget {
  final Widget child;

  const ExitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Show exit confirmation dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Exit'),
            content: const Text('Do you want to exit Explore Larosa?'),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  SystemNavigator.pop();
                },
                isDestructiveAction: true,
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}
