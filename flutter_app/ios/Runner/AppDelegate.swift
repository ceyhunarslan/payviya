import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var isFlutterEngineReady = false
  private var flutterViewController: FlutterViewController?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase configuration
    FirebaseApp.configure()
    print("🔥 Firebase configured in AppDelegate")
    
    // Initialize Flutter engine with explicit configuration
    let flutterEngine = FlutterEngine(name: "main_engine")
    
    // Run the engine with default configuration
    guard flutterEngine.run() else {
        print("❌ Failed to run Flutter engine")
        return false
    }
    print("✅ Flutter engine started successfully")
    
    // Wait a short moment to ensure engine is fully initialized
    Thread.sleep(forTimeInterval: 0.1)
    
    // Register plugins after engine is running
    GeneratedPluginRegistrant.register(with: flutterEngine)
    
    // Create and configure the Flutter view controller
    let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    controller.modalPresentationStyle = .fullScreen
    controller.view.backgroundColor = .white
    
    // Load default splash screen
    _ = controller.loadDefaultSplashScreenView()
    print("🎨 Splash screen loaded")
    
    // Configure and set up the window
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.backgroundColor = .white
    window.rootViewController = controller
    self.window = window
    window.makeKeyAndVisible()
    
    // Store references and set up method channel
    flutterViewController = controller
    
    // Set up method channel for splash screen
    let channel = FlutterMethodChannel(name: "app.channel.shared.data",
                                     binaryMessenger: flutterEngine.binaryMessenger)
    
    channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "splashScreenFinished" {
            print("🎬 Received splash screen finished signal from Flutter")
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Handle any pending deep links
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      print("🔗 Found URL in launch options: \(url.absoluteString)")
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("🔔 Notification permission granted: \(granted)")
          if let error = error {
            print("❌ Notification permission error: \(error)")
          }
        }
      )
    }
    
    application.registerForRemoteNotifications()
    print("📱 Registered for remote notifications")
    
    Messaging.messaging().delegate = self
    print("📨 Messaging delegate set")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    print("📲 APNS token set: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔑 Firebase registration token: \(String(describing: fcmToken))")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

// UNUserNotificationCenterDelegate methods
extension AppDelegate {
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("📬 Received notification while app in foreground: \(userInfo)")
    
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound]])
    } else {
      completionHandler([[.alert, .sound]])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("📬 Notification tapped: \(userInfo)")
    
    // Convert userInfo to JSON string for Flutter
    if let data = try? JSONSerialization.data(withJSONObject: userInfo),
       let jsonString = String(data: data, encoding: .utf8) {
      // Send notification tap event to Flutter
    }
    
    completionHandler()
  }
}
