import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var isFlutterEngineReady = false
  private var flutterViewController: FlutterViewController?
  private var pendingNotificationData: [String: Any]?
  private var lastHandledNotificationId: String?
  
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
    
    // Store references
    flutterViewController = controller
    isFlutterEngineReady = true
    
    // Handle any pending notifications
    if let pendingData = pendingNotificationData {
      print("📬 Processing pending notification data: \(pendingData)")
      handleNotificationData(pendingData)
      pendingNotificationData = nil
    }
    
    // Set up notification permissions
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
  
  private func handleNotificationData(_ userInfo: [AnyHashable: Any], wasUserInteraction: Bool = false) {
    guard isFlutterEngineReady, let controller = flutterViewController else {
      print("❌ Flutter engine not ready, storing notification data for later")
      pendingNotificationData = userInfo as? [String: Any]
      return
    }
    
    // Check for duplicate notification
    if let messageId = userInfo["gcm.message_id"] as? String {
      if messageId == lastHandledNotificationId {
        print("🔄 Skipping duplicate notification: \(messageId)")
        return
      }
      lastHandledNotificationId = messageId
    }
    
    print("📦 Handling notification data: \(userInfo)")
    
    // Extract data from userInfo
    var notificationData: [String: Any] = [:]
    
    // Try to get data from FCM format
    if let data = userInfo["data"] as? [String: Any] {
      notificationData = data
      // Ensure type is properly extracted from data
      if let type = data["type"] as? String {
        notificationData["type"] = type
      }
    }
    // Try to get data from APNS format
    else if let aps = userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any] {
      notificationData["title"] = alert["title"]
      notificationData["body"] = alert["body"]
      
      // Extract custom data and ensure type is preserved
      for (key, value) in userInfo {
        if key as? String != "aps" {
          if key as? String == "type" {
            notificationData["type"] = value
          } else {
            notificationData[key as? String ?? ""] = value
          }
        }
      }
    }
    // Try to get data directly
    else {
      for (key, value) in userInfo {
        if key as? String == "type" {
          notificationData["type"] = value
        } else {
          notificationData[key as? String ?? ""] = value
        }
      }
    }
    
    // Add wasUserInteraction flag to the notification data
    notificationData["wasUserInteraction"] = wasUserInteraction
    
    print("📤 Sending notification data to Flutter: \(notificationData)")
    
    // Create method channel
    let channel = FlutterMethodChannel(
      name: "com.payviya.app/notifications",
      binaryMessenger: controller.binaryMessenger
    )
    
    // Send notification data to Flutter
    channel.invokeMethod("handleNotification", arguments: notificationData)
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

extension AppDelegate {
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("📬 Received notification while app in foreground: \(userInfo)")
    
    // Just display the notification, don't handle data yet
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
    
    // Only handle data when user actually taps the notification
    handleNotificationData(userInfo, wasUserInteraction: true)
    completionHandler()
  }
  
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📬 Received remote notification: \(userInfo)")
    
    // Don't handle data automatically, wait for user interaction
    completionHandler(.newData)
  }
}
