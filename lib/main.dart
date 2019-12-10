import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_databases/data/moor_database.dart';

import 'package:amazing_databases/ui/home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => AppDatabase(),
      child: MaterialApp(
        title: 'Flutter Demo',
        home: HomePage(),
      ),
    );
  }
}
