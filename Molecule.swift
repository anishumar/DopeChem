import Foundation
import UIKit
import ARKit
import SwiftUI

// MARK: - Molecule Library View & Edit Molecule View

struct MoleculeLibraryView: View {
    @EnvironmentObject var library: MoleculeLibrary
    @State private var isEditing = false
    @State private var selectedMoleculeIndex: Int? = nil
    @State private var showBuilder = false

    var body: some View {
        ZStack {
            List {
                ForEach(library.customMolecules.indices, id: \.self) { index in
                    let molecule = library.customMolecules[index]
                    NavigationLink(destination: ARContainerView(molecule: molecule)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(molecule.name)
                                .font(.headline)
                                .foregroundColor(.purple)
                            Text(molecule.formula)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(4)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            selectedMoleculeIndex = index
                            isEditing = true
                        }
                        .tint(.purple)
                        Button("Delete", role: .destructive) {
                            library.customMolecules.remove(at: index)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Molecules")
            
            // Floating plus button to add a new molecule.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showBuilder = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.purple)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showBuilder) {
            NavigationView {
                MoleculeBuilderView()
                    .navigationTitle("Build Molecule")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showBuilder = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let index = selectedMoleculeIndex {
                EditMoleculeView(molecule: $library.customMolecules[index])
            }
        }
    }
}

struct EditMoleculeView: View {
    @Binding var molecule: Molecule
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Molecule Details")) {
                    TextField("Name", text: $molecule.name)
                    TextField("Formula", text: $molecule.formula)
                }
            }
            .navigationTitle("Edit Molecule")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
