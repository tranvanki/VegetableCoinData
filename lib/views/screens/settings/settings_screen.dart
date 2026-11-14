import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/core/storage/image_cache_manager.dart';
import 'package:provider/provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/state/state_views.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(title: const Text('Cài đặt')),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Giao diện'),
                trailing: DropdownButton<ThemeMode>(
                  value: appState.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Theo hệ thống'),
                    ),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Sáng')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                  ],
                  onChanged: (value) {
                    if (value != null) appState.setThemeMode(value);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Ngôn ngữ'),
                trailing: DropdownButton<String>(
                  value: appState.locale.languageCode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    appState.setLocale(
                      Locale(value, value == 'vi' ? 'VN' : 'US'),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(
                  AppRoutes.webviewPath(
                    'https://coingecko',
                    title: 'Điều khoản sử dụng',
                  ),
                ),
              ),
              ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Xoá bộ nhớ đệm ảnh'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: const Text('Cảnh Báo'),
                            content: const Text(
                                'Bạn có chắc chắn muốn xoá toàn bộ bộ nhớ đệm ảnh không?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Hủy'),
                                onPressed: () => Navigator.of(context)
                                    .pop(false), // Trả về false khi bấm Hủy
                              ),
                              TextButton(
                                child: const Text('Xoá',
                                    style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.of(context)
                                    .pop(true), // Trả về true khi bấm Xóa
                              ),
                            ]);
                      },
                    );
                    if (confirm == true) {
                      await AppImageCacheManager.instance.emptyCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã xoá bộ nhớ đệm thành công!')),
                        );
                      }
                    }
                  }),
            ],
          )),
    );
  }
}
