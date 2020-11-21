import 'package:fedi/app/status/post/poll/post_status_poll_model.dart';
import 'package:fedi/disposable/disposable.dart';
import 'package:fedi/form/field/value/bool/bool_value_form_field_bloc.dart';
import 'package:fedi/form/field/value/duration/duration_value_form_field_bloc.dart';
import 'package:fedi/form/field/value/string/string_value_form_field_bloc.dart';
import 'package:fedi/form/form_bloc.dart';
import 'package:fedi/form/group/one_type/one_type_form_group_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

abstract class IPostStatusPollBloc implements IFormBloc, IDisposable {
  static IPostStatusPollBloc of(BuildContext context, {bool listen = true}) =>
      Provider.of<IPostStatusPollBloc>(context, listen: listen);

  static final Duration minimumPollExpiration = Duration(minutes: 10);
  static final Duration defaultPollExpiration = Duration(days: 1);
  static final int defaultMaxPollOptions = 20;

  IOneTypeFormGroupBloc<IStringValueFormFieldBloc> get pollOptionsGroupBloc;

  IBoolValueFormFieldBloc get multiplyFieldBloc;

  IDurationValueFormFieldBloc get durationLengthFieldBloc;

  void fillFormData(IPostStatusPoll poll);


}
