import Flutter
import UIKit

//@main
@objc class AppDelegate: FlutterAppDelegate {
    var flutterEngine: FlutterEngine?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // FlutterEngineを初期化
        flutterEngine = FlutterEngine(name: "MyFlutterEngine")
        flutterEngine?.run()
        
        GeneratedPluginRegistrant.register(with: flutterEngine!)
        
        // FlutterViewControllerをflutterEngineを使用して初期化
        let flutterViewController = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)
        
        // windowを設定し、rootViewControllerにFlutterViewControllerを設定
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = flutterViewController
        self.window?.makeKeyAndVisible()
        
        // BatteryHostApiのセットアップ
        let batteryApi = BatteryHostApiImpl(binaryMessenger: flutterEngine!.binaryMessenger)
        BatteryHostApiSetup.setUp(binaryMessenger: flutterEngine!.binaryMessenger, api: batteryApi)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
