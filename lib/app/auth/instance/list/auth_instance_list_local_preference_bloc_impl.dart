import 'package:fedi/app/auth/instance/list/auth_instance_list_local_preference_bloc.dart';
import 'package:fedi/app/auth/instance/list/auth_instance_list_model.dart';
import 'package:fedi/local_preferences/local_preference_bloc_impl.dart';
import 'package:fedi/local_preferences/local_preferences_service.dart';

class AuthInstanceListLocalPreferenceBloc
    extends ObjectLocalPreferenceBloc<AuthInstanceList?>
    implements IAuthInstanceListLocalPreferenceBloc {
  AuthInstanceListLocalPreferenceBloc(
    ILocalPreferencesService preferencesService,
  ) : super(
          preferencesService,
          "instance.list",
          1,
          (json) => AuthInstanceList.fromJson(json),
        );
}
