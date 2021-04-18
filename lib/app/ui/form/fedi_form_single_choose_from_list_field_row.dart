import 'package:fedi/app/ui/dialog/chooser/selection/single/fedi_single_selection_chooser_dialog.dart';
import 'package:fedi/app/ui/fedi_icons.dart';
import 'package:fedi/app/ui/fedi_padding.dart';
import 'package:fedi/app/ui/form/fedi_form_column_desc.dart';
import 'package:fedi/app/ui/form/fedi_form_row.dart';
import 'package:fedi/app/ui/form/fedi_form_row_label.dart';
import 'package:fedi/app/ui/theme/fedi_ui_theme_model.dart';
import 'package:fedi/dialog/dialog_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'fedi_form_column_error.dart';

typedef ValueToTextMapper<T> = String Function(T value);
typedef ValueToIconMapper<T> = IconData Function(T value);
typedef ValueChangedCallback<T> = Function(T oldValue, T newValue);

class FediFormSingleChooseFromListFieldRow<T> extends StatelessWidget {
  final bool isEnabled;
  final bool nullable;
  final String label;
  final String? description;
  final String? descriptionOnDisabled;
  final String? error;
  final String chooserTitle;
  final T value;
  final List<T> possibleValues;
  final ValueToTextMapper<T>? valueToTextMapper;
  final ValueToIconMapper<T>? valueToIconMapper;
  final ValueChangedCallback<T?> onChanged;

  FediFormSingleChooseFromListFieldRow({
    required this.isEnabled,
    required this.nullable,
    required this.label,
    required this.description,
    required this.descriptionOnDisabled,
    required this.error,
    required this.chooserTitle,
    required this.value,
    required this.possibleValues,
    required this.valueToTextMapper,
    required this.valueToIconMapper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FediFormRow(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FediFormRowLabel(label),
              _FediFormSingleChooseFromListFieldRowBodyWidget(
                isEnabled: isEnabled,
                chooserTitle: chooserTitle,
                possibleValues: possibleValues,
                value: value,
                valueToTextMapper: valueToTextMapper,
                valueToIconMapper: valueToIconMapper,
                onChanged: onChanged,
                nullable: nullable,
              ),
            ],
          ),
          if (description != null) _buildDescription(),
          if (error != null) FediFormColumnError(error),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    // todo: refactor
    if (isEnabled) {
      if (description != null) {
        return FediFormColumnDesc(description);
      } else {
        return const SizedBox.shrink();
      }
    } else {
      if (descriptionOnDisabled != null) {
        return FediFormColumnDesc(descriptionOnDisabled);
      } else {
        if (description != null) {
          return FediFormColumnDesc(description);
        } else {
          return const SizedBox.shrink();
        }
      }
    }
  }
}

class _FediFormSingleChooseFromListFieldRowBodyWidget<T>
    extends StatelessWidget {
  const _FediFormSingleChooseFromListFieldRowBodyWidget({
    Key? key,
    required this.isEnabled,
    required this.chooserTitle,
    required this.possibleValues,
    required this.value,
    required this.valueToTextMapper,
    required this.valueToIconMapper,
    required this.onChanged,
    required this.nullable,
  }) : super(key: key);

  final bool isEnabled;
  final String chooserTitle;
  final List possibleValues;

  final T value;
  final ValueToTextMapper<T>? valueToTextMapper;
  final ValueToIconMapper<T>? valueToIconMapper;
  final ValueChangedCallback<T?> onChanged;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEnabled
              ? () {
                  showFediSingleSelectionChooserDialog(
                    context: context,
                    title: chooserTitle,
                    actions: possibleValues
                        .map(
                          (possibleValue) => SelectionDialogAction(
                            isSelected: value == possibleValue,
                            label: valueToTextMapper != null
                                ? valueToTextMapper!(possibleValue)
                                : null,
                            icon: valueToIconMapper != null
                                ? valueToIconMapper!(possibleValue)
                                : null,
                            onAction: (context) {
                              onChanged(value, possibleValue);
                              Navigator.of(context).pop();
                            },
                          ),
                        )
                        .toList(),
                  );
                }
              : null,
          child: _FediFormSingleChooseFromListFieldRowContentWidget(
            valueToIconMapper: valueToIconMapper,
            value: value,
            isEnabled: isEnabled,
            valueToTextMapper: valueToTextMapper,
          ),
        ),
        if (nullable && value != null)
          _FediFormSingleChooseFromListFieldRowDeleteWidget(
            onChanged: onChanged,
            value: value,
            isEnabled: isEnabled,
          ),
      ],
    );
  }
}

class _FediFormSingleChooseFromListFieldRowContentWidget<T>
    extends StatelessWidget {
  const _FediFormSingleChooseFromListFieldRowContentWidget({
    Key? key,
    required this.valueToIconMapper,
    required this.value,
    required this.isEnabled,
    required this.valueToTextMapper,
  }) : super(key: key);

  final ValueToIconMapper<T>? valueToIconMapper;
  final T value;
  final bool isEnabled;
  final ValueToTextMapper<T>? valueToTextMapper;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (valueToIconMapper != null)
          Padding(
            padding: FediPadding.horizontalSmallPadding,
            child: Icon(
              valueToIconMapper!(value),
              color: isEnabled
                  ? IFediUiColorTheme.of(context).darkGrey
                  : IFediUiColorTheme.of(context).lightGrey,
            ),
          ),
        if (valueToTextMapper != null)
          Padding(
            padding: FediPadding.horizontalSmallPadding,
            child: Text(
              valueToTextMapper!(value),
              style: isEnabled
                  ? IFediUiTextTheme.of(context).mediumShortDarkGrey
                  : IFediUiTextTheme.of(context).mediumShortLightGrey,
            ),
          ),
        Padding(
          padding: FediPadding.horizontalSmallPadding,
          child: Icon(
            FediIcons.pen,
            color: isEnabled
                ? IFediUiColorTheme.of(context).darkGrey
                : IFediUiColorTheme.of(context).lightGrey,
          ),
        ),
      ],
    );
  }
}

class _FediFormSingleChooseFromListFieldRowDeleteWidget<T>
    extends StatelessWidget {
  const _FediFormSingleChooseFromListFieldRowDeleteWidget({
    Key? key,
    required this.onChanged,
    required this.value,
    required this.isEnabled,
  }) : super(key: key);

  final ValueChangedCallback<T?> onChanged;

  final T value;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(value, null);
      },
      child: Padding(
        padding: FediPadding.horizontalSmallPadding,
        child: Icon(
          FediIcons.delete,
          color: isEnabled
              ? IFediUiColorTheme.of(context).darkGrey
              : IFediUiColorTheme.of(context).lightGrey,
        ),
      ),
    );
  }
}
