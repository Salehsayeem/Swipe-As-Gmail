import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hovering/hovering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _items = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    readJson();
  }

  Future<void> readJson() async {
    try {
      final String response = await rootBundle.loadString('assets/data.json');
      final data = json.decode(response);
      setState(() {
        _items = data["items"];
      });
    } catch (e) {
      log('Error loading JSON: $e');
    }
  }

  String _truncateText(String text) {
    const maxLength = 55;
    const ellipsis = '...';
    text = text.replaceAll('\n', ' ');
    if (text.length > maxLength) {
      text = text.substring(0, maxLength) + ellipsis;
    }

    return text;
  }

  bool isToday(String dateString) {
    if (dateString.isEmpty) return false;

    final now = DateTime.now();
    final date = DateTime.parse(dateString);

    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  void sortItemsByDateAndTime(List<dynamic> filteredItems) {
    filteredItems.sort((a, b) {
      DateTime dateTimeA = DateTime.tryParse(a["date"] ?? "") ?? DateTime(0);
      DateTime dateTimeB = DateTime.tryParse(b["date"] ?? "") ?? DateTime(0);
      return dateTimeB.compareTo(dateTimeA);
    });
  }

  Widget buildDismissibleItem(Map<String, dynamic> item, int index) {
    final colorCode = item["color"];

    return Dismissible(
      key: Key(item["id"].toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        color: colorCode != null
            ? Color(int.parse(colorCode.substring(1), radix: 16) | 0xFF000000)
            : Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
      ),
      onDismissed: (direction) {
        setState(() {
          _items.remove(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item["name"] + " removed"),
            shape: const StadiumBorder(),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _items.insert(index, item);
                });
              },
            ),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: colorCode != null
              ? Color(int.parse(colorCode.substring(1), radix: 16) | 0xFF000000)
              : Colors.transparent,
          child: Text(item["id"]),
        ),
        title: Text(
          item["name"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _truncateText(item["title"]),
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            Text(
              _truncateText(item["subtitle"]),
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          (item["date"] != null && item["time"] != null)
              ? (isToday(item["date"]) ? item["time"] : item["date"])
              : "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Apply design and animations in Appbar
      appBar: AppBar(
        centerTitle: true,
        //the menu icon
        leading: HoverAnimatedContainer(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          hoverDecoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ),
        //input text
        title: GestureDetector(
          onTap: () {},
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search in mail',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              color: Colors.black,
            ),
            textAlign: TextAlign.left,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
        ),
        actions: [
          Padding(
            //gmail avatar
            padding: const EdgeInsets.all(8.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    'g',
                    style: TextStyle(
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        elevation: 4,
      ),
      body: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Inbox",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
          _items.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    //search functionalities
                    itemCount: _items
                        .where((item) => item["name"].toLowerCase().contains(
                              _searchText.toLowerCase(),
                            ))
                        .length,
                    itemBuilder: (context, index) {
                      final filteredItems = _items
                          .where((item) => item["name"].toLowerCase().contains(
                                _searchText.toLowerCase(),
                              ))
                          .toList();

                      sortItemsByDateAndTime(filteredItems);
                      final item = filteredItems[index];
                      // Return this widget to view the list and apply dismissible function
                      return buildDismissibleItem(item, index);
                    },
                  ),
                )
              //if there is no item, then show this text
              : Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: const Center(
                    child: Text(
                      "No mail received yet",
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
