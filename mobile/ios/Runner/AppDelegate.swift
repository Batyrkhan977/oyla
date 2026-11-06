import Flutter
import UIKit
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var reminderChannel: FlutterMethodChannel?
  private var handwritingChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "oyla/reminders",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let arguments = call.arguments as? [String: Any]
      switch call.method {
      case "schedule":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
          DispatchQueue.main.async { result(granted ? nil : FlutterError(code: "notification_denied", message: "Notifications disabled", details: nil)) }
        }
      case "scheduleActivities":
        ReminderScheduler.shared.schedule(arguments?["items"] as? [[String: Any]] ?? [], result: result)
      case "pendingActions":
        result(UserDefaults.standard.array(forKey: "oyla.activity.actions") ?? [])
      case "acknowledge":
        let id = arguments?["id"] as? String
        let queue = UserDefaults.standard.array(forKey: "oyla.activity.actions") as? [[String: Any]] ?? []
        UserDefaults.standard.set(queue.filter { $0["eventId"] as? String != id }, forKey: "oyla.activity.actions")
        result(nil)
      case "skipToday": result(nil)
      case "cancel":
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    reminderChannel = channel

    let handwriting = FlutterMethodChannel(
      name: "oyla/handwriting",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    handwriting.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      HandwritingRecognizer.recognize(arguments: call.arguments, result: result)
    }
    handwritingChannel = handwriting
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    ReminderScheduler.shared.log(notification.request.content.userInfo, type: "REMINDER_SENT")
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let item = response.notification.request.content.userInfo
    ReminderScheduler.shared.log(item, type: "REMINDER_OPENED")
    if ["STARTED", "POSTPONED", "SKIPPED"].contains(response.actionIdentifier) {
      ReminderScheduler.shared.log(item, type: response.actionIdentifier)
    }
    if response.actionIdentifier == "POSTPONED" {
      let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
      center.add(UNNotificationRequest(identifier: response.notification.request.identifier + ".later", content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)))
    }
    completionHandler()
  }
}

private enum HandwritingRecognizer {
  private static let imageSize = CGSize(width: 800, height: 400)
  private static let inset: CGFloat = 40

  static func recognize(arguments: Any?, result: @escaping FlutterResult) {
    guard
      let arguments = arguments as? [String: Any],
      let strokes = arguments["strokes"] as? [[[String: NSNumber]]],
      !strokes.isEmpty
    else {
      result(FlutterError(
        code: "invalid_strokes",
        message: "No handwriting was provided.",
        details: nil
      ))
      return
    }

    let renderer = UIGraphicsImageRenderer(size: imageSize)
    let image = renderer.image { context in
      UIColor.white.setFill()
      context.fill(CGRect(origin: .zero, size: imageSize))
      let drawing = context.cgContext
      drawing.setStrokeColor(UIColor.black.cgColor)
      drawing.setLineWidth(28)
      drawing.setLineCap(.round)
      drawing.setLineJoin(.round)

      for stroke in strokes where !stroke.isEmpty {
        guard let first = point(from: stroke[0]) else { continue }
        drawing.beginPath()
        drawing.move(to: first)
        for rawPoint in stroke.dropFirst() {
          if let next = point(from: rawPoint) {
            drawing.addLine(to: next)
          }
        }
        if stroke.count == 1 {
          drawing.addLine(to: CGPoint(x: first.x + 1, y: first.y + 1))
        }
        drawing.strokePath()
      }
    }

    guard let cgImage = image.cgImage else {
      result(FlutterError(
        code: "image_error",
        message: "The handwriting image could not be created.",
        details: nil
      ))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNRecognizeTextRequest { request, error in
        if let error {
          finish(result, error: error)
          return
        }
        let observations = (request.results as? [VNRecognizedTextObservation] ?? [])
          .sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        let recognized = observations.compactMap { observation in
          observation.topCandidates(5)
            .map { $0.string.filter(\.isNumber) }
            .first { !$0.isEmpty }
        }.joined()
        DispatchQueue.main.async {
          result(recognized.isEmpty ? nil : recognized)
        }
      }
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["en-US"]
      request.usesLanguageCorrection = false
      do {
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
      } catch {
        finish(result, error: error)
      }
    }
  }

  private static func point(from raw: [String: NSNumber]) -> CGPoint? {
    guard let x = raw["x"]?.doubleValue, let y = raw["y"]?.doubleValue else {
      return nil
    }
    let drawingWidth = imageSize.width - inset * 2
    let drawingHeight = imageSize.height - inset * 2
    return CGPoint(
      x: inset + CGFloat(x.clamped(to: 0...1)) * drawingWidth,
      y: inset + CGFloat(y.clamped(to: 0...1)) * drawingHeight
    )
  }

  private static func finish(_ result: @escaping FlutterResult, error: Error) {
    DispatchQueue.main.async {
      result(FlutterError(
        code: "recognition_error",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }
}

private extension Double {
  func clamped(to range: ClosedRange<Double>) -> Double {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

private final class ReminderScheduler {
  static let shared = ReminderScheduler()
  func log(_ item: [AnyHashable: Any], type: String) {
    guard let id = item["id"] as? String, let owner = item["owner"] as? String else { return }
    var queue = UserDefaults.standard.array(forKey: "oyla.activity.actions") as? [[String: Any]] ?? []
    queue.append(["eventId": UUID().uuidString, "id": id, "owner": owner, "type": type,
      "at": Int(Date().timeIntervalSince1970 * 1000)])
    UserDefaults.standard.set(queue, forKey: "oyla.activity.actions")
  }
  func schedule(_ items: [[String: Any]], result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
    let group = DispatchGroup()
    for item in items.prefix(60) {
      guard let id = item["id"] as? String, let title = item["title"] as? String,
        let timestamp = item["at"] as? NSNumber else { continue }
      let language = item["language"] as? String ?? "english"
      func label(_ en: String, _ kk: String, _ ru: String) -> String { language == "kazakh" ? kk : language == "russian" ? ru : en }
      let category = "OYLA_ACTIVITY." + language
      let actions = [UNNotificationAction(identifier: "STARTED", title: label("Start", "Бастау", "Начать"), options: .foreground),
        UNNotificationAction(identifier: "POSTPONED", title: label("30 minutes later", "30 минуттан кейін", "Через 30 минут")),
        UNNotificationAction(identifier: "SKIPPED", title: label("Skip", "Өткізу", "Пропустить"))]
      center.setNotificationCategories([UNNotificationCategory(identifier: category, actions: actions, intentIdentifiers: [])])
      let content = UNMutableNotificationContent()
      content.title = "Oyla"; content.body = title; content.sound = .default
      content.categoryIdentifier = category; content.userInfo = item
      let date = Date(timeIntervalSince1970: timestamp.doubleValue / 1000)
      if date <= Date() { continue }
      let components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: date)
      group.enter()
      center.add(UNNotificationRequest(identifier: "oyla.activity." + id, content: content,
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))) { _ in group.leave() }
    }
    group.notify(queue: .main) { result(nil) }
  }
}
