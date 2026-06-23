import '../../services/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<({List<NotificationModel> notifications, String? nextCursor})> getNotifications({String? cursor}) async {
    try {
      final path = cursor != null ? '/notifications?cursor=$cursor' : '/notifications';
      final body = await apiClient.get(path) as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      final String? nextCursor = body['next_cursor'] as String?;

      return (notifications: notifications, nextCursor: nextCursor);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load notifications');
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      final body = await apiClient.put('/notifications/$id/read') as Map<String, dynamic>;
      return NotificationModel.fromJson(body['data']);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await apiClient.put('/notifications/read-all');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to mark all notifications as read');
    }
  }
}
