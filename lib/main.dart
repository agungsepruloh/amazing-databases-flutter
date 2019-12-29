import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_databases/data/moor_database.dart';

import 'package:amazing_databases/ui/home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();

    return MultiProvider(
      providers: [
        Provider(create: (_) => db.taskDao),
        Provider(create: (_) => db.tagDao),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: HomePage(),
      ),
    );
  }
}
