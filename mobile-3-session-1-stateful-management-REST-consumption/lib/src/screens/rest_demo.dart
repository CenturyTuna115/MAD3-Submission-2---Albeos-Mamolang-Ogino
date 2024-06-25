
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:state_change_demo/src/models/post.model.dart';
import 'package:state_change_demo/src/models/user.model.dart';

class RestDemoScreen extends StatefulWidget {
  const RestDemoScreen({super.key});

  @override
  State<RestDemoScreen> createState() => _RestDemoScreenState();
}

class _RestDemoScreenState extends State<RestDemoScreen> {
  PostController controller = PostController();

  @override
  void initState() {
    super.initState();
    controller.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posts"),
        leading: IconButton(
          onPressed: () {
            controller.getPosts();
          },
          icon: const Icon(Icons.refresh),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showNewPostFunction(context);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.error != null) {
              return Center(
                child: Text(controller.error.toString()),
              );
            }

            if (!controller.working) {
              return Center(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.postList.length,
                  itemBuilder: (context, index) {
                    Post post = controller.postList[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  viewDetails(context, post.id);
                                },
                                child: const Text("View Details"),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      showEditPostFunction(context, post);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      controller.deletePost(post.id);
                                    },
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            }
            return const Center(
              child: SpinKitChasingDots(
                size: 54,
                color: Colors.black87,
              ),
            );
          },
        ),
      ),
    );
  }

  showNewPostFunction(BuildContext context) {
    AddPostDialog.show(context, controller: controller);
  }

  showEditPostFunction(BuildContext context, Post post) {
    EditPostDialog.show(context, controller: controller, post: post);
  }

  viewDetails(BuildContext context, int postId) {
    PostDetailDialog.show(context, controller: controller, postId: postId);
  }
}

class PostDetailDialog extends StatefulWidget {
  static show(BuildContext context, {required PostController controller, required int postId}) =>
      showDialog(
        context: context, builder: (dContext) => PostDetailDialog(controller, postId));
  const PostDetailDialog(this.controller, this.postId, {super.key});

  final PostController controller;
  final int postId;

  @override
  State<PostDetailDialog> createState() => _PostDetailDialogState();
}

class _PostDetailDialogState extends State<PostDetailDialog> {
  Post? post;

  @override
  void initState() {
    super.initState();
    fetchPostDetail();
  }

  Future<void> fetchPostDetail() async {
    Post postDetail = await widget.controller.getPostDetail(widget.postId);
    setState(() {
      post = postDetail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Post Details"),
      content: post == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Title: ${post!.title}", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Body: ${post!.body}"),
              ],
            ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Close"),
        )
      ],
    );
  }
}

class EditPostDialog extends StatefulWidget {
  static show(BuildContext context, {required PostController controller, required Post post}) =>
      showDialog(
        context: context, builder: (dContext) => EditPostDialog(controller, post));
  const EditPostDialog(this.controller, this.post, {super.key});

  final PostController controller;
  final Post post;

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late TextEditingController bodyC, titleC;
  final _formKey = GlobalKey<FormState>(); // Add form key for validation

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController(text: widget.post.body);
    titleC = TextEditingController(text: widget.post.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Edit post"),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) { // Validate form
              widget.controller.editPost(
                postId: widget.post.id, 
                title: titleC.text.trim(), 
                body: bodyC.text.trim()
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text("Save"),
        )
      ],
      content: Form( // Wrap content with Form
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Title"),
            TextFormField(
              controller: titleC,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const Text("Content"),
            TextFormField(
              controller: bodyC,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddPostDialog extends StatefulWidget {
  static show(BuildContext context, {required PostController controller}) =>
      showDialog(
        context: context, builder: (dContext) => AddPostDialog(controller));
  const AddPostDialog(this.controller, {super.key});

  final PostController controller;

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  late TextEditingController bodyC, titleC;
  final _formKey = GlobalKey<FormState>(); // Add form key for validation

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController();
    titleC = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Add new post"),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) { // Validate form
              widget.controller.makePost(
                title: titleC.text.trim(), 
                body: bodyC.text.trim(), 
                userId: 1
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text("Add"),
        )
      ],
      content: Form( // Wrap content with Form
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Title"),
            TextFormField(
              controller: titleC,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const Text("Content"),
            TextFormField(
              controller: bodyC,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PostController with ChangeNotifier {
  Map<String, dynamic> posts = {};
  bool working = true;
  Object? error;

  List<Post> get postList => posts.values.whereType<Post>().toList();

  clear() {
    error = null;
    posts = {};
    notifyListeners();
  }

  Future<Post> makePost(
      {required String title,
      required String body,
      required int userId}) async {
    try {
      working = true;
      if(error != null ) error = null;
      print(title);
      print(body);
      print(userId);
      http.Response res = await HttpService.post(
          url: "https://jsonplaceholder.typicode.com/posts",
          body: {"title": title, "body": body, "userId": userId});
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }

      print(res.body);

      Map<String, dynamic> result = jsonDecode(res.body);

      Post output = Post.fromJson(result);
      posts[output.id.toString()] = output;
      working = false;
      notifyListeners();
      return output;
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
      return Post.empty;
    }

  }

  Future<void> getPosts() async {
    try {
      working = true;
      clear();
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/posts");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<Post> tmpPost = result.map((e) => Post.fromJson(e)).toList();
      posts = {for (Post p in tmpPost) "${p.id}": p};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  Future<Post> getPostDetail(int postId) async {
    try {
      working = true;
      notifyListeners();
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/posts/$postId");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      Map<String, dynamic> result = jsonDecode(res.body);
      Post postDetail = Post.fromJson(result);
      working = false;
      notifyListeners();
      return postDetail;
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
      return Post.empty;
    }
  }

   Future<void> deletePost(int postId) async {
    try {
      working = true;
      notifyListeners();
      
      // Simulate deletion in UI
      posts.remove(postId.toString()); // Remove post locally

      // Notify listeners to update UI
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

   Future<void> editPost({required int postId, required String title, required String body}) async {
    try {
      working = true;
      notifyListeners();

      http.Response res = await HttpService.put(
          url: "https://jsonplaceholder.typicode.com/posts/$postId",
          body: {"id": postId, "title": title, "body": body, "userId": 1});

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("${res.statusCode} | ${res.body}");
      }

      // Fake the update in the UI
      Post updatedPost = Post(id: postId, title: title, body: body, userId: 1);
      posts[postId.toString()] = updatedPost;
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }
}

class UserController with ChangeNotifier {
  Map<String, dynamic> users = {};
  bool working = true;
  Object? error;

  List<User> get userList => users.values.whereType<User>().toList();

  getUsers() async {
    try {
      working = true;
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/users");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<User> tmpUser = result.map((e) => User.fromJson(e)).toList();
      users = {for (User u in tmpUser) "${u.id}": u};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  clear() {
    users = {};
    notifyListeners();
  }
}

class HttpService {
  static Future<http.Response> get(
      {required String url, Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> post(
      {required String url,
      required Map<dynamic, dynamic> body,
      Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> delete(
      {required String url, Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.delete(uri, headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> put(
      {required String url,
      required Map<dynamic, dynamic> body,
      Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.put(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }
}

void main() {
  runApp(MaterialApp(
    home: RestDemoScreen(),
  ));
}
