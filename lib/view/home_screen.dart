import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';

import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/event_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/transaction_provider.dart';
import 'package:outi_log/view/component/app_drawer.dart';
import 'package:outi_log/view/component/schedule/dialog_component.dart';
import 'package:outi_log/view/household_budget.dart';
import 'package:outi_log/view/schedule_screen.dart';
import 'package:outi_log/view/shopping_list_screen.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:provider/provider.dart' as provider_package;

// 画面下部のナビゲーションの状態を管理するProvider
final homeScreenIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<Widget> _screens = [
    ScheduleScreen(),
    AccountBookScreen(),
    ShoppingListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpace();
  }

  Future<void> _initializeSpace() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // Firestoreスペースプロバイダーを初期化
      await ref.read(firestoreSpacesProvider.notifier).initializeSpaces();

      // 従来のローカルスペースも並行して初期化（移行中のため）
      await ref.read(spacesProvider.notifier).initializeSpaces(currentUser.uid);
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'スケジュール';
      case 1:
        return '家計簿';
      case 2:
        return '買い物リスト';
      default:
        return 'おうちログ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeScreenIndexProvider);

    // Firestoreスペースを優先的に使用
    final firestoreSpaces = ref.watch(firestoreSpacesProvider);
    final localSpaces = ref.watch(spacesProvider);

    // Firestoreにスペースがある場合はそちらを使用、なければローカルを使用
    final spaces = firestoreSpaces ?? localSpaces;
    final currentSpace = spaces?.currentSpace;

    return provider_package.MultiProvider(
      providers: [
        provider_package.ChangeNotifierProvider(
            create: (context) => EventNotifier()),
        provider_package.ChangeNotifierProvider(
            create: (context) => TransactionNotifier()),
      ],
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            currentSpace != null ? _getAppBarTitle(selectedIndex) : 'スペースなし',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: themeColor,
          // actions: currentSpace != null && selectedIndex == 0
          //     ? [
          //         IconButton(
          //           icon: const Icon(Icons.add, color: Colors.white),
          //           onPressed: () {
          //             showDialog(
          //               context: context,
          //               builder: (context) => const DialogComponent(),
          //             );
          //           },
          //         ),
          //       ]
          //     : null,
        ),
        drawer: const AppDrawer(),
        body: currentSpace != null
            ? _screens[selectedIndex]
            : _buildNoSpaceView(),
        bottomNavigationBar: currentSpace != null
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: selectedIndex,
                onTap: (index) =>
                    ref.read(homeScreenIndexProvider.notifier).state = index,
                selectedItemColor: themeColor,
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today),
                    label: 'スケジュール',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet),
                    label: '家計簿',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: '買い物リスト',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildNoSpaceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'スペースがありません',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'スペースを作成して、\n家族やカップルと共有を始めましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpaceAddScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'スペースを作成',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
