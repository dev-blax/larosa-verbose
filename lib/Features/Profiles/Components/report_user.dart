import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:larosa_block/Utils/links.dart';

import '../../../Components/snackbar.dart';
import '../../../Services/auth_service.dart';
import '../../../Services/log_service.dart';

class ReportUserComponent extends StatefulWidget {
  final int reportProfileId;
  const ReportUserComponent({super.key, required this.reportProfileId});

  @override
  State<ReportUserComponent> createState() => _ReportUserComponentState();
}

class _ReportUserComponentState extends State<ReportUserComponent> {
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

  Future<void> _reportUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LogService.logInfo('Requesting report token: ${AuthService.getToken()}');
      LogService.logInfo('reportprofileID ${widget.reportProfileId.toString()}');

      final response = await dio.post(
        '${LarosaLinks.baseurl}/api/v1/report-accounts',
        data: {
          'reportedProfileId': widget.reportProfileId,
          'reason': _selectedReason,
          'additionalDetails': _detailsController.text.trim(),
        },
        options: Options(
          headers: {
            "Access-Control-Allow-Origin": "*",
            'Authorization': 'Bearer ${AuthService.getToken()}',
          },
        ),
      );

      LogService.logInfo('Got response');

      if (response.statusCode == 201 && mounted) {
        Navigator.pop(context);
        TopSnackBar(
          message: 'User reported successfully',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ).show(context);
      } else {
        LogService.logError('Failed to report user: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to report user: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to report user')),
        );
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Report User',
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
                child: Text(reason.replaceAll('_', ' ').toUpperCase()),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _reportUser,
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
                    : const Text('Report User'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
