import UIKit
import SafariServices

/// import UserNotifications
/// You can generate notifications locally from your app or remotely from a server that you manage.
/// For local notifications, the app creates the notification content and specifies a condition, like a time or location, that triggers the delivery of the notification.
/// For remote notifications, your company’s server generates push notifications, and Apple Push Notification service (APNs) handles the delivery of those notifications to the user’s devices.
import UserNotifications

enum Identifiers {
  static let viewAction = "VIEW_IDENTIFIER"
  static let newsCategory = "NEWS_CATEGORY"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  /// if your app was not running and user launches it by tapping the push notificaitons, iOS passes the notificatoin to your app in the launchOptions of application(_:didFinishLaunchingWithOptions:)
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    UITabBar.appearance().barTintColor = UIColor.themeGreenColor
    UITabBar.appearance().tintColor = UIColor.white
    
    /// set the delegate in order to handle triggered actions on notifications
    UNUserNotificationCenter.current().delegate = self
    registerForPushNotifications()
    
    /// check if app was launched from tapping a notification and if so perform this logic
    let notificationOption = launchOptions?[.remoteNotification]
    if let notification = notificationOption as? [String: AnyObject],
       let aps = notification["aps"] as? [String: AnyObject] {
      NewsItem.makeNewsItem(aps)
      (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
    }
    
    return true
  }
  
  /// if your app is active or running in the background, the system notifies your app by calling application(_:didReceiveRemoteNotification: fetchCompletionHandler:)
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    guard let aps = userInfo["aps"] as? [String: AnyObject] else {
      completionHandler(.failed)
      return
    }
    print(aps)
    NewsItem.makeNewsItem(aps)
  }
  

  func registerForPushNotifications() {
    /// ensures that the app will attempt to register for notifications any time it's launched
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
      guard let self = self else { return }
      print("UNUserNotificationCenter Permission Granted: \(granted)")
      guard granted else { return }
      
      /// configure actions on push notifications
      let viewAction = UNNotificationAction(identifier: "VIEW_IDENTIFIER", title: "View", options: [.foreground])
      let newsCategory = UNNotificationCategory(identifier: "NEWS_CATEGORY", actions: [viewAction], intentIdentifiers: [], options: [])
      UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
      
      
      self.getNotificationSettings()
    }
  }
  
  func getNotificationSettings() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("Notification settings: \(settings)")
      guard settings.authorizationStatus == .authorized else { return }
      DispatchQueue.main.async {
        /// kick off registration with APNS - apple push notification service). You need to call this on the main thread else receive runtime warning
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
  
  /// this method is called by iOS whenever a call to UIApplication.shared.registerForRemoteNotifications() succeeds. It takes a received device token and converts it to a string.
  /// the token is the fruit of this process. It's provided by APNS and uniquely identifies this app on this particular device.
  /// when sending a push notification, the server uses tokens as "addresses" to deliver to the correct devices.
  /// in your app, you would now send this token to your server to save and use later for sending notifications.
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in
      return String(format: "%02.2hhx", data)
    }
    print("DeviceToken data: \(deviceToken)")
    print("TokenParts after mapping data: \(tokenParts)")
    let token = tokenParts.joined()
    print("Token after joining the parts: \(token)")
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }

}


/// adopt and conform to UNUserNotificationCenterDelegate in order to handle Notification Actions that are triggered
extension AppDelegate: UNUserNotificationCenterDelegate {
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    if let aps = userInfo["aps"] as? [String: AnyObject],
       let newsItem = NewsItem.makeNewsItem(aps) {
      (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
      
      if response.actionIdentifier == "VIEW_IDENTIFIER",
         let url = URL(string: newsItem.link) {
        let safari = SFSafariViewController(url: url)
        window?.rootViewController?.present(safari, animated: true, completion: nil)
      }
    }
    
    completionHandler()
  }
  
  
  
}
