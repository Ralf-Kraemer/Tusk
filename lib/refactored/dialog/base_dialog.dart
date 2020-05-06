import 'package:easy_localization/easy_localization.dart';
import 'package:fedi/disposable/disposable_owner.dart';
import 'package:fedi/refactored/dialog/dialog_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

abstract class BaseDialog extends DisposableOwner {
  final bool cancelable;

  BaseDialog({this.cancelable = true});

  bool _isShowing = false;

  bool get isShowing => _isShowing;

  Future show(BuildContext context) {
    assert(!isShowing);
    _isShowing = true;
    return showDialog(
        barrierDismissible: cancelable,
        context: context,
        builder: (BuildContext context) => buildDialog(context));
  }

  void hide(BuildContext context) async {
    assert(isShowing);
    _isShowing = false;
    dispose();
    Navigator.of(context).pop();
  }

  Widget buildDialog(BuildContext context);
}

DialogAction createDefaultCancelAction(BuildContext context) {
  return DialogAction(
      onAction: () {
        Navigator.of(context).pop();
      },
      label: AppLocalizations.of(context).tr("dialog.action.cancel"));
}

DialogAction createOkCancelAction(BuildContext context) {
  return DialogAction(
      onAction: () {
        Navigator.of(context).pop();
      },
      label: AppLocalizations.of(context).tr("dialog.action.ok"));
}
