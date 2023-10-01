import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestApiTest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'RestApiTest'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic> post = {};
  Map<String, dynamic> updatedPost = {};

  @override
  void initState() {
    Socket socket = io(
        'http://192.168.0.103:3000',
        OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    socket.connect();
    socket.on('posts', (data) {
      setState(() {
        if(data['action'] == 'create') {
          post = data['post'];
        }
        if(data['action'] == 'update') {
          updatedPost = data['post'];
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(post['title'] ?? ''),
            const SizedBox(
              height: 10,
            ),
            Text(updatedPost['title'] ?? ''),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () => postsProvider.login(context, this),
              child: const Text('login'),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () => postsProvider.signup(context, this),
              child: const Text('signup'),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                postsProvider.createPosts(context, this);
              },
              child: const Text('create'),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                postsProvider.updatePost(context, this);
              },
              child: const Text('update'),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                postsProvider.deletePost(context, this);
              },
              child: const Text('delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class PostsProvider with ChangeNotifier {
  String? message;
  String? token;
  String? userId;
  Map<String, dynamic>? post;

  Future<void> login(BuildContext context, State state) async {
    final url = Uri.parse('http://192.168.0.103:3000/auth/login');
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json
            .encode({"email": "akhil.a96@yahoo.com", "password": "password"}));
    message = json.decode(response.body)["message"] ?? "";
    userId = json.decode(response.body)["userId"] ?? "";
    token = json.decode(response.body)["token"] ?? "";
    if (kDebugMode) {
      print(message);
      print(userId);
      print(token);
    }
    if (!state.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message!),
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> signup(BuildContext context, State state) async {
    final url = Uri.parse('http://192.168.0.103:3000/auth/signup');
    final response = await http.put(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": "akhil.a9600@yahoo.com",
          "password": "password",
          "name": "akhil"
        }));
    message = json.decode(response.body)["message"] ?? "";
    userId = json.decode(response.body)["user"] ?? "";
    if (kDebugMode) {
      print(message);
      print(userId);
    }
    if (!state.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message!),
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> createPosts(BuildContext context, State state) async {
    final url = Uri.parse('http://192.168.0.103:3000/feed/post');
    Map<String, dynamic> creator;
    final request = http.MultipartRequest(
      'POST',
      url,
    );
    request.headers.addAll({
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });
    // request.files.add(
    //   http.MultipartFile(
    //     '',
    //     File(),
    //   ),
    // );
    request.fields.addAll({"title": "testPost14", "content": "testPost14"});
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    message = json.decode(response.body)["message"] ?? "";
    creator = json.decode(response.body)["creator"] ?? {};
    post = json.decode(response.body)["post"] ?? {};
    if (kDebugMode) {
      print(message);
      print(creator["_id"]);
      print(post!['title']);
      print(creator["name"]);
    }
    if (!state.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message!),
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> updatePost(BuildContext context, State state) async {
    final url =
    Uri.parse('http://192.168.0.103:3000/feed/post/${post!['_id']}');
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({"title": "testPost15", "content": "testPost15"}),
    );
    message = json.decode(response.body)["message"] ?? "";
    post = json.decode(response.body)["post"] ?? {};
    if (kDebugMode) {
      print(message);
      print(post!['title']);
    }
    if (!state.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message!),
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> deletePost(BuildContext context, State state) async {
    final url =
    Uri.parse('http://192.168.0.103:3000/feed/post/${post!['_id']}');
    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );
    message = json.decode(response.body)["message"] ?? "";
    if (kDebugMode) {
      print(message);
    }
    if (!state.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message!),
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }
}
