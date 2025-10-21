import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let deepLinkChannel = FlutterMethodChannel(name: "qr_redirector/deep_link",
                                               binaryMessenger: controller.binaryMessenger)
    
    deepLinkChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getInitialLink":
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
          result(url.absoluteString)
        } else {
          result(nil)
        }
      case "getLinkStream":
        // Для спрощення повертаємо nil - в реальному додатку тут був би stream
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let deepLinkChannel = FlutterMethodChannel(name: "qr_redirector/deep_link",
                                               binaryMessenger: controller.binaryMessenger)
    
    deepLinkChannel.invokeMethod("onDeepLink", arguments: url.absoluteString)
    
    return true
  }
}