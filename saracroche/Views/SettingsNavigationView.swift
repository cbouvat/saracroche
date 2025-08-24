import SwiftUI

struct SettingsNavigationView: View {
  @ObservedObject var viewModel: BlockerViewModel
  @State private var showDeleteConfirmation = false
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          Button {
            viewModel.openSettings()
          } label: {
            Label(
              "Activer ou désactiver Saracroche dans **Réglages**",
              systemImage: "gearshape.fill"
            )
          }

          Button {
            viewModel.updateBlockerList()
          } label: {
            Label(
              "Recharger la liste de blocage",
              systemImage: "arrow.clockwise.circle.fill"
            )
          }

          Button(role: .destructive) {
            showDeleteConfirmation = true
          } label: {
            Label(
              "Supprimer la liste de blocage",
              systemImage: "trash.fill"
            )
            .foregroundColor(.red)
          }
          .confirmationDialog(
            "Supprimer la liste de blocage",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
          ) {
            Button("Supprimer", role: .destructive) {
              viewModel.removeBlockerList()
            }
          } message: {
            Text("Êtes-vous sûr de vouloir supprimer la liste de blocage ?")
          }
        } header: {
          Text("Configuration")
        }

        Section {
          Button {
            if let url = URL(string: "https://cbouvat.com/saracroche/help/") {
              UIApplication.shared.open(url)
            }
          } label: {
            Label("Aide & FAQ", systemImage: "questionmark.circle.fill")
          }

          Button {
            if let url = URL(string: "https://cbouvat.com/saracroche/privacy/") {
              UIApplication.shared.open(url)
            }
          } label: {
            Label("Confidentialité", systemImage: "lock.shield.fill")
          }

          Button {
            if let url = URL(string: "https://cbouvat.com/saracroche") {
              UIApplication.shared.open(url)
            }
          } label: {
            Label("Site officiel", systemImage: "safari.fill")
          }

          Button {
            if let url = URL(
              string:
                "https://apps.apple.com/app/id6743679292?action=write-review"
            ) {
              UIApplication.shared.open(url)
            }
          } label: {
            Label("Noter l'application", systemImage: "star.fill")
          }

          Button {
            if let url = URL(
              string: "https://github.com/cbouvat/saracroche-ios"
            ) {
              UIApplication.shared.open(url)
            }
          } label: {
            Label(
              "Code source",
              systemImage: "keyboard.fill"
            )
          }
        } header: {
          Text("Liens")
        }

        Section {
          Button {
            if let version = Bundle.main.infoDictionary?[
              "CFBundleShortVersionString"
            ] as? String {
              let deviceModel = UIDevice.current.modelIdentifier
              let systemVersion = UIDevice.current.systemVersion

              let deviceInfo = """
                Appareil : \(deviceModel)
                Version iOS : \(systemVersion)
                Version de l'application : \(version)
                """

              let body = """
                Bonjour,

                (Votre message ici)

                \(deviceInfo)
                """

              let encodedBody =
                body.addingPercentEncoding(
                  withAllowedCharacters: .urlQueryAllowed
                ) ?? ""
              let urlString =
                "mailto:mail@cbouvat.com?subject=Contact%20-%20Saracroche%20iOS&body="
                + encodedBody
              if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
              }
            }
          } label: {
            Label(
              "Signaler un bug ou suggérer une fonctionnalité par e-mail",
              systemImage: "envelope.fill"
            )
          }

          Button {
            if let url = URL(string: "https://mastodon.social/@cbouvat") {
              UIApplication.shared.open(url)
            }
          } label: {
            Label("Mastodon @cbouvat", systemImage: "person.bubble.fill")
          }
        } header: {
          Text("Contact")
        } footer: {
          Text(
            "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
            + "\n\n\nBisou 😘"
          )
          .padding(.vertical)
          .frame(maxWidth: .infinity)
          .multilineTextAlignment(.center)
        }
      }
      .navigationTitle("Réglages")
    }
  }
}

#Preview {
  SettingsNavigationView(
    viewModel: BlockerViewModel()
  )
}
