import 'package:drift/drift.dart';

// Drift Table Schema Definitions for Offline-First Architecture

class MembersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get designation => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class MeetingsTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get meetingDate => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get attendeeMemberIds => text().nullable()(); // JSON encoded list
  TextColumn get status => text().withDefault(const Constant('In Progress'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class TasksTable extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId => text()();
  TextColumn get parentTaskId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Pending'))();
  TextColumn get assignedMemberIds => text().nullable()(); // JSON encoded list
  TextColumn get note => text().nullable()();
  DateTimeColumn get originMeetingDate => dateTime()();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isOverridden => boolean().withDefault(const Constant(false))();
  TextColumn get overrideReason => text().nullable()();
  TextColumn get overrideBy => text().nullable()();
  DateTimeColumn get overrideAt => dateTime().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get meetingId => text().nullable()();
  TextColumn get taskTitle => text()();
  TextColumn get oldState => text()();
  TextColumn get newState => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isOverride => boolean().withDefault(const Constant(false))();
  TextColumn get overrideReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class OutboxQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // member, meeting, task, activity_log
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON representation
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
