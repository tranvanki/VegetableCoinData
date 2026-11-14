import 'package:flutter/material.dart' hide SearchBar;
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/theme/app_colors.dart';
import 'package:hhmmobile/views/screens/token_list.dart';
import 'package:hhmmobile/views/widgets/common/search_widget.dart';
import 'package:provider/provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../../../providers/app_state_provider.dart';

import '../widgets/common/search_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    //safe Area on top
    return Scaffold(
      //Screen widget

      //search widget
      appBar: AppBar(
          title: SizedBox(
        child:
            // SearchWidget(
            //   ontap:()=> context.push(AppRoutes.search)
            // )
            Text('CoinGecko'),
      )),
      body: Container(
          color: const Color.fromARGB(255, 243, 238, 238), child: TokenList()),
    );
  }
}
