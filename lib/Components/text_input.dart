import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TextInputComponent extends StatefulWidget {
  final IconData iconData;
  final String label;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final bool formatAsMoney;
  final bool readOnly;
  final Function()? onTap;

  const TextInputComponent({
    super.key,
    required this.label,
    required this.controller,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.formatAsMoney = false,
    this.readOnly = false,
    this.onTap,
    required this.iconData,
  });

  @override
  State<TextInputComponent> createState() => _TextInputComponentState();
}

class _TextInputComponentState extends State<TextInputComponent> {
  late TextEditingController _controller;
  bool hideText = false;

  @override
  void initState() {
    super.initState();

    if (widget.isPassword) {
      hideText = widget.isPassword;
    }

    _controller = widget.controller;
    if (widget.formatAsMoney) {
      _controller.addListener(_formatMoney);
    }
  }

  void _formatMoney() {
    final value = _controller.text.replaceAll(',', '');
    if (value.isEmpty) return;

    final formatter = NumberFormat('#,###');
    final formattedValue = formatter.format(int.parse(value));
    if (_controller.text != formattedValue) {
      _controller.value = _controller.value.copyWith(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  @override
  void dispose() {
    if (widget.formatAsMoney) {
      _controller.removeListener(_formatMoney);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        hintText: widget.label,
        hintStyle: const TextStyle(color: Colors.white),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    hideText = !hideText;
                  });
                },
                icon: Icon(
                  hideText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                  color: CupertinoColors.white,
                ))
            : null,
        prefixIcon: Icon(
          widget.iconData,
          size: 18,
          color: CupertinoColors.white,
        ),
        filled: false,
        fillColor: Colors.white.withOpacity(.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CupertinoColors.white,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CupertinoColors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CupertinoColors.white,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CupertinoColors.white,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CupertinoColors.white,
          ),
        ),
      ),
      style: TextStyle(color: CupertinoColors.white, fontSize: 16),
      keyboardType: widget.inputType,
      obscureText: hideText,
      validator: widget.validator,
    );
  }
}
