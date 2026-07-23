import Flutter
import UIKit
import Vision
import VisionKit

@main
@objc class AppDelegate: FlutterAppDelegate, VNDocumentCameraViewControllerDelegate {
  private var pendingScanResult: FlutterResult?
  private var pendingPageLimit = 1

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "inkdoc/on_device_ai",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "scanDocument":
          let arguments = call.arguments as? [String: Any]
          let batchMode = arguments?["batchMode"] as? Bool ?? false
          let requestedLimit = arguments?["pageLimit"] as? Int ?? 1
          self?.scanDocument(
            pageLimit: batchMode ? min(max(requestedLimit, 2), 10) : 1,
            result: result
          )
        case "getDeviceCapabilities":
          result(self?.deviceCapabilities())
        case "improveText":
          let arguments = call.arguments as? [String: Any]
          let text = arguments?["text"] as? String ?? ""
          result(self?.cleanRecognizedText(text) ?? text)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func deviceCapabilities() -> [String: Any] {
    let bytesPerGb = 1024.0 * 1024.0 * 1024.0
    let values = try? URL(fileURLWithPath: NSHomeDirectory())
      .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    #if targetEnvironment(simulator)
      let isSimulator = true
    #else
      let isSimulator = false
    #endif
    #if arch(arm64)
      let architecture = "arm64"
    #else
      let architecture = "x86_64"
    #endif
    return [
      "platform": "iOS",
      "osVersion": UIDevice.current.systemVersion,
      "totalRamGb": Double(ProcessInfo.processInfo.physicalMemory) / bytesPerGb,
      "freeStorageGb": Double(values?.volumeAvailableCapacityForImportantUsage ?? 0) / bytesPerGb,
      "architecture": architecture,
      "isSimulator": isSimulator,
    ]
  }

  private func scanDocument(pageLimit: Int, result: @escaping FlutterResult) {
    guard pendingScanResult == nil else {
      result(FlutterError(
        code: "SCAN_IN_PROGRESS",
        message: "A document scan is already running.",
        details: nil
      ))
      return
    }

    guard VNDocumentCameraViewController.isSupported else {
      result(FlutterError(
        code: "SCANNER_UNAVAILABLE",
        message: "VisionKit document camera is unavailable on this device.",
        details: nil
      ))
      return
    }

    pendingScanResult = result
    pendingPageLimit = pageLimit

    let scanner = VNDocumentCameraViewController()
    scanner.delegate = self
    window?.rootViewController?.present(scanner, animated: true)
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {
    controller.dismiss(animated: true)

    DispatchQueue.global(qos: .userInitiated).async {
      var pages: [[String: Any?]] = []

      let pageCount = min(scan.pageCount, self.pendingPageLimit)
      for index in 0..<pageCount {
        let image = scan.imageOfPage(at: index)
        let rawText = self.recognizeText(in: image)
        let cleanedText = self.cleanRecognizedText(rawText)
        let confidence = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 0.9

        pages.append([
          "number": index + 1,
          "text": cleanedText,
          "rawText": rawText,
          "imageUri": nil,
          "confidence": confidence,
          "aiEngine": "Vision OCR cleanup; ready for Apple Foundation Models",
          "lowConfidencePhrases": self.lowConfidencePhrases(cleanedText),
        ])
      }

      DispatchQueue.main.async {
        self.pendingScanResult?([
          "engine": "VisionKit Document Camera + Vision text recognition",
          "pdfUri": nil,
          "pages": pages,
        ])
        self.pendingScanResult = nil
        self.pendingPageLimit = 1
      }
    }
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true)
    pendingScanResult?(FlutterError(
      code: "CANCELLED",
      message: "Document scanning was cancelled.",
      details: nil
    ))
    pendingScanResult = nil
    pendingPageLimit = 1
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {
    controller.dismiss(animated: true)
    pendingScanResult?(FlutterError(
      code: "SCANNER_FAILED",
      message: error.localizedDescription,
      details: nil
    ))
    pendingScanResult = nil
    pendingPageLimit = 1
  }

  private func recognizeText(in image: UIImage) -> String {
    guard let cgImage = image.cgImage else {
      return ""
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return ""
    }

    let observations = request.results ?? []
    return observations
      .compactMap { $0.topCandidates(1).first?.string }
      .joined(separator: "\n")
  }

  private func cleanRecognizedText(_ text: String) -> String {
    let normalized = text
      .split(separator: "\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
      .joined(separator: "\n")

    return normalized
      .replacingOccurrences(of: " ,", with: ",")
      .replacingOccurrences(of: " .", with: ".")
      .replacingOccurrences(of: " ?", with: "?")
      .replacingOccurrences(of: " !", with: "!")
  }

  private func lowConfidencePhrases(_ text: String) -> [String] {
    return text
      .split(separator: "\n")
      .map(String.init)
      .filter { !$0.isEmpty && $0.count <= 24 }
      .prefix(3)
      .map { $0 }
  }
}
