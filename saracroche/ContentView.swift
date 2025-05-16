//
//  ContentView.swift
//  saracroche
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = SaracrocheViewModel()

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
        Image(
          systemName: viewModel.isBlockerEnabled ? "checkmark.circle.fill" : "xmark.circle.fill"
        )
        .foregroundColor(viewModel.isBlockerEnabled ? .green : .red)
        Text(viewModel.blockerStatusMessage)
      }
      .padding(.top)
      .frame(maxWidth: .infinity, alignment: .leading)

      if !viewModel.isBlockerEnabled {
        Button("Activer dans les réglages") {
          viewModel.openSettings()
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
      } else {
        Text("\(viewModel.blockerUpdateStatusMessage)")
          .font(.footnote)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical)

        if viewModel.blockerStatus == "update" {
          Button("Installation en cours...") {
            // Do nothing, installation is in progress
          }
          .padding()
          .background(Color.orange)
          .foregroundColor(.white)
          .cornerRadius(8)
        } else if viewModel.blockerStatus == "delete" {
          Button("Suppression en cours...") {
            // Do nothing, deletion is in progress
          }
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(8)
        } else if viewModel.blockerStatus == "active" {
          if viewModel.isUpdateAvailable {
            Button("Mettre à jour la liste de blocage") {
              viewModel.reloadBlockerListExtension()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
          } else {
            Button("Liste de blocage à jour") {
              viewModel.reloadBlockerListExtension()
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
            viewModel.reloadBlockerListExtension()
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
  }
}

#Preview {
  ContentView()
}
