import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../Services/dio_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/links.dart';

class EmailVerificationCodeScreen extends StatefulWidget {
  final String email;
  const EmailVerificationCodeScreen({super.key, required this.email});

  @override
  State<EmailVerificationCodeScreen> createState() =>
      _EmailVerificationCodeScreenState();
}

class _EmailVerificationCodeScreenState
    extends State<EmailVerificationCodeScreen> {
  @override
  void initState() {
    super.initState();
  }

  final List<TextEditingController> controllers =
      List.generate(6, (index) => TextEditingController());

  String getCompleteCode() {
    return controllers.map((controller) => controller.text).join();
  }


  Future<void> verifyCode() async {
    try {
      var response = await DioService().dio.post(
        '${LarosaLinks.baseurl}/api/v1/verify-email',
        data: {
          'email': widget.email,
          'token': getCompleteCode(),
        },
      );

      if (response.statusCode == 200) {
        if(mounted){
          context.push('/home');
        }
      }
    } catch (e) {
      LogService.logError('Error in verifyCode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.back),
        ),
        title: const Text('Enter Verification Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  height: 45,
                  child: TextField(
                    controller: controllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    autofocus: index == 0,
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                    onSubmitted: (value) {
                      if (index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                    // onKeyEvent: (event) {
                    //   if (event is RawKeyDownEvent &&
                    //       event.logicalKey == LogicalKeyboardKey.backspace && 
                    //       index > 0 && 
                    //       controllers[index].text.isEmpty) {
                    //     controllers[index - 1].clear();
                    //     FocusScope.of(context).previousFocus();
                    //     return KeyEventResult.handled;
                    //   }
                    //   return KeyEventResult.ignored;
                    // },
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CupertinoColors.systemGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CupertinoColors.systemGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CupertinoColors.activeBlue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () {},
                child: const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
