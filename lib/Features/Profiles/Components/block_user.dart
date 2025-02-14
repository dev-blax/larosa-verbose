import 'package:flutter/material.dart';
import 'package:larosa_block/Utils/api_service.dart';

class BlockUserComponent extends StatefulWidget {
  final int profileId;
  const BlockUserComponent({super.key, required this.profileId});

  @override
  State<BlockUserComponent> createState() => _BlockUserComponentState();
}

class _BlockUserComponentState extends State<BlockUserComponent> {
  bool _isLoading = false;

  Future<void> _blockUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.blockUser(widget.profileId, context);

      if (success && mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 5000), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User blocked successfully')),
            );
          } 
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Block User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Are you sure you want to block this user? You won\'t see their posts and they won\'t be able to interact with you.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _blockUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Block User'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}