import 'package:fedi/app/chat/selection/chat_selection_widget.dart';
import 'package:fedi/app/message/post_message_bloc.dart';
import 'package:fedi/app/message/post_message_widget.dart';
import 'package:fedi/app/ui/divider/fedi_ultra_light_grey_divider.dart';
import 'package:fedi/app/ui/fedi_padding.dart';
import 'package:fedi/generated/l10n.dart';
import 'package:flutter/widgets.dart';

class ChatBodyWrapperWidget extends StatelessWidget {
  final Widget child;

  const ChatBodyWrapperWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    var postMessageBloc = IPostMessageBloc.of(context, listen: false);
    var postMessageWidget = const _ChatPostMessageWidget();
    return StreamBuilder<bool>(
      stream: postMessageBloc.isExpandedStream,
      initialData: postMessageBloc.isExpanded,
      builder: (context, snapshot) {
        var isPostMessageExpanded = snapshot.data!;
        if (isPostMessageExpanded) {
          return postMessageWidget;
        } else {
          return Column(
            children: <Widget>[
              const ChatSelectionWidget(),
              Expanded(
                child: Padding(
                  padding: FediPadding.horizontalBigPadding,
                  child: child,
                ),
              ),
              const FediUltraLightGreyDivider(),
              postMessageWidget,
            ],
          );
        }
      },
    );
  }
}

class _ChatPostMessageWidget extends StatelessWidget {
  const _ChatPostMessageWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PostMessageWidget(
      hintText: S.of(context).app_chat_post_field_content_hint,
    );
  }
}
