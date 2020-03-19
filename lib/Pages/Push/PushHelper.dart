import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fedi/Pleroma/Foundation/CurrentInstance.dart';
import 'package:fedi/Pleroma/Foundation/InstanceStorage.dart';
import 'dart:io' show Platform;

import 'package:vibration/vibration.dart';

class PushHelper {
  PushHelper._privateConstructor();

  static final PushHelper _instance = PushHelper._privateConstructor();
  static PushHelper get instance {
    return _instance;
  }

  Function swapAccount;
  Function onMessage;
  String notificationId;
  String notifcationType;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool fromResume = false;
  Function notificationUpdater;
  Function updateBadges;

  Future<dynamic> theOnMessage(Map<String, dynamic> message) async {
    debugPrint("onMessage: face $message");
    String server;
    String acc;
    String type;
    if (Platform.isAndroid) {
      // Android-specific code
      var d = message["data"];
      acc = d['account'];
      server = d['server'];
      type = d["notification_type"];
    } else {
      // iOS-specific code
      acc = message['account'];
      server = message['server'];
      type = message["notification_type"];
    }

    //  _navigateToItemDetail(message);
    String account = "$acc@$server";
    print("NEW ACCOUNT ALERT $account");
    await InstanceStorage.addAccountAlert(account, type);
    Vibration.vibrate();
    PushHelper.instance.updateBadges();
    PushHelper.instance.notificationUpdater();
    //   _showItemDialog(message);
  }

  config(BuildContext context) {
    print("CONFIGING");
    PushHelper.instance._firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        debugPrint("onMessage: face $message");
        String server;
        String acc;
        String type;
        if (Platform.isAndroid) {
          // Android-specific code
          var d = message["data"];
          acc = d['account'];
          server = d['server'];

          type = d["notification_type"];
        } else {
          // iOS-specific code
          acc = message['account'];
          server = message['server'];
          type = message["notification_type"];
        }

        //  _navigateToItemDetail(message);
        String account = "$acc@$server";
        print("NEW ACCOUNT ALERT $account");
        InstanceStorage.addAccountAlert(account, type).then((value) {
          Vibration.vibrate();
          PushHelper.instance.updateBadges();
          PushHelper.instance.notificationUpdater();
        });

        //   _showItemDialog(message);
      },
      onLaunch: (Map<String, dynamic> data) async {
        print("onLaunch");
        print("$data");
        String server;
        String acc;
        String id;
        String type;
        if (Platform.isAndroid) {
          // Android-specific code
          var d = data["data"];
          acc = d['account'];
          server = d['server'];
          id = d['notification_id'].toString();
          type = d["notification_type"];
        } else {
          // iOS-specific code
          acc = data['account'];
          server = data['server'];
          id = data['notification_id'].toString();
          type = data["notification_type"];
        }

        PushHelper.instance.notificationId = id;
        PushHelper.instance.notifcationType = type;
        //  _navigateToItemDetail(message);
        String account = "$acc@https://$server";
        print("SWAPPING ACCOUNT $account");
        InstanceStorage.setCurrentAccount(account).then((future) {
          swapAccount();
        }).catchError((error) {
          print(error);
        });
      },
      onResume: (Map<String, dynamic> data) async {
        String server;
        String acc;
        String id;
        String type;
        if (Platform.isAndroid) {
          // Android-specific code
          var d = data["data"];
          acc = d['account'];
          server = d['server'];
          id = d['notification_id'].toString();
          type = d["notification_type"];
        } else {
          // iOS-specific code
          acc = data['account'];
          server = data['server'];
          id = data['notification_id'].toString();
          type = data["notification_type"];
        }
        //  _navigateToItemDetail(message);
        String account = "$acc@https://$server";
        print("SWAPPING ACCOUNT $account");
        PushHelper.instance.notificationId = id;
        PushHelper.instance.notifcationType = type;
        InstanceStorage.setCurrentAccount(account).then((future) {
          PushHelper.instance.swapAccount();
        }).catchError((error) {
          print(error);
        });
      },
    );
  }

  unregister() {
    CurrentInstance.instance.currentClient.unsubscribeToPush();
  }

  register() {
    PushHelper.instance._firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {});

    PushHelper.instance._firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print("Token");
      print(token);

      CurrentInstance.instance.currentClient.subscribeToPush(token);
    });
  }
}