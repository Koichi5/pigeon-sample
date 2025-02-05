## 初めに
今回は Flutter から Swift を呼び出す実装を行いたいと思います。
最終的には Swift 独自のライブラリである CoreML を用いて分析した結果を Flutter 側に返して表示する実装を行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ Flutter から Swift を呼び出す実装を行いたい方
+ Flutter で Swift 独自の機能を使用する実装を行いたい方

## 目的
今回は先述の通り、Flutter から Swift を呼び出す実装を行いたいと思います。
Flutter から Swift を呼び出すことで Flutter 単体では手の届かないネイティブの機能を実装できます。

## 実装
実装は以下の手順で進めていきたいと思います。
1. Swift から文字列を取得する実装
2. Swift から CoreML の分析結果を取得する実装

:::message
第2章の「Swift から CoreML の分析結果を取得する実装」はSwiftに依存した内容を多く含むため、FlutterからSwiftの簡単な処理を呼び出すだけであれば必要ないかもしれません。
:::

### 1. Swiftから文字列を取得する実装
コードは以下の通りです。
```dart: swift_on_flutter_sample_screen.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwiftOnFlutterSampleScreen extends HookWidget {
  const SwiftOnFlutterSampleScreen({super.key});

  // Swift側のメソッドチャンネルと紐付ける No.1
  final MethodChannel _methodChannel = const MethodChannel('com.example.flutter');　

  @override
  Widget build(BuildContext context) {
    final result = useState('Swift から値を取得してみましょう');
    Future helloSwift() async {  // No.3
      try {
        var response = await _methodChannel.invokeMethod('helloSwift');  // No.4
        result.value = response;  // No.8
      } on PlatformException catch (e) {
        log(e.message ?? 'Unexpected PlatformException');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Swiftのコードを呼び出し"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(result.value),  // No.9
            ),
            ElevatedButton(
              onPressed: () {
                helloSwift();  // No.2
              },
              child: const Text('Swift 呼び出し'),
            ),
          ],
        ),
      ),
    );
  }
}
```

```swift: ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private let methodChannelName = "com.example.flutter"
    public var result: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        // No.5
        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller as! FlutterBinaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] methodCall, result  in
            //Flutterで実行したinvokedMethodを受け取る処理 No.6
            hellowSwift(result)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

private func hellowSwift(_ result: @escaping FlutterResult) {
    result("Hello Flutter👋 \n This is Swift !")  // No.7
}
```

上記のコードを実行すると以下のように表示され、ボタンを押した時点でテキストが切り替わることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/1a8396e5acfb-20240511.gif =350x)

コードをそれぞれ詳しくみていきます。

以下では `_methodChannel` 変数としてメソッドチャネルを定義しています。
`MethodChannel` の説明としては以下のような記述があります。
> MethodChannelは非同期メソッド呼び出しを使用してプラットフォームプラグインと通信するための名前付きチャンネルです。メソッド呼び出しは送信前にバイナリにエンコードされ、受信したバイナリ結果はDartの値にデコードされます。

`MethodChannel` に名前を定義することで、ネイティブで実行する処理をまとめることができます。
```dart
final MethodChannel _methodChannel = const MethodChannel('com.example.flutter');
```

次に以下の部分です。
`result` では初期値として表示するテキストと、Swift側から返ってきた結果を管理しています。
`helloSwift` では `invokeMethod` を使って Swift 側にリクエストを送り、その返り値を `response` に代入し、さらにその結果を `result.value` に代入しています。

```dart
final result = useState('Swift から値を取得してみましょう');
Future helloSwift() async {
  try {
    var response = await _methodChannel.invokeMethod('helloSwift');
    result.value = response;
  } on PlatformException catch (e) {
    log(e.message ?? 'Unexpected PlatformException');
  }
}
```

以下では先ほど定義した `helloSwift` を実行しています。
```dart
ElevatedButton(
  onPressed: () {
    helloSwift();
  },
  child: const Text('Swift 呼び出し'),
),
```

次に `AppDelegate.swift` についてです。Flutterとのやり取りは基本的に `AppDelegate` で行います。
以下ではメソッドチャネルの名前と Flutter側に返す `result` の定義をしています。
```swift
private let methodChannelName = "com.example.flutter"
public var result: FlutterResult?
```

次に以下の部分では、`FlutterViewController` と `FlutterMethodChannel` の定義を行い、`setMethodCallHandler` の中で Swift 側で定義した処理を実行しています。
今実装している関数は後述する `hellowSwift` 関数のみであるため、`methodChannel` を通じて行われる処理に関しては全て `hellowSwift` が実行されるようになります。
```swift
let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller as! FlutterBinaryMessenger)
methodChannel.setMethodCallHandler { [weak self] methodCall, result  in
  //Flutterで実行したinvokedMethodを受け取る処理
  hellowSwift(result)
}
```

Flutter側からの処理によって呼び出される `helloSwift` の実装は以下のようになっています。
処理としては `FlutterResult` として簡単な文字列を返却する処理となっています。
```swift
private func helloSwift(_ result: @escaping FlutterResult) {
    result("Hello Flutter👋 \n This is Swift !")
}
```

簡単にまとめると以下のような手順になるかと思います。
1. Flutter から MethodChannel を作成
2. MethodChannel で invokeMethod を名前Xをつけて呼び出して、Swift側にアクセス
3. Swift 側で名前Xに合致する関数を実行
4. 返り値を FlutterResult として Flutter 側で取得して表示

invokeMethod の 「invoke」 は「呼び出す」という意味なので、Swiftにアクセスするチャネルを通して、Swift側のメソッドを呼び出すイメージです。

::: details より詳しいコードの流れ
今までの具体的な処理の流れを Flutter -> Swift -> Flutter の順番で番号を振っているので、それを元に追っていきます。

```dart
// Flutter側
// No.1 メソッドチャネルとチャネル名の設定
final MethodChannel _methodChannel = const MethodChannel('com.example.flutter');

// No.2　Swiftとのやりとりを含む処理の実行
helloSwift();

// No.3 処理の参照
Future helloSwift() async {

// No.4 No.１で作成したチャネルから invokeMethod を呼び出し（この時メソッド名「helloSwift」も設定）
var response = await _methodChannel.invokeMethod('helloSwift');

// Swift側
// No.5　FlutterMethodChannel として Flutter 側で定義した名前と同じ名前のチャネルを作成
let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller as! FlutterBinaryMessenger)

// No.6 No.5で定義したチャネルで hellowSwift を実行
methodChannel.setMethodCallHandler { [weak self] methodCall, result  in
  hellowSwift(result)
}

// No.7 文字列を返す関数を実行して result を返す
result("Hello Flutter👋 \n This is Swift !")

// Flutter側
// No.8 Swiftから返ってきたレスポンスを useState の文字列に代入
result.value = response;

// No.9 テキストとして表示
child: Text(result.value),
```
:::

### 2. Swift から CoreML の分析結果を取得する実装
次に、Swift の CoreML ライブラリを Flutter 側から呼び出して実行するような実装を行います。
今回は以下のリポジトリを元に画像のURLを入力するとその画像に写っているものを判別するような機能を実装していきます。
https://github.com/Abhiek187/CoreML-Example/tree/master/Vision%2BML%20Example

最終的には以下の動画のように、画像のURLを入力すると、画像に写っているものを判別してラベルと正確性を表示するような実装を行いたいと思います。
https://youtube.com/shorts/jWD-c7EmajU?feature=share

こちらの実装に際して以下の手順で行いたいと思います。
1. Flutter 側で Swift を呼び出す実装
2. CoreMLのモデルを追加
3. CoreMLを用いて画像に映っているものを判別する実装
4. AppDelegateの編集

今回の実装に関して、Swift側の多少複雑になってしまったため、適宜以下のGitHubを参照しつつ実装していただけると幸いです。
https://github.com/Koichi5/sample-flutter/tree/feature/swift_on_flutter

#### 1. Flutter 側で Swift を呼び出す実装
まずは Flutter 側の実装です。コードは以下の通りです。
```dart: swift_on_flutter_core_ml_sample.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwiftOnFlutterCoreMlSample extends HookWidget {
  const SwiftOnFlutterCoreMlSample({super.key});

  final MethodChannel _methodChannel = const MethodChannel('com.example.flutter');

  @override
  Widget build(BuildContext context) {
    final result = useState('分析結果を表示します...');
    final imageUrlController = useTextEditingController(
      text:
          'https://cdn.pixabay.com/photo/2017/11/02/00/34/parrot-2909828_1280.jpg',
    );

    Future getTextLabelFromImage({required String imageUrl}) async {
      final arguments = {'imageUrl': imageUrl};
      try {
        var response = await _methodChannel.invokeMethod(
            'getTextLabelFromImage', arguments);
        result.value = response;
      } on PlatformException catch (e) {
        log(e.message ?? 'Unexpected PlatformException');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreML on Flutter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller: imageUrlController,
                    onSubmitted: (value) {
                      imageUrlController.text = value;
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    getTextLabelFromImage(imageUrl: imageUrlController.text);
                  },
                  child: const Text('分析'),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.cover,
              imageUrlController.text,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(result.value),
          ),
        ],
      ),
    );
  }
}
```

それぞれ詳しくみていきます。

以下の部分では前の章と同様に Swift にアクセスするチャネルを作成しています。
なお、今回は処理内容によってチャネルを変えることはしないので、前の章と同じ「com.example.flutter」という名前で作成しています。
```dart
final MethodChannel _methodChannel = const MethodChannel('com.example.flutter');
```

次に以下の部分です。
ここでは分析結果と初期のテキスト内容を保持する `result` と画像のURLの変化を保持する `imageUrlController` を定義しています。
```dart
final result = useState('分析結果を表示します...');
final imageUrlController = useTextEditingController(
      text:
          'https://cdn.pixabay.com/photo/2017/11/02/00/34/parrot-2909828_1280.jpg',
);
```

以下では前の章と同様に `invokeMethod` を使って Swift 側にアクセスしています。
今回の関数の名前は `getTextLabelFromImage` としており、第二引数に Swift 側に渡すためのデータを格納しています。
Swift 側には key に「imageUrl」という String、 value に検証したい画像のURLを持つ `arguments` を渡しています。Swift側ではこのデータを取り出して、CoreMLに画像を読み込ませることで分析ができるようになります。
また、Swift から返ってきた分析結果を `response` に代入し、それをさらに `result.value` に代入するという点は前の章と同じかと思います。
```dart
Future getTextLabelFromImage({required String imageUrl}) async {
  final arguments = {'imageUrl': imageUrl};
  try {
    var response = await _methodChannel.invokeMethod(
      'getTextLabelFromImage', arguments
    );
    result.value = response;
  } on PlatformException catch (e) {
    log(e.message ?? 'Unexpected PlatformException');
  }
}
```

以下では画像のURLを保持する `TextField` を実装しています。
controller として `imageUrlController` を指定しているため、 `imageUrlController.text` で入力されたURLを取得することができます。
```dart
child: TextField(
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
  ),
  controller: imageUrlController,
  onSubmitted: (value) {
    imageUrlController.text = value;
  },
),
```

以下では先ほど定義した `getTextLabelFromImage` を実行する `TextButton` を実装しています。
`imageUrl` にはユーザーが入力したURLを代入しています。
```dart
TextButton(
  onPressed: () {
    getTextLabelFromImage(imageUrl: imageUrlController.text);
  },
  child: const Text('分析'),
),
```

以下ではユーザーが入力したURLに対応する画像と分析結果のテキストを表示しています。
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Image.network(
    width: MediaQuery.of(context).size.width * 0.9,
    height: MediaQuery.of(context).size.width * 0.6,
    fit: BoxFit.cover,
    imageUrlController.text,
  ),
),
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Text(result.value),
),
```

これで Flutter 側では Swiftに対して画像のURLを送り、返ってきた結果を表示するまでの実装が完了しました。

#### 2. CoreMLのモデルを追加
次にCoreMLのモデルを追加します。
モデルは以下のGitHubの `MobileNet.mlmodel` を使用します。
https://github.com/Abhiek187/CoreML-Example/tree/master/Vision%2BML%20Example/Model

git clone するかダウンロードして Runner ディレクトリの中に配置すると Swift側でモデルを使用できるようになります。

#### 3. CoreMLを用いて画像に映っているものを判別する実装
次に CoreML に関する実装です。この部分が複雑になってしまいました。
コードは以下の通りです。
```swift: ios/Runner/MainController/MainViewController.swift
import UIKit
import SwiftUI

@available(iOS 13.0, *)
class MainViewController: UIViewController {
    @Published var predictionContents = ""
    let imagePredictor = ImagePredictor()
    let predictionsToShow = 2
}

@available(iOS 13.0, *)
extension MainViewController {
    public func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        print("predictionString: \(predictionString)")
        self.predictionContents = predictionString
    }

    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }
            return "\(name) - \(prediction.confidencePercentage)%"
        }
        return topPredictions
    }
}
```

```swift: ios/Runner/Image Predictor/ImagePredictor.swift
import Vision
import UIKit

class ImagePredictor {
    static func createImageClassifier() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()

        let imageClassifierWrapper = try? MobileNet(configuration: defaultConfig)

        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }

        let imageClassifierModel = imageClassifier.model

        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }

        return imageClassifierVisionModel
    }

    private static let imageClassifier = createImageClassifier()
    struct Prediction {
        let classification: String
        let confidencePercentage: String
    }

    typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void

    private var predictionHandlers = [VNRequest: ImagePredictionHandler]()

    private func createImageClassificationRequest() -> VNImageBasedRequest {
        let imageClassificationRequest = VNCoreMLRequest(model: ImagePredictor.imageClassifier,
                                                         completionHandler: visionRequestHandler)

        imageClassificationRequest.imageCropAndScaleOption = .centerCrop
        return imageClassificationRequest
    }

    func makePredictions(for photo: UIImage, completionHandler: @escaping ImagePredictionHandler) throws {
        let orientation = CGImagePropertyOrientation(photo.imageOrientation)

        guard let photoImage = photo.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }

        let imageClassificationRequest = createImageClassificationRequest()
        predictionHandlers[imageClassificationRequest] = completionHandler

        let handler = VNImageRequestHandler(cgImage: photoImage, orientation: orientation)
        let requests: [VNRequest] = [imageClassificationRequest]

        try handler.perform(requests)
    }

    private func visionRequestHandler(_ request: VNRequest, error: Error?) {
        guard let predictionHandler = predictionHandlers.removeValue(forKey: request) else {
            fatalError("Every request must have a prediction handler.")
        }

        var predictions: [Prediction]? = nil

        defer {
            predictionHandler(predictions)
        }

        if let error = error {
            print("Vision image classification error...\n\n\(error.localizedDescription)")
            return
        }

        if request.results == nil {
            print("Vision request had no results.")
            return
        }

        guard let observations = request.results as? [VNClassificationObservation] else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }

        predictions = observations.map { observation in
            Prediction(classification: observation.identifier,
                       confidencePercentage: observation.confidencePercentageString)
        }
    }
}
```

```swift: ios/Runner/Extensions/VNClassificationObservation+confidenceString.swift
import Vision

extension VNClassificationObservation {
    var confidencePercentageString: String {
        let percentage = confidence * 100

        switch percentage {
            case 100.0...:
                return "100%"
            case 10.0..<100.0:
                return String(format: "%2.1f", percentage)
            case 1.0..<10.0:
                return String(format: "%2.1f", percentage)
            case ..<1.0:
                return String(format: "%1.2f", percentage)
            default:
                return String(format: "%2.1f", percentage)
        }
    }
}
```

```swift:ios/Runner/Extensions/CGImagePropertyOrientation+UIImageOrientation.swift
import UIKit
import ImageIO

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
            case .up: self = .up
            case .down: self = .down
            case .left: self = .left
            case .right: self = .right
            case .upMirrored: self = .upMirrored
            case .downMirrored: self = .downMirrored
            case .leftMirrored: self = .leftMirrored
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}
```

非常に長くなってしまいましたが、それぞれの主な役割は以下のようになっています。
| ソース | 役割 |
| ---- | ---- |
| MainViewController | 他のファイルの処理をまとめて分析処理を実行する |
| ImagePredictor | モデルの読み込みから推論までを行う |
| CGImagePropertyOrientation | 画像の向きなどを判別するextension |
| VNClassificationObservation | 分析の正確性を保持するextension |

コードの非常に大まかな流れとしては以下のようになっています。
1. `MainViewController` の `classifyImage` 関数に画像を渡す
2. `ImagePredictor` の `makePredictions` で渡された画像に基づいて推論を行う
3. 推論結果が `MainViewController` の `predictionContents` に代入される

この時、分析を行う `classifyImage` 関数の入力は画像（UIImage）、出力である `predictionContents` はString となっています。

今回使用した CoreML のより詳しい説明や具体的な実装は以下をご覧ください。
https://github.com/Abhiek187/CoreML-Example

#### 4. AppDelegateの編集
最後に `AppDelegate` の編集を行います。
コードは以下の通りです。
```swift
import UIKit
import Flutter
import CoreML
import Vision

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    // メソッドチャネルの定義
    private let methodChannelName = "com.example.flutter"
    public var result: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller as! FlutterBinaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] methodCall, result  in
            //Flutterで実行したinvokedMethodを受け取る処理
            methodChannel.setMethodCallHandler(handleMethodCall)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

private func handleMethodCall(_ methodCall: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch methodCall.method {
    case "helloSwift":
        helloSwift(result)
    case "getTextLabelFromImage":
        guard let args = methodCall.arguments as? [String: String] else { return }
        let imageUrl = args["imageUrl"]!
        getTextLabelFromImage(result: result, imageUrl: imageUrl)
    default:
        result(FlutterMethodNotImplemented)
    }
}

private func helloSwift(_ result: @escaping FlutterResult) {
    result("Hello Flutter👋 \n This is Swift !")
}

private func getTextLabelFromImage(result: @escaping FlutterResult, imageUrl: String) {
    print("getTextLabelFromImage fired")

    // 非同期的に画像を取得する関数
    func getImageByUrl(url: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: url) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }

    getImageByUrl(url: imageUrl) { image in
        guard let image = image else {
            result(FlutterError(code: "Error", message: "Could not download the image", details: nil))
            return
        }
        if #available(iOS 13.0, *) {
            let controller = MainViewController()
            controller.classifyImage(image)
            print("predictionContents: \(controller.predictionContents)")
            result(controller.predictionContents)
        } else {
            result(FlutterError(code: "Flutter Error", message: "Error", details: nil))
        }
    }
}
```

前の章から追加、変化した点を中心に詳しくみていきます。

以下の部分はSwiftに定義されている関数をFlutterからのアクセスに応じて実行する部分です。
前の章ではどんなFlutterからのアクセスに対しても `hellowSwift` しか実行する関数がなかったため、`hellowSwift(result)`としてありました。
しかし、 Flutter からのアクセスを行い、Swiftの別々のコードを実行したい場合はそれぞれのアクセスに対して別の関数を実行する必要があります。
そこで以下のように `handleMethodCall` を設けて実行する関数を切り替えています。
```swift diff
methodChannel.setMethodCallHandler { [weak self] methodCall, result  in
   //Flutterで実行したinvokedMethodを受け取る処理
-  hellowSwift(result)
+  methodChannel.setMethodCallHandler(handleMethodCall)
}
```

次に以下についてです。
先ほど述べた `handleMethodCall` は以下のような実装になっています。
`methodCall.method` には実行したい関数の名前が入っており、その関数の名前によって実行する関数を切り替えています。この関数の名前は Flutter 側で `invokeMethod` を実行する時に引数に入れる名前と一致している必要があります。
```swift
private func handleMethodCall(_ methodCall: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch methodCall.method {
    case "helloSwift":
        helloSwift(result)
    case "getTextLabelFromImage":
        guard let args = methodCall.arguments as? [String: String] else { return }
        let imageUrl = args["imageUrl"]!
        getTextLabelFromImage(result: result, imageUrl: imageUrl)
    default:
        result(FlutterMethodNotImplemented)
    }
}
```

`invokeMethod` を Flutter 側で実行した際、`getTextLabelFromImage` という関数の名前と一緒に第二引数に `arguments` という変数を代入しました。
上記のコードでは `methodCall.arguments` を取り出すことで、第二引数に代入した値を参照することができ、さらにそこから `args["imageUrl"]` とすることで、 `imageUrl` を key にもつ value 、つまりユーザーが入力した画像のURLを取得することができます。
こうして取得した画像のURLを `getTextLabelFromImage` 関数に渡しています。

以下は `getTextLabelFromImage` 関数の実装です。
この関数で行なっていることは以下の三点です。
1. URLから非同期的に画像を取得して UIImage に変換する
2. UIImage を `classifyImage` 関数に渡して、画像に写っているものの推論を行う
3. 推論結果を `result(controller.predictionContents)` として Flutter 側に返す
```swift
private func getTextLabelFromImage(result: @escaping FlutterResult, imageUrl: String) {
    print("getTextLabelFromImage fired")

    // 非同期的に画像を取得する関数
    func getImageByUrl(url: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: url) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }

    getImageByUrl(url: imageUrl) { image in
        guard let image = image else {
            result(FlutterError(code: "Error", message: "Could not download the image", details: nil))
            return
        }
        if #available(iOS 13.0, *) {
            let controller = MainViewController()
            controller.classifyImage(image)
            print("predictionContents: \(controller.predictionContents)")
            result(controller.predictionContents)
        } else {
            result(FlutterError(code: "Flutter Error", message: "Error", details: nil))
        }
    }
}
```

これで画像に写っているものを分析する一連の流れは完了です。
実行すると以下の動画のように画像に写っているものの判別ができるようになるかと思います。
https://youtube.com/shorts/jWD-c7EmajU?feature=share

改めて確認すると以下のような流れになります。

1. ユーザーが分析したい画像のURLを入力する
2. `invokeMethod` を実行して `getTextLabelFromImage` という関数名と画像URLを Swift側に渡す
3. Flutterからのアクセスを検知して `AppDelegate` で関数名に応じて実行する関数を決定
4. 画像URLを `arguments` から取得する
5. 取得した画像URLを UIImage に変更する
6. UIImage を `MainViewController` の `classifyImage` に渡す
7. 画像に写っているものが推論される
8. 推論結果が `controller.predictionContents` に代入される
9. `result` に推論結果を入れて Flutter 側に返す
10. Swift から返ってきた値を画像のラベルとして表示

以上です。

## まとめ
最後まで読んでいただいてありがとうございました。

第2章に関しては「Flutter から Swift を呼び出す」という例として最小とは言えない例を持ってきてしまいました。また、UIKit で基本的な実装を行い、状態管理のみを SwiftUI で行うという変な実装になりました。改善点は多いものの、Flutter からでも Swift 独自のライブラリを実行でき、有効活用できることがわかりました。
Flutter にはパッケージが多くあり、基本的な機能の実装はパッケージで事足りることが多いと感じますが、より細かい実装や新しいネイティブのパッケージなどを使うには今回のような実装が必要になるので、担当できる領域を広げる手段として有用かと思います。

特に CoreML あたりでは知見がほとんどないので、誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
https://api.flutter.dev/flutter/services/MethodChannel-class.html

https://docs.flutter.dev/platform-integration/platform-channels

https://github.com/Abhiek187/CoreML-Example

https://developer.apple.com/documentation/vision/classifying_images_with_vision_and_core_ml

https://pixabay.com/ja/