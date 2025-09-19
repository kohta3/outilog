import Flutter
import UIKit
import Firebase
import FirebaseCrashlytics

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase初期化
    FirebaseApp.configure()
    
    // Crashlytics初期化
    #if !DEBUG
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
