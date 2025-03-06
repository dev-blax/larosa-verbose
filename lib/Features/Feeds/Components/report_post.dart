import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Components/snackbar.dart';

class ReportPostComponent extends StatefulWidget {
  final String postId;
  const ReportPostComponent({super.key, required this.postId});

  @override
  State<ReportPostComponent> createState() => _ReportPostComponentState();
}

class _ReportPostComponentState extends State<ReportPostComponent> {
  bool _isLoading = false;
  String _selectedReason = 'HARASSMENT';
  final _detailsController = TextEditingController();
  final dio = Dio();

  final List<String> _reportReasons = [
    'HARASSMENT',
    'HATE_SPEECH',
    'EXPLICIT_CONTENT',
    'SPAM',
    'IMPERSONATION',
    'FRAUD',
    'OTHER'
  ];

  Future<void> _reportPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LogService.logInfo('Reporting post: ${widget.postId}');

      final response = await dio.post(
        '${LarosaLinks.baseurl}/api/v1/report-posts',
        data: {
          'reportedPostId': widget.postId,
          'reason': _selectedReason,
          'additionalDetails': _detailsController.text.trim(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AuthService.getToken()}',
          },
        ),
      );

      LogService.logInfo('Report post response received');

      if (response.statusCode == 201 && mounted) {
        Navigator.pop(context);
        TopSnackBar(
          message: 'Post reported successfully',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ).show(context);
      } else {
        LogService.logError('Failed to report post: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to report post: ${e.toString()}');
      if (mounted) {
        TopSnackBar(
          message: 'Failed to report post',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ).show(context);
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
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason for reporting',
                border: OutlineInputBorder(),
              ),
              items: _reportReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReason = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _reportPost,
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
                      : const Text('Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}