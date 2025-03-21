import 'package:easy_dispose_provider/easy_dispose_provider.dart';
import 'package:fedi_app/app/account/account_bloc.dart';
import 'package:fedi_app/app/account/avatar/account_avatar_widget.dart';
import 'package:fedi_app/app/account/details/local_account_details_page.dart';
import 'package:fedi_app/app/account/display_name/account_display_name_widget.dart';
import 'package:fedi_app/app/account/local_account_bloc_impl.dart';
import 'package:fedi_app/app/async/unifedi/unifedi_async_operation_helper.dart';
import 'package:fedi_app/app/emoji/text/emoji_text_model.dart';
import 'package:fedi_app/app/html/html_text_bloc.dart';
import 'package:fedi_app/app/html/html_text_bloc_impl.dart';
import 'package:fedi_app/app/html/html_text_helper.dart';
import 'package:fedi_app/app/html/html_text_model.dart';
import 'package:fedi_app/app/html/html_text_widget.dart';
import 'package:fedi_app/app/notification/created_at/notification_created_at_widget.dart';
import 'package:fedi_app/app/notification/go_to_notification_extension.dart';
import 'package:fedi_app/app/notification/notification_bloc.dart';
import 'package:fedi_app/app/notification/notification_model.dart';
import 'package:fedi_app/app/ui/dialog/chooser/fedi_chooser_dialog.dart';
import 'package:fedi_app/app/ui/fedi_icons.dart';
import 'package:fedi_app/app/ui/fedi_sizes.dart';
import 'package:fedi_app/app/ui/modal_bottom_sheet/fedi_modal_bottom_sheet.dart';
import 'package:fedi_app/app/ui/overlay/fedi_blurred_overlay_warning_widget.dart';
import 'package:fedi_app/app/ui/spacer/fedi_big_horizontal_spacer.dart';
import 'package:fedi_app/app/ui/theme/fedi_ui_theme_model.dart';
import 'package:fedi_app/dialog/dialog_model.dart';
import 'package:fedi_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

var _logger = Logger('notification_list_item_widget.dart');

class NotificationListItemWidget extends StatelessWidget {
  const NotificationListItemWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    _logger.finest(() => 'build ${notificationBloc.remoteId}');

    var bodyWidget = const _NotificationListItemBodyWidget();

    return StreamBuilder<bool?>(
      stream: notificationBloc.dismissedStream,
      builder: (context, snapshot) {
        var dismissed = snapshot.data;
        if (dismissed == true) {
          return Stack(
            children: [
              bodyWidget,
              const Positioned.fill(
                child: _NotificationListItemBodyDismissedWidget(),
              ),
            ],
          );
        } else {
          return bodyWidget;
        }
      },
    );
  }
}

class _NotificationListItemBodyDismissedWidget extends StatelessWidget {
  const _NotificationListItemBodyDismissedWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => FediBlurredOverlayWarningWidget(
        descriptionText: S.of(context).app_notification_dismissed,
      );
}

class _NotificationListItemBodyWidget extends StatelessWidget {
  const _NotificationListItemBodyWidget();

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    return DisposableProxyProvider<INotificationBloc, IAccountBloc>(
      update: (context, value, previous) => LocalAccountBloc.createFromContext(
        context,
        account: value.account!,
        isNeedWatchWebSocketsEvents: false,
        isNeedRefreshFromNetworkOnInit: false,
        isNeedWatchLocalRepositoryForUpdates: false,
        isNeedPreFetchRelationship: false,
      ),
      child: StreamBuilder<NotificationState>(
        stream: notificationBloc.stateStream,
        builder: (context, snapshot) {
          var notificationState = snapshot.data;
          var unread = notificationState?.unread ?? true;
          var dismissed = notificationState?.dismissed ?? false;

          return Slidable(
            startActionPane: const ActionPane(),
            // ignore: no-magic-number
            actionExtentRatio: 0.25,
            secondaryActions: <Widget>[
              if (unread)
                const _NotificationListItemBodyMarkAsReadActionWidget(),
              if (!dismissed)
                const _NotificationListItemBodyDismissActionWidget(),
            ],
            child: const _NotificationListItemBodySlidableChildWidget(),
          );
        },
      ),
    );
  }
}

class _NotificationListItemBodyDismissActionWidget extends StatelessWidget {
  const _NotificationListItemBodyDismissActionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    return IconSlideAction(
      icon: FediIcons.delete,
      caption: S.of(context).app_notification_action_dismiss,
      color: IFediUiColorTheme.of(context).white,
      onTap: () {
        // ignore: avoid-ignoring-return-values
        UnifediAsyncOperationHelper.performUnifediAsyncOperation<void>(
          context: context,
          showProgressDialog: false,
          asyncCode: () => notificationBloc.dismiss(),
        );
      },
    );
  }
}

class _NotificationListItemBodyMarkAsReadActionWidget extends StatelessWidget {
  const _NotificationListItemBodyMarkAsReadActionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    return SlidableAction(
      icon: FediIcons.check,
      label: S.of(context).app_notification_action_markAsRead,
      foregroundColor: IFediUiColorTheme.of(context).white,
      onTap: () {
        // ignore: avoid-ignoring-return-values
        UnifediAsyncOperationHelper.performUnifediAsyncOperation<void>(
          context: context,
          showProgressDialog: false,
          asyncCode: () => notificationBloc.markAsRead(),
        );
      },
    );
  }
}

class _NotificationListItemBodySlidableChildWidget extends StatelessWidget {
  const _NotificationListItemBodySlidableChildWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    return StreamBuilder<bool?>(
      stream: notificationBloc.unreadStream,
      builder: (context, snapshot) {
        var unread = snapshot.data ?? true;

        return Opacity(
          // ignore: no-magic-number
          opacity: unread ? 1.0 : 0.6,
          child: const _NotificationListItemBodySlidableChildContentWidget(),
        );
      },
    );
  }
}

class _NotificationListItemBodySlidableChildContentWidget
    extends StatelessWidget {
  const _NotificationListItemBodySlidableChildContentWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FediSizes.bigPadding,
          vertical: FediSizes.bigPadding + FediSizes.smallPadding,
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: const <Widget>[
                _NotificationListItemAvatarWidget(),
                FediBigHorizontalSpacer(),
                Expanded(
                  child: _NotificationListItemBodyMainAreaWidget(),
                ),
                FediBigHorizontalSpacer(),
                _NotificationListItemCreatedAtWidget(),
              ],
            ),
          ],
        ),
      );
}

class _NotificationListItemBodyMainAreaWidget extends StatelessWidget {
  const _NotificationListItemBodyMainAreaWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          _onNotificationClick(context);
        },
        onLongPress: () {
          _onNotificationLongPress(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const _NotificationListItemAccountDisplayNameWidget(),
            Row(
              children: const [
                _NotificationListItemIconWidget(),
                Expanded(
                  child: _NotificationListItemContentWidget(),
                ),
              ],
            ),
          ],
        ),
      );

  Future<void> _onNotificationClick(BuildContext context) async {
    var notificationBloc = INotificationBloc.of(context, listen: false);

    await notificationBloc.notification.goToRelatedPage(context);
  }

  void _onNotificationLongPress(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context, listen: false);

    showFediModalBottomSheetDialog<void>(
      context: context,
      child: FediChooserDialogBody(
        title: S.of(context).app_notification_action_popup_title,
        actions: [
          if (notificationBloc.unread)
            DialogAction(
              icon: FediIcons.check,
              label: S.of(context).app_notification_action_markAsRead,
              onAction: (context) {
                notificationBloc.markAsRead();
                Navigator.of(context).pop();
              },
            ),
          if (!notificationBloc.dismissed)
            DialogAction(
              icon: FediIcons.delete,
              label: S.of(context).app_notification_action_dismiss,
              onAction: (context) {
                notificationBloc.dismiss();
                Navigator.of(context).pop();
              },
            ),
        ],
        cancelable: true,
      ),
    );
  }
}

class _NotificationListItemContentWidget extends StatelessWidget {
  const _NotificationListItemContentWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    var rawText = _mapToRawText(context, notificationBloc);

    var emojis = notificationBloc.status?.emojis;

    return Provider<EmojiText>.value(
      value: EmojiText(text: rawText, emojis: emojis),
      child: DisposableProxyProvider<EmojiText, IHtmlTextBloc>(
        update: (context, emojiText, previous) {
          var htmlTextInputData = HtmlTextInputData(
            input: emojiText.text,
            emojis: emojiText.emojis,
          );
          if (previous?.inputData == htmlTextInputData) {
            return previous!;
          }

          var textScaleFactor = MediaQuery.of(context).textScaleFactor;
          var fediUiColorTheme = IFediUiColorTheme.of(
            context,
            listen: false,
          );
          var htmlTextBloc = HtmlTextBloc(
            inputData: htmlTextInputData,
            settings: HtmlTextSettings(
              // ignore: no-magic-number
              textMaxLines: 3,
              textOverflow: TextOverflow.ellipsis,
              color: fediUiColorTheme.mediumGrey,
              // todo: refactor
              // ignore: no-magic-number
              fontSize: 14,
              // todo: refactor
              // ignore: no-magic-number
              lineHeight: 1.5,
              fontWeight: FontWeight.w300,
              shrinkWrap: true,
              linkColor: fediUiColorTheme.primary,
              drawNewLines: false,
              textScaleFactor: textScaleFactor,
            ),
          );

          return htmlTextBloc;
        },
        child: const HtmlTextWidget(),
      ),
    );
  }

  // ignore: long-method
  String _mapToRawText(
    BuildContext context,
    INotificationBloc notificationBloc,
  ) =>
      notificationBloc.typeAsUnifediApi.map(
        follow: (_) => S.of(context).app_notification_header_follow,
        favourite: (_) => S.of(context).app_notification_header_favourite,
        reblog: (_) => S.of(context).app_notification_header_reblog,
        mention: (_) {
          var rawText =
              '<b>${S.of(context).app_notification_header_mention_prefix}</b>';

          return rawText +
              S.of(context).app_notification_header_mention_postfix(
                    _extractStatusRawContent(notificationBloc)!,
                  );
        },
        poll: (_) => S.of(context).app_notification_header_poll,
        move: (_) => S.of(context).app_notification_header_move,
        followRequest: (_) =>
            S.of(context).app_notification_header_followRequest,
        emojiReaction: (_) =>
            S.of(context).app_notification_header_emojiReaction(
                  notificationBloc.notification.emoji!,
                ),
        chatMention: (_) {
          var rawText =
              '<b>${S.of(context).app_notification_header_chatMention_prefix}</b>';

          return rawText +
              S.of(context).app_notification_header_chatMention_postfix(
                    _extractChatMessageRawContent(notificationBloc)!,
                  );
        },
        report: (_) => S.of(context).app_notification_header_report(
              notificationBloc.account?.acct ?? '',
            ),
        unknown: (_) {
          var isHaveStatus = notificationBloc.status != null;
          String? statusText;
          if (isHaveStatus) {
            statusText = _extractStatusRawContent(notificationBloc);
          } else {
            statusText = '';
          }

          var isHaveEmoji = notificationBloc.notification.emoji != null;
          String? emojiText;
          if (isHaveEmoji) {
            emojiText = notificationBloc.notification.emoji;
          } else {
            emojiText = '';
          }

          return S.of(context).app_notification_header_unknown(
                '${notificationBloc.typeAsUnifediApi.stringValue}: $emojiText $statusText',
              );
        },
      );

  String? _extractStatusRawContent(INotificationBloc notificationBloc) {
    var content = notificationBloc.status?.content;

    if (content != null) {
      content = content.extractRawStringFromHtmlString();
      var mediaAttachments =
          notificationBloc.notification.status?.mediaAttachments;
      if (content.isEmpty && mediaAttachments?.isNotEmpty == true) {
        content = mediaAttachments!
            .map(
              (mediaAttachment) =>
                  mediaAttachment.description ?? mediaAttachment.url,
            )
            .join(', ');
      }
    }

    return content;
  }

  String? _extractChatMessageRawContent(INotificationBloc notificationBloc) {
    var content = notificationBloc.chatMessage?.content;

    if (content != null) {
      content = content.extractRawStringFromHtmlString();
      var mediaAttachment =
          notificationBloc.notification.chatMessage?.mediaAttachment;
      if (mediaAttachment != null) {
        content = mediaAttachment.description ?? mediaAttachment.url;
      }
    }

    return content;
  }
}

class _NotificationListItemAccountDisplayNameWidget extends StatelessWidget {
  const _NotificationListItemAccountDisplayNameWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => AccountDisplayNameWidget(
        textStyle: IFediUiTextTheme.of(context).bigTallDarkGrey,
      );
}

class _NotificationListItemIconWidget extends StatelessWidget {
  const _NotificationListItemIconWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData? iconData;
    var notificationBloc = INotificationBloc.of(context);
    var iconColor = IFediUiColorTheme.of(context).primary;

    notificationBloc.typeAsUnifediApi.when(
      follow: (_) {
        iconData = FediIcons.follow;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      favourite: (_) {
        iconData = FediIcons.heart_active;
        iconColor = IFediUiColorTheme.of(context).secondary;
      },
      reblog: (_) {
        iconData = FediIcons.reply;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      mention: (_) {
        iconData = null;
      },
      poll: (_) {
        iconData = FediIcons.poll;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      move: (_) {
        iconData = FediIcons.forward;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      followRequest: (_) {
        iconData = FediIcons.add_user;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      // ignore: no-equal-arguments
      emojiReaction: (_) {
        iconData = null;
      },
      chatMention: (_) {
        iconData = FediIcons.chat;
        iconColor = IFediUiColorTheme.of(context).primary;
      },
      report: (_) {
        iconData = FediIcons.report;
        iconColor = IFediUiColorTheme.of(context).error;
      },

      // ignore: no-equal-arguments
      unknown: (_) {
        iconData = null;
      },
    );

    if (iconData != null) {
      return Padding(
        padding: const EdgeInsets.only(right: FediSizes.smallPadding),
        child: Icon(
          iconData,
          color: iconColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _NotificationListItemAvatarWidget extends StatelessWidget {
  const _NotificationListItemAvatarWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);

    return InkWell(
      onTap: () {
        goToLocalAccountDetailsPage(
          context,
          account: notificationBloc.account!,
        );
      },
      child: const AccountAvatarWidget(
        progressSize: FediSizes.accountAvatarProgressDefaultSize,
        imageSize: FediSizes.accountAvatarDefaultSize,
      ),
    );
  }
}

class _NotificationListItemCreatedAtWidget extends StatelessWidget {
  const _NotificationListItemCreatedAtWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var notificationBloc = INotificationBloc.of(context);
    var fediUiTextTheme = IFediUiTextTheme.of(context);

    return StreamBuilder<bool?>(
      stream: notificationBloc.unreadStream,
      initialData: notificationBloc.unread,
      builder: (context, snapshot) {
        var unread = snapshot.data!;

        return NotificationCreatedAtWidget(
          textStyle: unread
              ? fediUiTextTheme.smallShortPrimaryDark
              : fediUiTextTheme.smallShortGrey,
        );
      },
    );
  }
}
