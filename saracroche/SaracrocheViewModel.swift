import CallKit
import Combine
import SwiftUI

enum BlockerExtensionStatus {
  case enabled
  case disabled
  case error
  case unexpected
  case unknown
}

enum BlockerActionState {
  case update
  case delete
  case finish
  case nothing
}

class SaracrocheViewModel: ObservableObject {
  @Published var blockerExtensionStatus: BlockerExtensionStatus = .unknown
  @Published var blockerActionState: BlockerActionState = .nothing
  @Published var blockerPhoneNumberBlocked: Int64 = 0
  @Published var blockerPhoneNumberTotal: Int64 = 0
  @Published var blocklistInstalledVersion: String = ""
  @Published var blocklistVersion: String = "2.0"
  @Published var showBlockerStatusSheet: Bool = false

  private var statusTimer: Timer? = nil
  private var updateTimer: Timer? = nil

  // List of phone number patterns to block
  let blockPhoneNumberPatterns: [String] = [
    "33162XXXXXX",
    "33163XXXXXX",
    "33270XXXXXX",
    "33271XXXXXX",
    "33377XXXXXX",
    "33378XXXXXX",
    "33424XXXXXX",
    "33425XXXXXX",
    "33568XXXXXX",
    "33569XXXXXX",
    "33948XXXXXX",
    "339475XXXXX",
    "339476XXXXX",
    "339477XXXXX",
    "339478XXXXX",
    "339479XXXXX",
  ]

  // List of phone number patterns to inform the user about (not blocked)
  let informPhoneNumberPatterns: [String] = [
    "33937XXXXXX",
    "33938XXXXXX",
    "33939XXXXXX",
  ]

  let sharedUserDefaults = UserDefaults(
    suiteName: "group.com.cbouvat.saracroche"
  )

  init() {
    checkBlockerExtensionStatus()
    startTimerBlockerExtensionStatus()
    startUpdateTimer()
  }

  deinit {
    stopStatusBlockerExtensionStatus()
    stopUpdateTimer()
  }

  func checkBlockerExtensionStatus() {
    let manager = CXCallDirectoryManager.sharedInstance

    manager.getEnabledStatusForExtension(
      withIdentifier: "com.cbouvat.saracroche.blocker"
    ) {
      status,
      error in
      DispatchQueue.main.async {
        if error != nil {
          self.blockerExtensionStatus = .error
          return
        }

        switch status {
        case .enabled:
          self.blockerExtensionStatus = .enabled
        case .disabled:
          self.blockerExtensionStatus = .disabled
        case .unknown:
          self.blockerExtensionStatus = .unknown
        @unknown default:
          self.blockerExtensionStatus = .unexpected
        }
      }
    }
  }

  func updateBlockerState() {
    let blockerActionState =
      sharedUserDefaults?.string(forKey: "blockerActionState") ?? ""
    let blockedNumbers =
      sharedUserDefaults?.integer(forKey: "blockedNumbers") ?? 0
    let totalBlockedNumbers =
      sharedUserDefaults?.integer(forKey: "totalBlockedNumbers") ?? 0
    let blocklistInstalledVersion =
      sharedUserDefaults?.string(forKey: "blocklistVersion") ?? ""

    if blockerActionState == "update" {
      self.blockerActionState = .update
    } else if blockerActionState == "delete" {
      self.blockerActionState = .delete
    } else if blockerActionState == "finish" {
      self.blockerActionState = .finish
    } else {
      self.blockerActionState = .nothing
    }

    self.blockerPhoneNumberBlocked = Int64(blockedNumbers)
    self.blockerPhoneNumberTotal = Int64(totalBlockedNumbers)
    self.blocklistInstalledVersion = blocklistInstalledVersion

    if self.blockerActionState == .update || self.blockerActionState == .delete
      || self.blockerActionState == .finish
    {
      self.showBlockerStatusSheet = true
    } else {
      self.showBlockerStatusSheet = false
    }
  }

  func updateBlockerList() {
    sharedUserDefaults?.set("update", forKey: "blockerActionState")
    sharedUserDefaults?.set(
      countAllBlockedNumbers(),
      forKey: "totalBlockedNumbers"
    )
    sharedUserDefaults?.set(0, forKey: "blockedNumbers")
    sharedUserDefaults?.set(self.blocklistVersion, forKey: "blocklistVersion")

    var patternsToProcess = blockPhoneNumberPatterns
    let manager = CXCallDirectoryManager.sharedInstance

    func processNextPattern() {
      if sharedUserDefaults?.string(forKey: "blockerActionState") != "update" {
        return
      }
      sharedUserDefaults?.set("addPrefix", forKey: "action")
      if !patternsToProcess.isEmpty {
        let pattern = patternsToProcess.removeFirst()

        sharedUserDefaults?.set(pattern, forKey: "phonePattern")

        manager.reloadExtension(
          withIdentifier: "com.cbouvat.saracroche.blocker"
        ) { error in
          DispatchQueue.main.async {
            if error != nil {
              self.blockerExtensionStatus = .error
            }

            processNextPattern()
          }
        }
      } else {
        sharedUserDefaults?.set("finish", forKey: "blockerActionState")
      }
    }

    sharedUserDefaults?.set("reset", forKey: "action")
    manager.reloadExtension(withIdentifier: "com.cbouvat.saracroche.blocker") {
      error in
      DispatchQueue.main.async {
        if error != nil {
          self.blockerExtensionStatus = .error
        }

        processNextPattern()
      }
    }
  }

  func cancelUpdateBlockerAction() {
    sharedUserDefaults?.set("", forKey: "blockerActionState")
    updateBlockerState()
  }

  func removeBlockerList() {
    sharedUserDefaults?.set("delete", forKey: "blockerActionState")
    sharedUserDefaults?.set(0, forKey: "blockedNumbers")

    let manager = CXCallDirectoryManager.sharedInstance

    sharedUserDefaults?.set("reset", forKey: "action")
    manager.reloadExtension(withIdentifier: "com.cbouvat.saracroche.blocker") {
      error in
      DispatchQueue.main.async {
        if error != nil {
          self.blockerExtensionStatus = .error
        }
        self.sharedUserDefaults?.set("", forKey: "blockerActionState")
      }
    }
  }

  func cancelRemoveBlockerAction() {
    sharedUserDefaults?.set("", forKey: "blockerActionState")
    updateBlockerState()
  }

  func markBlockerActionFinished() {
    sharedUserDefaults?.set("", forKey: "blockerActionState")
    updateBlockerState()
  }

  func openSettings() {
    let manager = CXCallDirectoryManager.sharedInstance
    manager.openSettings(completionHandler: { error in
      if let error = error {
        print(
          "Erreur lors de l'ouverture des réglages: \(error.localizedDescription)"
        )
      }
    })
  }

  private func countAllBlockedNumbers() -> Int64 {
    var totalCount: Int64 = 0

    // Count all numbers using the patterns
    for pattern in blockPhoneNumberPatterns {
      let xCount = pattern.filter { $0 == "X" }.count
      totalCount += Int64(pow(10, Double(xCount)))
    }

    return totalCount
  }

  private func startTimerBlockerExtensionStatus() {
    statusTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {
      [weak self] _ in
      self?.checkBlockerExtensionStatus()
    }
  }

  private func stopStatusBlockerExtensionStatus() {
    statusTimer?.invalidate()
    statusTimer = nil
  }

  private func startUpdateTimer() {
    updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) {
      [weak self] _ in
      self?.updateBlockerState()
    }
  }

  private func stopUpdateTimer() {
    updateTimer?.invalidate()
    updateTimer = nil
  }
}
