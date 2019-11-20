import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DynamicThemeBuilder = MaterialApp Function(BuildContext context, DynamicThemeData data);

class DynamicThemeApp extends StatelessWidget {
  final DynamicThemeBuilder builder;
  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode defaultThemeMode;

  DynamicThemeApp({
    Key key,
    @required this.builder,
    this.defaultThemeMode = ThemeMode.system,
    ThemeData theme,
    ThemeData darkTheme,
  })  : assert(builder != null),
        this.theme = theme,
        this.darkTheme = darkTheme,
        super(key: key) {
    DynamicThemeController._setThemes(
      theme,
      darkTheme,
      defaultThemeMode == ThemeMode.system ? ThemeMode.light : defaultThemeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = DynamicThemeController();

    return FutureBuilder<ThemeMode>(
      future: controller._loadThemeMode(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        } else {
          return StreamBuilder<ThemeMode>(
            stream: controller.outThemeMode,
            initialData: snapshot.data,
            builder: (context, snapshot) {
              return builder(context, DynamicThemeData());
            },
          );
        }
      },
    );
  }
}

class DynamicThemeController {
  static const _KEY_DYNAMIC_THEME_MODE = 'dynamic_theme_mode';

  static final DynamicThemeController _instance = DynamicThemeController._internal();

  DynamicThemeController._internal() : _data = DynamicThemeData();

  factory DynamicThemeController() => _instance;

  static _setThemes(ThemeData theme, ThemeData darkTheme, ThemeMode defaultThemeMode) {
    if (_instance._defaultThemeMode == null) {
      _instance._defaultThemeMode = defaultThemeMode;
      DynamicThemeData._setThemes(theme, darkTheme);
    }
  }

  final StreamController<ThemeMode> _modeController = StreamController<ThemeMode>();

  Stream<ThemeMode> get outThemeMode => _modeController.stream;

  DynamicThemeData get data => _data;
  final DynamicThemeData _data;

  ThemeMode _defaultThemeMode;

  void toggleMode() {
    _data._toggleMode();
    _modeController.sink.add(_data.mode);
  }

  void saveThemeMode() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_KEY_DYNAMIC_THEME_MODE, _data.mode.index);
    });
  }

  void reloadThemeMode() {
    _loadThemeMode().then((_) {
      _modeController.sink.add(_data.mode);
    });
  }

  Future<ThemeMode> _loadThemeMode() async {
    return SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey(_KEY_DYNAMIC_THEME_MODE)) {
        _data._setMode(ThemeMode.values.elementAt(prefs.getInt(_KEY_DYNAMIC_THEME_MODE)));
      } else {
        _data._setMode(_defaultThemeMode);
      }
      return _data.mode;
    });
  }

  void dispose() {
    _modeController.close();
  }
}

class DynamicThemeData {
  static final DynamicThemeData _instance = DynamicThemeData._internal();

  DynamicThemeData._internal();

  factory DynamicThemeData() => _instance;

  static _setThemes(ThemeData theme, ThemeData darkTheme) {
    _instance._theme = theme;
    _instance._darkTheme = darkTheme;
  }

  ThemeData get theme => _theme;
  ThemeData _theme;

  ThemeData get darkTheme => _darkTheme;
  ThemeData _darkTheme;

  ThemeMode get mode => _mode;
  ThemeMode _mode;

  void _toggleMode() => _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

  void _setMode(ThemeMode mode) => _mode = mode;
}
