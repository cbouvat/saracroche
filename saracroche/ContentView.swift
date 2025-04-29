//
//  ContentView.swift
//  saracroche
//

import CallKit
import SwiftUI

struct ContentView: View {
  @State private var isBlockerEnabled: Bool = false
  @State private var blockerStatusMessage: String = "Vérification du statut..."
  @State private var blockerUpdateStatusMessage: String = ""
  @State private var blocklistVersion: String = "1"
  @State private var statusTimer: Timer? = nil
  @State private var updateTimer: Timer? = nil

  // List of phone number ranges to block
  @State private var blockPhoneNumberRanges: [(start: Int64, end: Int64)] = [
    (33_162_000_000, 33_162_999_999),
    (33_163_000_000, 33_163_999_999),
    (33_270_000_000, 33_270_999_999),
    (33_271_000_000, 33_271_999_999),
    (33_377_000_000, 33_377_999_999),
    (33_378_000_000, 33_378_999_999),
    (33_424_000_000, 33_424_999_999),
    (33_425_000_000, 33_425_999_999),
    (33_568_000_000, 33_568_999_999),
    (33_569_000_000, 33_569_999_999),
    (33_948_000_000, 33_948_999_999),
    (33_947_500_000, 33_947_599_999),
    (33_947_600_000, 33_947_699_999),
    (33_947_700_000, 33_947_799_999),
    (33_947_800_000, 33_947_899_999),
    (33_947_900_000, 33_947_999_999),
  ]

  // List of phone number ranges to inform the user about (not blocked)
  @State private var informPhoneNumberRanges: [(start: Int64, end: Int64)] = [
    (33_937_000_000, 33_937_999_999),
    (33_938_000_000, 33_938_999_999),
    (33_939_000_000, 33_939_999_999),
  ]

  let sharedUserDefaults = UserDefaults(suiteName: "group.com.cbouvat.saracroche")

  var body: some View {
    VStack {
      Text("Saracroche")
        .font(.largeTitle)
        .fontWeight(.heavy)
        .foregroundColor(Color("AccentColor"))
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Statut du bloqueur d'appels")
        .font(.headline)
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack {
        Image(systemName: isBlockerEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
          .foregroundColor(isBlockerEnabled ? .green : .red)
        Text(blockerStatusMessage)
      }
      .padding(.top)
      .frame(maxWidth: .infinity, alignment: .leading)

      if !isBlockerEnabled {
        Button("Activer dans les réglages") {
          openSettings()
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
      } else {
        Text("\(blockerUpdateStatusMessage)")
          .font(.footnote)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical)

        let installedVersion = sharedUserDefaults?.string(forKey: "blocklistVersion") ?? ""
        let updateAvailable = installedVersion != blocklistVersion
        let blockerStatus = sharedUserDefaults?.string(forKey: "blockerStatus") ?? ""

        if blockerStatus == "update" {
          Button("Installation en cours...") {
            // Do nothing, installation is in progress
          }
          .padding()
          .background(Color.orange)
          .foregroundColor(.white)
          .cornerRadius(8)
        } else if blockerStatus == "delete" {
          Button("Suppression en cours...") {
            // Do nothing, deletion is in progress
          }
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(8)
        } else if blockerStatus == "active" {
          if updateAvailable {
            Button("Mettre à jour la liste de blocage") {
              reloadBlockerListExtension()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
          } else {
            Button("Liste de blocage à jour") {
              reloadBlockerListExtension()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
          }

          Button("Supprimer la liste de blocage") {
            removeBlockerList()
          }
          .foregroundColor(.blue)
          .underline()
          .padding()
        } else {
          Button("Installer la liste de blocage") {
            reloadBlockerListExtension()
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
      }

      Text("Liste des préfixes bloqués")
        .font(.headline)
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text(
        "L'application bloque les préfixes suivants, communiqués par l'ARCEP : 0162, 0163, 0270, 0271, 0377, 0378, 0424, 0425, 0568, 0569, 0948, 0949, ainsi que ceux allant de 09475 à 09479. Ces préfixes sont réservés au démarchage téléphonique."
      )
      .font(.footnote)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .onAppear {
      checkBlockerStatus()
      startStatusTimer()
      startUpdateTimer()
    }
    .onDisappear {
      stopStatusTimer()
      stopUpdateTimer()
    }
  }

  private func checkBlockerStatus() {
    let blockerStatus = sharedUserDefaults?.string(forKey: "blockerStatus") ?? ""
    if blockerStatus == "update" { return }
    let manager = CXCallDirectoryManager.sharedInstance

    manager.getEnabledStatusForExtension(withIdentifier: "com.cbouvat.saracroche.blocker") {
      status, error in
      DispatchQueue.main.async {
        if error != nil {
          self.isBlockerEnabled = false
          self.blockerStatusMessage = "Erreur"
          return
        }

        switch status {
        case .enabled:
          self.isBlockerEnabled = true
          self.blockerStatusMessage = "Le bloqueur d'appels est actif"
        case .disabled:
          self.isBlockerEnabled = false
          self.blockerStatusMessage = "Le bloqueur d'appels est désactivé"
        case .unknown:
          self.isBlockerEnabled = false
          self.blockerStatusMessage = "Statut inconnu"
        @unknown default:
          self.isBlockerEnabled = false
          self.blockerStatusMessage = "Statut inattendu"
        }
      }
    }
  }

  private func updateBlockerStatusMessage() {
    let blockedNumbers = sharedUserDefaults?.integer(forKey: "blockedNumbers") ?? 0
    let totalBlockedNumbers = sharedUserDefaults?.integer(forKey: "totalBlockedNumbers") ?? 0
    let blockerStatus = sharedUserDefaults?.string(forKey: "blockerStatus") ?? ""

    if blockerStatus == "active" {
      self.blockerUpdateStatusMessage = "🎉 \(blockedNumbers) numéros bloqués"
    } else if blockerStatus == "update" {
      if blockedNumbers == 0 {
        self.blockerUpdateStatusMessage =
          "Installation de la liste de blocage en cours... Garder l'application ouverte"
      } else {
        let percentage = totalBlockedNumbers > 0 ? (blockedNumbers * 100) / totalBlockedNumbers : 0
        self.blockerUpdateStatusMessage =
          "Installation de la liste de blocage en cours... \(blockedNumbers) numéros bloqués sur \(totalBlockedNumbers) numéros (\(percentage)%). Gardez l'application ouverte"
      }
    } else if blockerStatus == "delete" {
      self.blockerUpdateStatusMessage = "Suppression de la liste de blocage en cours..."
    } else {
      self.blockerUpdateStatusMessage = "Aucun numéro bloqué, installer la liste de blocage"
    }
  }

  private func reloadBlockerListExtension() {
    let totalCount = countAllBlockedNumbers()

    sharedUserDefaults?.set("update", forKey: "blockerStatus")
    sharedUserDefaults?.set(totalCount, forKey: "totalBlockedNumbers")
    sharedUserDefaults?.set(0, forKey: "blockedNumbers")
    sharedUserDefaults?.set(self.blocklistVersion, forKey: "blocklistVersion")

    var rangesToProcess = blockPhoneNumberRanges
    let manager = CXCallDirectoryManager.sharedInstance

    func processNextRange() {
      sharedUserDefaults?.set("addPrefix", forKey: "action")
      if !rangesToProcess.isEmpty {
        let range = rangesToProcess.removeFirst()

        sharedUserDefaults?.set(range.start, forKey: "prefixesStart")
        sharedUserDefaults?.set(range.end, forKey: "prefixesEnd")

        manager.reloadExtension(withIdentifier: "com.cbouvat.saracroche.blocker") { error in
          DispatchQueue.main.async {
            if error != nil {
              self.blockerStatusMessage = "Erreur lors du rechargement"
            }

            processNextRange()
          }
        }
      } else {
        sharedUserDefaults?.set("active", forKey: "blockerStatus")
      }
    }

    sharedUserDefaults?.set("reset", forKey: "action")
    manager.reloadExtension(withIdentifier: "com.cbouvat.saracroche.blocker") { error in
      DispatchQueue.main.async {
        if error != nil {
          self.blockerStatusMessage = "Erreur lors du rechargement"
        }

        processNextRange()
      }
    }
  }

  private func removeBlockerList() {
    sharedUserDefaults?.set("delete", forKey: "blockerStatus")
    sharedUserDefaults?.set(0, forKey: "totalBlockedNumbers")
    sharedUserDefaults?.set(0, forKey: "blockedNumbers")
    sharedUserDefaults?.set("", forKey: "blocklistVersion")

    let manager = CXCallDirectoryManager.sharedInstance

    sharedUserDefaults?.set("reset", forKey: "action")
    manager.reloadExtension(withIdentifier: "com.cbouvat.saracroche.blocker") { error in
      DispatchQueue.main.async {
        if error != nil {
          self.blockerStatusMessage = "Erreur lors de la suppression"
        } else {
          sharedUserDefaults?.set("", forKey: "blockerStatus")
        }
      }
    }
  }

  private func countAllBlockedNumbers() -> Int64 {
    var totalCount: Int64 = 0

    // Compter tous les numéros en utilisant le tableau
    for range in blockPhoneNumberRanges {
      totalCount += (range.end - range.start + 1)
    }

    return totalCount
  }

  private func startStatusTimer() {
    statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      self.checkBlockerStatus()
    }
  }

  private func stopStatusTimer() {
    statusTimer?.invalidate()
    statusTimer = nil
  }

  private func startUpdateTimer() {
    updateTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
      self.updateBlockerStatusMessage()
    }
  }

  private func stopUpdateTimer() {
    updateTimer?.invalidate()
    updateTimer = nil
  }

  private func openSettings() {
    let manager = CXCallDirectoryManager.sharedInstance
    manager.openSettings(completionHandler: { error in
      if let error = error {
        print("Erreur lors de l'ouverture des réglages: \(error.localizedDescription)")
      }
    })
  }
}

#Preview {
  ContentView()
}
