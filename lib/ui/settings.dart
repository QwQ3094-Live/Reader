import 'package:flutter/material.dart';
import 'package:reader/ui/components/settings_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _brightness = '跟随系统';
  double _round = 20;
  String _date = '';
  
  void _toggleTheme(String value) {
    setState(() {
      _brightness = value;
    });
  }
  
  void _changeRound(double value) {
    setState(() {
      _round = value;
    });
  }
  
  void _inputDate(String? value) {
    setState(() {
      if (value != null) _date = value;
      else _date = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const PreferenceTitle(text: '主题'),

          MenuPreference(
            iconData: Icons.brightness_4,
            title: '主题模式',
            subtitle: _brightness,
            menuItems: [
              MenuItemButton(
                child: const Text('跟随系统'),
                onPressed: () => _toggleTheme('跟随系统'),
              ),
              MenuItemButton(
                child: const Text('明亮'),
                onPressed: () => _toggleTheme('明亮'),
              ),
              MenuItemButton(
                child: const Text('黑暗'),
                onPressed: () => _toggleTheme('黑暗'),
              ),
              MenuItemButton(
                child: const Text('OLED纯黑'),
                onPressed: () => _toggleTheme('OLED纯黑'),
              ),
            ],
          ),
          
          const PreferenceTitle(text: '通用'),
          
          SliderPreference(
            iconData: Icons.rounded_corner,
            title: '圆角大小',
            slider: Slider(
              value: _round,
              max: 24,
              label: _round.toString(),
              onChanged: (double value) => _changeRound(value),
            ),
          ),
          
          EditTextPreference(
            iconData: Icons.date_range,
            title: '日期输入',
            subtitle: _date,
            dialogTitle: '输入你的日期',
            dialogContent: '日期',
            dialogCancel: '取消',
            dialogSure: '确定',
            onConfirm: (String date) => _inputDate(date),
          ),
        ],
      ),
    );
  }
}