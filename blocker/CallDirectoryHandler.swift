import CallKit
import Foundation

class CallDirectoryHandler: CXCallDirectoryProvider {
  override func beginRequest(with context: CXCallDirectoryExtensionContext) {
    context.delegate = self

    if context.isIncremental {
      incrementalUpdate(to: context)
    } else {
      fullUpdate(to: context)
    }

    context.completeRequest()
  }

  private func sharedUserDefaults() -> UserDefaults? {
    UserDefaults(suiteName: "group.com.cbouvat.saracroche")
  }

  private func incrementalUpdate(
    to context: CXCallDirectoryExtensionContext
  ) {

    let action = sharedUserDefaults()?.string(forKey: "action") ?? ""

    if action == "resetNumbersList" {
      resetNumbersList(to: context)
    } else if action == "addNumbersList" {
      addNumbersList(to: context)
    } else {
      print("Unknown action: \(action)")
    }

    sharedUserDefaults()?.set("", forKey: "action")
  }

  private func fullUpdate(
    to context: CXCallDirectoryExtensionContext
  ) {
    // Add fake number to iOS make sure the extension is working
    context.addBlockingEntry(withNextSequentialPhoneNumber: 1_800_555_5555)
  }

  private func resetNumbersList(
    to context: CXCallDirectoryExtensionContext
  ) {

    print("Resetting all numbers list")
    sharedUserDefaults()?.set(0, forKey: "blockedNumbers")

    context.removeAllBlockingEntries()
    context.removeAllIdentificationEntries()

    print("Successfully reset all numbers list")
  }

  private func addNumbersList(
    to context: CXCallDirectoryExtensionContext
  ) {

    var blockedNumbers = Int64(
      sharedUserDefaults()?.integer(forKey: "blockedNumbers") ?? 0
    )

    let numbersList =
      sharedUserDefaults()?.stringArray(forKey: "numbersList") ?? []

    print(
      "Adding numbers : count \(numbersList.count), first \(numbersList.first ?? "")"
    )

    for number in numbersList {
      let number = Int64("\(number)") ?? 0
      context.addBlockingEntry(withNextSequentialPhoneNumber: number)
      blockedNumbers += 1
    }

    sharedUserDefaults()?.set(blockedNumbers, forKey: "blockedNumbers")
  }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

  func requestFailed(
    for extensionContext: CXCallDirectoryExtensionContext,
    withError error: Error
  ) {
    print("Request failed with error: \(error.localizedDescription)")
  }

}
