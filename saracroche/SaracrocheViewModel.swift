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
  @Published var blocklistVersion: String = "3.0"
  @Published var showBlockerStatusSheet: Bool = false

  private var statusTimer: Timer? = nil
  private var updateTimer: Timer? = nil

  // List of phone number patterns to block
  let blockPhoneNumberPatterns: [String] = [
    // ARCEP
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

    // DVS Connect : DVSC
    "3316224XXXX",
    "33162497XXX",
    "33162498XXX",
    "33162499XXX",
    "33162525XXX",
    "33186706XXX",
    "3318844XXXX",
    "33188441XXX",
    "33188442XXX",
    "33188443XXX",
    "33188444XXX",
    "33188445XXX",
    "33188446XXX",
    "33188447XXX",
    "33188448XXX",
    "33188449XXX",
    "33189366XXX",
    "3325959XXXX",
    "33259591XXX",
    "33259592XXX",
    "33259593XXX",
    "33259594XXX",
    "33259595XXX",
    "33259596XXX",
    "33259597XXX",
    "33259598XXX",
    "33259599XXX",
    "3327023XXXX",
    "33270252XXX",
    "33270253XXX",
    "33270254XXX",
    "3337647XXXX",
    "33376471XXX",
    "33376472XXX",
    "33376473XXX",
    "33376474XXX",
    "33376475XXX",
    "33376476XXX",
    "33376477XXX",
    "33376478XXX",
    "33376479XXX",
    "3337723XXXX",
    "33377252XXX",
    "33377253XXX",
    "33377254XXX",
    "3342423XXXX",
    "33424431XXX",
    "33424432XXX",
    "33424433XXX",
    "3345163XXXX",
    "33451631XXX",
    "33451632XXX",
    "33451633XXX",
    "33451634XXX",
    "33451635XXX",
    "33451636XXX",
    "33451637XXX",
    "33451638XXX",
    "33451639XXX",
    "3353716XXXX",
    "33537161XXX",
    "33537162XXX",
    "33537163XXX",
    "33537164XXX",
    "33537165XXX",
    "33537166XXX",
    "33537167XXX",
    "33537168XXX",
    "33537169XXX",
    "3356823XXXX",
    "33568431XXX",
    "33568432XXX",
    "33568433XXX",
    "33939401XXX",
    "3394808XXXX",
    "33948081XXX",
    "33948082XXX",
    "33948083XXX",
    "3394820XXXX",
    "33948455XXX",
    "33974071XXX",
    "3397472XXXX",
    "33974721XXX",
    "33974722XXX",
    "33974723XXX",
    "33974724XXX",
    "33974725XXX",
    "33974726XXX",
    "33974727XXX",
    "33974728XXX",
    "33974729XXX",
    "33987282XXX",
    "33987283XXX",
    "33987284XXX",
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
    UIApplication.shared.isIdleTimerDisabled = true
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
        UIApplication.shared.isIdleTimerDisabled = false
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
    UIApplication.shared.isIdleTimerDisabled = false
    sharedUserDefaults?.set("", forKey: "blockerActionState")
    updateBlockerState()
  }

  func removeBlockerList() {
    UIApplication.shared.isIdleTimerDisabled = true
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
        UIApplication.shared.isIdleTimerDisabled = false
      }
    }
  }

  func cancelRemoveBlockerAction() {
    UIApplication.shared.isIdleTimerDisabled = false
    sharedUserDefaults?.set("", forKey: "blockerActionState")
    updateBlockerState()
  }

  func markBlockerActionFinished() {
    UIApplication.shared.isIdleTimerDisabled = false
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
