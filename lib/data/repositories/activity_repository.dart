import '../../services/api_client.dart';
import '../models/activity_model.dart';
import '../../core/constants/api_constants.dart';

class ActivityRepository {
  final ApiClient apiClient;

  ActivityRepository({required this.apiClient});

  Future<({List<ActivityModel> activities, int? nextPage})> getActivities({int page = 1}) async {
    try {
      final body = await apiClient.get('${ApiConstants.activities}?page=$page') as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;
      final activities = data.map((json) => ActivityModel.fromJson(json)).toList();
      
      final nextPageUrl = body['next_page_url'];
      final nextPage = nextPageUrl != null ? page + 1 : null;

      return (activities: activities, nextPage: nextPage);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load activity feed');
    }
  }
}
