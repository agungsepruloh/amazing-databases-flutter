import 'package:moor_flutter/moor_flutter.dart';

part 'moor_database.g.dart';

class Tasks extends Table {
  // autoIncrement automatically sets this to be the primary key
  IntColumn get id => integer().autoIncrement()();
  // security because the field is nullable and we have first version of the apps and changes of the database
  // when the tasks don't have any reference in the tags table, the join table will not know what to do
  // as an exceptioin when we dont have any reference in the other tables, give references and NULL able again
  TextColumn get tagName =>
      text().nullable().customConstraint('NULL REFERENCES tags(name)')();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(Constant(false))();

  // how to set another properties as primary key
  // @override
  // Set<Column> get primaryKey => {id, name};
}

class Tags extends Table {
  TextColumn get name => text().withLength(min: 1, max: 10)();
  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {name};
}

class TaskWithTag {
  final Task task;
  final Tag tag;

  TaskWithTag({
    @required this.task,
    @required this.tag,
  });
}

@UseMoor(tables: [Tasks, Tags], daos: [TaskDao, TagDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          FlutterQueryExecutor.inDatabaseFolder(
              path: 'db.sqlite', logStatements: true),
        );

  @override
  int get schemaVersion => 2;

  // bump up schema version, and migration strategy
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // if the database run not the first time on the devices
          if (from == 1) {
            await migrator.addColumn(tasks, tasks.tagName);
            await migrator.createTable(tags);
          }
        },
      );
}

// Document Access Object
@UseDao(
  tables: [Tasks, Tags],
  queries: {
    'completedTasksGenerated':
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
  },
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;
  TaskDao(this.db) : super(db);

  // Future<List<Task>> getAllTasks() => select(tasks).get();

  // Stream<List<Task>> watchAllTasks() {
  //   return (select(tasks)
  //         ..orderBy([
  //           (t) => OrderingTerm(
  //                 expression: t.dueDate,
  //                 mode: OrderingMode.desc,
  //               ),
  //           (t) => OrderingTerm(
  //                 expression: t.name,
  //                 mode: OrderingMode.asc,
  //               ),
  //         ]))
  //       .watch();
  // }

  Stream<List<Task>> watchCompletedTasks() {
    return (select(tasks)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.dueDate,
                  mode: OrderingMode.desc,
                ),
            (t) => OrderingTerm(
                  expression: t.name,
                  mode: OrderingMode.asc,
                ),
          ])
          ..where(
            (t) => t.completed.equals(true),
          ))
        .watch();
  }

  Stream<List<TaskWithTag>> watchAllTasks() {
    return (select(tasks)
          ..orderBy(
            [
              (t) => OrderingTerm(
                    expression: t.dueDate,
                    mode: OrderingMode.desc,
                  ),
              (t) => OrderingTerm(
                    expression: t.name,
                    mode: OrderingMode.asc,
                  ),
            ],
          ))
        .join([
          leftOuterJoin(tags, tags.name.equalsExp(tasks.tagName)),
        ])
        .watch()
        .map(
          (rows) => rows.map(
            (row) {
              return TaskWithTag(
                  task: row.readTable(tasks), tag: row.readTable(tags));
            },
          ).toList(),
        );
  }

  Future insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}

@UseDao(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  final AppDatabase db;

  TagDao(this.db) : super(db);

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future insertTag(Insertable<Tag> tag) => into(tags).insert(tag);
}
