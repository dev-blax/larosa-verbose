import 'dart:async';
import 'dart:collection';
import '../../../Services/dio_service.dart';
import '../../../Services/log_service.dart';
import '../../../Utils/links.dart';

class ConversationController {
  final DioService _dioService = DioService();
  final Queue<int> _messageUpdateQueue = Queue<int>();
  bool _isProcessingQueue = false;
  Timer? _queueProcessor;

  ConversationController() {
    // Start the queue processor
    _queueProcessor = Timer.periodic(const Duration(seconds: 1), (_) {
      _processQueue();
    });
  }

  void dispose() {
    _queueProcessor?.cancel();
  }

  // Add message to queue for status update
  void queueMessageForStatusUpdate(int messageId) {
    if (!_messageUpdateQueue.contains(messageId)) {
      _messageUpdateQueue.add(messageId);
      LogService.logInfo('Added message $messageId to update queue');
    }
  }

  // Process the queue in the background
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageUpdateQueue.isEmpty) return;

    _isProcessingQueue = true;
    try {
      while (_messageUpdateQueue.isNotEmpty) {
        final messageId = _messageUpdateQueue.removeFirst();
        await updateMessageStatusToRead(messageId);
        // Add a small delay between requests to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  // Update message status to read
  Future<void> updateMessageStatusToRead(int messageId) async {
    try {
      final body = {
        'status': 'READ',
        'messageId': messageId,
      };
      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/message/status',
        data: body,
      );
    
      if (response.statusCode == 201) {
        final data = response.data;
        LogService.logInfo('Message status updated to read');
        LogService.logInfo('Response: $data');
      }
    } catch (e) {
      LogService.logError('Error updating message status to read: $e');
      // Re-queue the message if update failed
      queueMessageForStatusUpdate(messageId);
    }
  }



  // fetch user public key
  Future<String?> fetchUserPublicKey(int profileId) async {
    try {
      final response = await _dioService.dio.get(
        '${LarosaLinks.baseurl}/api/v1/keys/public/$profileId',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        LogService.logInfo('User public key fetched successfully');
        LogService.logInfo('Response: $data');
        return data;
      }
    } catch (e) {
      LogService.logError('Error fetching user public key: $e');
    }
    return null;
  }
}
