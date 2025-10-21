import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var deepLinkChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    deepLinkChannel = FlutterMethodChannel(name: "qr_redirector/deep_link",
                                           binaryMessenger: controller.binaryMessenger)
    
    deepLinkChannel?.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getInitialLink":
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
          print("[AppDelegate] Initial deep link: \(url.absoluteString)")
          result(url.absoluteString)
        } else {
          result(nil)
        }
      case "getLinkStream":
        // Stream реалізований через onDeepLink метод
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("[AppDelegate] Runtime deep link received: \(url.absoluteString)")
    
    // Відправляємо deep link в Flutter
    deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
    
    return true
  }
}