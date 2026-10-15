import 'dart:async';

import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/repositories/payment_repository.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/repositories/wallet_repository.dart';
import 'package:dineroo_mobile/customer/services/payment/payment_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/customer/view_models/payment/payment_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_presence_repository.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';
import 'package:dineroo_mobile/driver/view_models/driver_order_history_view_model.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:dineroo_mobile/shared/services/notification/push_navigation_resolver.dart';
import 'package:dineroo_mobile/shared/services/notification/push_lifecycle_observer.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_status_banner.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/customer/services/order/order_list_service.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_list_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/order/order_view_model.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:dineroo_mobile/shared/realtime/realtime_lifecycle_observer.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/services/auth/session_expiry_service.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/view_models/auth/auth_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:dineroo_mobile/customer/repositories/order_repository.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:dineroo_mobile/shared/views/auth/login_view.dart';
import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:dineroo_mobile/shared/views/initial_redirect_view.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';
import 'package:dineroo_mobile/shared/view_models/app_update/app_update_view_model.dart';
import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:dineroo_mobile/shared/common/observability/telemetry_lifecycle_observer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(RealtimeLifecycleObserver());

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    logger.e('Error loading .env: $e');
  }

  // Init Hive
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  await Hive.openBox<String>('recentSearches');

  Hive.registerAdapter(DeliveryAddressAdapter());
  await Hive.openBox<DeliveryAddress>('deliveryAddressBox');

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(SelectedMenuItemAdapter());
  await Hive.openBox<CartItem>('cartBox');

  WidgetsBinding.instance.addObserver(PushLifecycleObserver());

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await _bootstrapObservabilityAndRun();
}

/// Initialises tracing (OpenTelemetry -> Tempo) and crash reporting (Sentry -> GlitchTip), then
/// runs the app. Both are no-ops when unconfigured (empty OTEL endpoint / SENTRY_DSN), so local
/// dev without an obs stack is unaffected. Sentry wraps the app run so it captures errors from
/// the whole widget tree.
Future<void> _bootstrapObservabilityAndRun() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final serviceVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  AppTelemetry.init(serviceVersion: serviceVersion);
  WidgetsBinding.instance.addObserver(TelemetryLifecycleObserver());

  void startApp() {
    runApp(const DinerooApp());
    _initializePushNotificationsAfterStartup();
  }

  final dsn = dotenv.env['SENTRY_DSN'] ?? '';
  if (dsn.isEmpty) {
    startApp();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = dotenv.env['SENTRY_ENVIRONMENT'] ?? 'production';
      // Distributed traces go to Tempo via OpenTelemetry (see AppTelemetry); GlitchTip handles
      // errors/crashes only, so Sentry's own performance tracing stays off.
      options.tracesSampleRate = 0.0;
      options.attachStacktrace = true;
    },
    appRunner: startApp,
  );
}

void _initializePushNotificationsAfterStartup() {
  unawaited(
    Future<void>(() async {
      try {
        await PushNotificationService().initialize();
        logger.i('[Startup] Async push initialization completed');
      } catch (e, stack) {
        logger.e(
          '[Startup] Async push initialization failed; app startup continues',
          error: e,
          stackTrace: stack,
        );
      }
    }),
  );
}

class DinerooApp extends StatelessWidget {
  const DinerooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DinerooAppShell();
  }
}

class _DinerooAppShell extends StatefulWidget {
  const _DinerooAppShell();

  @override
  State<_DinerooAppShell> createState() => _DinerooAppShellState();
}

class _DinerooAppShellState extends State<_DinerooAppShell> {
  StreamSubscription<Map<String, dynamic>>? _openedMessageSubscription;
  final PushNavigationResolver _pushNavigationResolver =
      const PushNavigationResolver();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _openedMessageSubscription = PushNotificationService().openedMessages
        .listen((data) => unawaited(_handleOpenedPushMessage(data)));
    SessionExpiryService.configure(onExpired: () => _handleSessionExpired());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingMessage = PushNotificationService()
          .takePendingOpenedMessage();
      if (pendingMessage != null) {
        unawaited(_handleOpenedPushMessage(pendingMessage));
      }
    });
  }

  Future<void> _handleSessionExpired() async {
    final context = navigatorKey.currentContext;
    final navigator = navigatorKey.currentState;
    if (context == null || navigator == null || !context.mounted) return;

    final authViewModel = context.read<AuthViewModel>();

    await authViewModel.logoutLocal(context);
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WhoiamView()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextContext = navigatorKey.currentContext;
      if (nextContext == null || !nextContext.mounted) return;
      AppSnackbar.warning(
        nextContext,
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    });
  }

  @override
  void dispose() {
    _openedMessageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleOpenedPushMessage(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final currentContext = navigator.context;
    final authViewModel = currentContext.read<AuthViewModel>();
    final currentUserViewModel = currentContext.read<CurrentUserViewModel>();
    final payload = PushNotificationPayload.fromData(data);
    var currentUser = currentUserViewModel.currentUser;

    if (currentUser == null && payload.type != null) {
      final isAuthenticated = await authViewModel.isAuthenticated();
      if (!mounted) return;

      if (isAuthenticated) {
        final refreshedContext = navigatorKey.currentContext;
        if (refreshedContext == null || !refreshedContext.mounted) return;

        await authViewModel.loadUserFromToken(refreshedContext);
        if (!mounted) return;
        currentUser = currentUserViewModel.currentUser;
      } else {
        PushNotificationService().savePendingNavigationPayload(data);

        final fallbackScreen =
            payload.type == PushNotificationType.courierDecision
            ? const LoginView(selectedRole: UserRole.driver)
            : const WhoiamView();

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => fallbackScreen),
          (route) => false,
        );
        return;
      }
    }

    final targetScreen = _pushNavigationResolver.resolve(
      currentUser: currentUser,
      payload: payload,
    );

    if (targetScreen != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InitialRedirectView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrentUserViewModel()),
        ChangeNotifierProvider(create: (_) => UserRoleViewModel()),
      ],
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AppUpdateViewModel(AppUpdateService()),
            ),
            ChangeNotifierProvider(
              create: (_) => AuthViewModel(
                AuthRepository(
                  AuthService(),
                  context.read<CurrentUserViewModel>(),
                  context.read<UserRoleViewModel>(),
                ),
              ),
            ),
            ChangeNotifierProvider(create: (_) => LocationViewModel()),
            ChangeNotifierProvider(
              create: (_) =>
                  UserViewModel(UserRepository(service: UserService())),
            ),
            ChangeNotifierProvider(create: (_) => CartViewModel()),
            ChangeNotifierProvider(
              create: (_) => OrderViewModel(
                OrderRepository(
                  orderService: OrderService(),
                  listService: OrderListService(),
                  sharedOrderService: SharedOrderService(),
                ),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => OrderListViewModel(
                OrderRepository(
                  orderService: OrderService(),
                  listService: OrderListService(),
                  sharedOrderService: SharedOrderService(),
                ),
                context.read<CurrentUserViewModel>(),
              )..fetchOrders(),
            ),
            ChangeNotifierProvider(
              create: (_) => RestaurantViewModel(
                RestaurantRepository(
                  service: RestaurantService(),
                  listService: RestaurantListService(),
                ),
              ),
            ),
            Provider<PaymentService>(create: (_) => PaymentService()),
            Provider<WalletService>(create: (_) => WalletService()),
            Provider<PaymentRepository>(
              create: (ctx) =>
                  PaymentRepository(service: ctx.read<PaymentService>()),
            ),
            Provider<WalletRepository>(
              create: (ctx) =>
                  WalletRepository(service: ctx.read<WalletService>()),
            ),
            ChangeNotifierProvider<PaymentViewModel>(
              create: (ctx) => PaymentViewModel(ctx.read<PaymentRepository>()),
            ),
            ChangeNotifierProvider<WalletViewModel>(
              create: (ctx) => WalletViewModel(ctx.read<WalletRepository>()),
            ),
            ChangeNotifierProvider(
              create: (ctx) => DriverHomeViewModel(
                DriverPresenceRepository(service: DriverPresenceService()),
                DriverDeliveryRepository(service: DriverDeliveryService()),
                DriverOrderRepository(
                  orderService: SharedOrderService(),
                  orderDetailsRepository: OrderDetailsRepository(
                    service: OrderDetailsService(),
                  ),
                ),
                RestaurantRepository(
                  service: RestaurantService(),
                  listService: RestaurantListService(),
                ),
                ctx.read<CurrentUserViewModel>(),
              ),
            ),
            ChangeNotifierProvider(
              create: (ctx) => DriverOrderHistoryViewModel(
                DriverDeliveryRepository(service: DriverDeliveryService()),
                DriverOrderRepository(
                  orderService: SharedOrderService(),
                  orderDetailsRepository: OrderDetailsRepository(
                    service: OrderDetailsService(),
                  ),
                ),
                ctx.read<CurrentUserViewModel>(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => ManagerOrderReceptionViewModel(
                repository: ManagerOrderRepository(
                  service: ManagerOrderService(),
                ),
              ),
            ),
            ChangeNotifierProvider(
              create: (ctx) => ManagerRestaurantViewModel(
                ManagerRestaurantRepository(
                  service: ManagerRestaurantService(),
                ),
                currentUserViewModel: ctx.read<CurrentUserViewModel>(),
              ),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Dineroo',
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: const TextScaler.linear(1.0), // Disables scaling
                ),
                child: AppNetworkStatusBanner(child: child!),
              );
            },
            theme: ThemeData(
              fontFamily: 'Montserrat',
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
              ),
            ),
            home: const InitialRedirectView(),
          ),
        );
      },
    );
  }
}
