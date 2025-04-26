import Foundation
import UIKit
import ARKit
import SwiftUI

// MARK: - Bond Mode Toggle Button
struct BondModeToggleButton: View {
    @Binding var isBondMode: Bool
    var canBond: Bool  // Should be true if molecule.atoms.count >= 2
    @State private var isExpanded: Bool = false

    var body: some View {
        Button(action: {
            if isBondMode {
                // Exit bond mode: shrink back to icon.
                isBondMode.toggle()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = false
                }
            } else {
                // Enter bond mode: expand to show text.
                isBondMode.toggle()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = true
                }
            }
        }) {
            HStack {
                Image(systemName: isBondMode ? "link.circle.fill" : "link.circle")
                    .font(.title2)
                if isExpanded {
                    Text(isBondMode ? "Exit Bond Mode" : "Enter Bond Mode")
                        .font(.subheadline)
                }
            }
            .padding(8)
            .background(isBondMode ? Color.orange : Color.purple)
            .cornerRadius(25)
            .foregroundColor(.white)
        }
        .onChange(of: canBond) { newValue in
            if newValue && !isBondMode {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded = true }
            } else if !newValue && !isBondMode {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded = false }
            }
        }
    }
}

// MARK: - Molecule Builder View

// Define an enum to record actions.
enum BuilderAction {
    case addAtom(Molecule.AtomPlacement)
    case addBond(Bond)
}

struct MoleculeBuilderView: View {
    @EnvironmentObject var library: MoleculeLibrary
    @Environment(\.dismiss) var dismiss
    @State private var currentMolecule = Molecule(name: "New Molecule")
    @State private var feedbackText: String = "Tap atoms to add them to the canvas."
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isBondMode: Bool = false
    @State private var selectedAtomForBond: UUID? = nil
    
    // New action stack to record each addition.
    @State private var actions: [BuilderAction] = []

    var body: some View {
        VStack(spacing: 16) {
            Text(feedbackText)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
                .padding(.top, 16)
            
            // Canvas for atoms and bonds.
            ZStack {
                MoleculeCanvasView(
                    molecule: $currentMolecule,
                    isEditable: true,
                    isBondMode: isBondMode,
                    onAtomTap: { placement in
                        if isBondMode {
                            if let firstSelected = selectedAtomForBond {
                                if firstSelected != placement.id {
                                    let newBond = Bond(fromAtomID: firstSelected, toAtomID: placement.id)
                                    currentMolecule.bonds.append(newBond)
                                    actions.append(.addBond(newBond))
                                    feedbackText = "Bond created between atoms."
                                    selectedAtomForBond = nil
                                }
                            } else {
                                selectedAtomForBond = placement.id
                                feedbackText = "Selected atom for bonding. Tap another atom."
                            }
                        }
                    },
                    selectedAtomID: selectedAtomForBond
                )
                .frame(height: 400)
                .background(Color(white: 0.1))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .overlay(
                    VStack {
                        HStack {
                            // Updated undo button that uses the action stack.
                            Button(action: {
                                if let lastAction = actions.popLast() {
                                    switch lastAction {
                                    case .addAtom(let placement):
                                        if let index = currentMolecule.atoms.firstIndex(where: { $0.id == placement.id }) {
                                            currentMolecule.atoms.remove(at: index)
                                            // Also remove bonds that reference this atom.
                                            currentMolecule.bonds.removeAll {
                                                $0.fromAtomID == placement.id || $0.toAtomID == placement.id
                                            }
                                            feedbackText = "Last atom undone."
                                        }
                                    case .addBond(let bond):
                                        if let index = currentMolecule.bonds.firstIndex(where: { $0.id == bond.id }) {
                                            currentMolecule.bonds.remove(at: index)
                                            feedbackText = "Last bond undone."
                                        }
                                    }
                                } else {
                                    feedbackText = "No actions to undo."
                                }
                            }) {
                                Image(systemName: "arrow.uturn.left")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            // Place the Bond Mode Toggle next to Undo.
                            BondModeToggleButton(
                                isBondMode: $isBondMode,
                                canBond: currentMolecule.atoms.count >= 2
                            )
                            
                            Spacer()
                            
                            Button(action: {
                                currentMolecule = Molecule(name: "New Molecule")
                                actions.removeAll() // Clear the action stack as well.
                                feedbackText = "Canvas cleared."
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                )
            }
            
            // Periodic table view for adding atoms.
            // When an atom is added, we now record the action.
            PeriodicTableView { atom in
                let randomX = CGFloat.random(in: 30...330)
                let randomY = CGFloat.random(in: 80...350)
                let placement = Molecule.AtomPlacement(
                    atom: atom,
                    position: CGPoint(x: randomX, y: randomY)
                )
                currentMolecule.atoms.append(placement)
                actions.append(.addAtom(placement))
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if currentMolecule.atoms.isEmpty {
                        alertMessage = "Please add at least one atom before forming a molecule."
                        showAlert = true
                        return
                    }
                    let generated = currentMolecule.generatedFormula()
                    currentMolecule.formula = generated
                    currentMolecule.name = generated
                    library.customMolecules.append(currentMolecule)
                    feedbackText = "Molecule formed: \(generated)"
                    dismiss()
                }
            }
        }
    }
}


// MARK: - Molecule Canvas and Atom Views

struct MoleculeCanvasView: View {
    @Binding var molecule: Molecule
    var isEditable: Bool
    var isBondMode: Bool = false
    var onAtomTap: ((Molecule.AtomPlacement) -> Void)? = nil
    var selectedAtomID: UUID? = nil

    var body: some View {
        GeometryReader { _ in
            ZStack {
                ForEach(molecule.atoms) { placement in
                    AtomGestureWrapper(
                        molecule: $molecule,
                        placement: placement,
                        isEditable: isEditable,
                        isBondMode: isBondMode,
                        onAtomTap: onAtomTap,
                        selectedAtomID: selectedAtomID
                    )
                }
                ForEach(molecule.bonds) { bond in
                    if let from = molecule.atoms.first(where: { $0.id == bond.fromAtomID }),
                       let to = molecule.atoms.first(where: { $0.id == bond.toAtomID }) {
                        Path { path in
                            path.move(to: from.position)
                            path.addLine(to: to.position)
                        }
                        .stroke(Color.gray, lineWidth: 1)
                    }
                }
            }
            .background(Color.white.opacity(0.05))
        }
    }
}

struct AtomView: View {
    var atom: Atom
    var isSelected: Bool = false

    var body: some View {
        Circle()
            .fill(atom.color)
            .frame(width: atom.radius * 2, height: atom.radius * 2)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.5), lineWidth: isSelected ? 3 : 1)
            )
            .overlay(
                Text(atom.symbol)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

struct AtomGestureWrapper: View {
    @Binding var molecule: Molecule
    let placement: Molecule.AtomPlacement
    let isEditable: Bool
    let isBondMode: Bool
    let onAtomTap: ((Molecule.AtomPlacement) -> Void)?
    let selectedAtomID: UUID?

    var body: some View {
        Group {
            if isBondMode {
                AtomPlacementView(
                    placement: placement,
                    isSelected: placement.id == selectedAtomID
                )
                .onTapGesture { onAtomTap?(placement) }
            } else {
                AtomPlacementView(
                    placement: placement,
                    isSelected: placement.id == selectedAtomID
                )
                .gesture(
                    DragGesture().onChanged { value in
                        if isEditable,
                           let index = molecule.atoms.firstIndex(where: { $0.id == placement.id }) {
                            molecule.atoms[index].position = value.location
                        }
                    }
                )
            }
        }
    }
}

struct AtomPlacementView: View {
    let placement: Molecule.AtomPlacement
    let isSelected: Bool

    var body: some View {
        AtomView(atom: placement.atom, isSelected: isSelected)
            .position(placement.position)
    }
}

// MARK: - Periodic Table & Atom Button

struct PeriodicTableView: View {
    var onAtomTap: (Atom) -> Void

    var body: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            VStack(spacing: 5) {
                ForEach(0..<periodicTableGrid.count, id: \.self) { rowIndex in
                    HStack(spacing: 5) {
                        ForEach(0..<periodicTableGrid[rowIndex].count, id: \.self) { colIndex in
                            if let atom = periodicTableGrid[rowIndex][colIndex] {
                                AtomButtonView(atom: atom, onTap: { onAtomTap(atom) })
                            } else {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
}

struct AtomButtonView: View {
    var atom: Atom
    var onTap: () -> Void

    var body: some View {
        Button(action: { onTap() }) {
            Text(atom.symbol)
                .font(.system(.subheadline, design: .rounded))
                .frame(width: 50, height: 50)
                .background(Circle().fill(atom.color))
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .foregroundColor(.white)
        }
    }
}
