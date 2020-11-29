import 'package:fedi/disposable/disposable.dart';
import 'package:fedi/web_sockets/channel/web_sockets_channel_model.dart';
import 'package:fedi/web_sockets/web_sockets_model.dart';
import 'package:flutter/widgets.dart';

abstract class IWebSocketsChannel<T extends WebSocketsEvent>
    implements IDisposable {
  IWebSocketsChannelConfig<T> get config;

  IDisposable listenForEvents({
    @required WebSocketChannelListener<T> listener,
  });
}
