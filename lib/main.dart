import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Database _database;
  List<String> tasks = [];

  @override
  void initState() {
    super.initState();
    _openDatabase();
  }

  void _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tasks.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) {
        db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task TEXT
          )
        ''');
      },
    );

    _loadTasks();
  }

  void _loadTasks() async {
    final List<Map<String, dynamic>> maps = await _database.query('tasks');
    tasks = List.generate(maps.length, (i) {
      return maps[i]['task'] as String;
    });
    setState(() {});
  }

  void _addTask(String task) async {
    final Map<String, dynamic> row = {
      'task': task,
    };
    await _database.insert('tasks', row);
    _loadTasks();
  }

  void _removeTask(int index) async {
    await _database.delete('tasks', where: 'task = ?', whereArgs: [tasks[index]]);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Compras Supermercado'),
      ),
      body: Column(
        children: <Widget>[
          TaskForm(_addTask),
          Expanded(
            child: TaskList(tasks, _removeTask),
          ),
        ],
      ),
    );
  }
}

class TaskForm extends StatefulWidget {
  final Function(String) addTask;

  TaskForm(this.addTask);

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final TextEditingController _taskController = TextEditingController();

  void _submitForm() {
    final task = _taskController.text;
    if (task.isNotEmpty) {
      widget.addTask(task);
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Novo Item'),
              onSubmitted: (_) => _submitForm(),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  final List<String> tasks;
  final Function(int) removeTask;

  TaskList(this.tasks, this.removeTask);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (ctx, index) {
        return ListTile(
          title: Text(tasks[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => removeTask(index),
          ),
        );
      },
    );
  }
}

// Para criar uma conta
Future<User?> signUp(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  } catch (e) {
    print(e);
    return null;
  }
}

// Para fazer login
Future<User?> signIn(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  } catch (e) {
    print(e);
    return null;
  }
}

// Para fazer logout
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}
