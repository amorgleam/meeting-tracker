import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';

abstract class LocalDbBackend {
  Future<void> init();

  void insertMember(Member member, {bool enqueueOutbox = true});
  List<Member> getMembers();

  void insertMeeting(Meeting meeting, {bool enqueueOutbox = true});
  List<Meeting> getMeetings();

  void insertTask(TaskItem task, {bool enqueueOutbox = true});
  List<TaskItem> getTasks();

  void insertActivityLog(ActivityLog log, {bool enqueueOutbox = true});
  List<ActivityLog> getActivityLogs();

  List<Map<String, dynamic>> getPendingOutbox();
  void removeOutboxItem(String id);
  void incrementOutboxAttempts(String id, String error);

  String? getMetadata(String key);
  void setMetadata(String key, String value);

  String getPlatformLabel();
  void close();
}
