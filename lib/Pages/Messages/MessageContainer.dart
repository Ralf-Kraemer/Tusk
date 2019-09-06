import 'package:flutter/material.dart';
import 'package:phaze/Pages/Messages/MessagesPage.dart';
import 'package:phaze/Pages/Messages/NotificationPage.dart';

class MessageConatiner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MessageContainer();
  }
}

class _MessageContainer extends State<MessageConatiner> with TickerProviderStateMixin {
  List<String> titles = ["Messages", "Notifications"];
  TabController _controller;
  int _currentIndex = 0;

  List<Widget> _pageControllers = [
    MessagesPage(),
    NotificationPage()
  ];

  void initState() {
    super.initState();
    _controller = TabController(length: 2, initialIndex: 0, vsync: this,);
     _controller.addListener(_controllerChanged);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageControllers[_currentIndex],
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              // TODO: go to followers list
            },
          )
        ],
        bottom: TabBar(
          controller: _controller,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.mail_outline),
            ),
            Tab(
              icon: Icon(Icons.notifications_none),
            )
          ],
        ),
      ),
    );
  }

  _controllerChanged() {
    setState(() {
      _currentIndex = _controller.index;
    });
  }
}
