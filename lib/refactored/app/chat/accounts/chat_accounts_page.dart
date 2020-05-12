import 'package:easy_localization/easy_localization.dart';
import 'package:fedi/refactored/app/chat/accounts/chat_accounts_widget.dart';
import 'package:fedi/refactored/app/chat/chat_bloc.dart';
import 'package:fedi/refactored/app/chat/chat_bloc_impl.dart';
import 'package:fedi/refactored/app/chat/chat_model.dart';
import 'package:fedi/refactored/disposable/disposable_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatAccountsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
            AppLocalizations.of(context).tr("app.chat.accounts.title")),
      ),
      body: ChatAccountsWidget(),
    );
  }
}

void goToChatAccountsPage(
    BuildContext context, IChat chat) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => DisposableProvider<IChatBloc>(
            create: (context) => ChatBloc.createFromContext(context,
                chat: chat),
            child: ChatAccountsPage())),
  );
}
