import SwiftUI
import SceneKit
import ARKit
import CoreGraphics

// MARK: - Models

struct Atom: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let color: Color
    let radius: CGFloat
    
    static func == (lhs: Atom, rhs: Atom) -> Bool {
        return lhs.symbol == rhs.symbol && lhs.radius == rhs.radius
    }
}

extension Atom: Codable {
    enum CodingKeys: CodingKey {
        case symbol, radius, color
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(radius, forKey: .radius)
        let colorString: String
        if color == Color.white { colorString = "white" }
        else if color == Color.black { colorString = "black" }
        else if color == Color.red { colorString = "red" }
        else if color == Color.blue { colorString = "blue" }
        else if color == Color.green { colorString = "green" }
        else if color == Color.purple { colorString = "purple" }
        else { colorString = "gray" }
        try container.encode(colorString, forKey: .color)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        radius = try container.decode(CGFloat.self, forKey: .radius)
        let colorString = try container.decode(String.self, forKey: .color)
        switch colorString {
        case "white": color = .white
        case "black": color = .black
        case "red": color = .red
        case "blue": color = .blue
        case "green": color = .green
        case "purple": color = .purple
        default: color = .gray
        }
    }
}

struct Bond: Identifiable, Codable, Equatable {
    var id = UUID()
    let fromAtomID: UUID
    let toAtomID: UUID
}

struct Molecule: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var formula: String = ""
    var atoms: [AtomPlacement] = []
    var bonds: [Bond] = []
    
    struct AtomPlacement: Identifiable, Codable, Equatable {
        var id = UUID()
        let atom: Atom
        var position: CGPoint
    }
    
    static func == (lhs: Molecule, rhs: Molecule) -> Bool {
        return lhs.name == rhs.name &&
               lhs.formula == rhs.formula &&
               lhs.atoms == rhs.atoms &&
               lhs.bonds == rhs.bonds
    }
}

// MARK: - Dynamic Formula Generation

extension Molecule {
    func subscriptNumber(_ num: Int) -> String {
        let subscripts = ["0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"]
        return String(num).compactMap { subscripts[String($0)] }.joined()
    }
    
    func generatedFormula() -> String {
        var counts: [String: Int] = [:]
        for placement in atoms {
            counts[placement.atom.symbol, default: 0] += 1
        }
        
        let orderedElements: [String]
        if counts.keys.contains("C") {
            let others = counts.keys.filter { $0 != "C" && $0 != "H" }.sorted()
            orderedElements = counts.keys.contains("H") ? ["C", "H"] + others : ["C"] + others
        } else {
            orderedElements = counts.keys.sorted()
        }
        
        var formula = ""
        for element in orderedElements {
            if let count = counts[element] {
                formula += element
                if count > 1 {
                    formula += subscriptNumber(count)
                }
            }
        }
        return formula
    }
}

struct MoleculeDefinition {
    let name: String
    let formula: String
    let composition: [String: Int]
}

// MARK: - Realistic Periodic Table Colors & Layout

let alkaliMetals: Set<String> = ["Li", "Na", "K", "Rb", "Cs", "Fr"]
let alkalineEarth: Set<String> = ["Be", "Mg", "Ca", "Sr", "Ba", "Ra"]
let lanthanides: Set<String> = ["La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu"]
let actinides: Set<String> = ["Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", "Md", "No", "Lr"]
let transitionMetals: Set<String> = [
    "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn",
    "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd",
    "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg",
    "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn"
]
let postTransition: Set<String> = ["Al", "Ga", "In", "Tl", "Sn", "Pb", "Bi", "Nh", "Fl", "Mc"]
let metalloids: Set<String> = ["B", "Si", "Ge", "As", "Sb", "Te", "Po"]
let nonmetals: Set<String> = ["C", "N", "O", "P", "S", "Se"]
let halogens: Set<String> = ["F", "Cl", "Br", "I", "At"]
let nobleGases: Set<String> = ["He", "Ne", "Ar", "Kr", "Xe", "Rn", "Og"]

func realLifeColor(for element: String) -> Color {
    if element == "H" { return Color.gray }
    if nobleGases.contains(element) { return Color.gray }
    if alkaliMetals.contains(element) { return Color.red.opacity(0.7) }
    if alkalineEarth.contains(element) { return Color.green }
    if lanthanides.contains(element) { return Color.purple }
    if actinides.contains(element) { return Color.pink }
    if transitionMetals.contains(element) { return Color.gray }
    if postTransition.contains(element) { return Color.orange }
    if metalloids.contains(element) { return Color.yellow }
    if nonmetals.contains(element) {
        switch element {
        case "C": return Color.black
        case "N": return Color.blue
        case "O": return Color.red
        case "P": return Color.orange
        case "S": return Color.yellow
        case "Se": return Color.green
        default: return Color.gray
        }
    }
    if halogens.contains(element) { return Color.green }
    return Color.gray
}

let periodicTableGrid: [[Atom?]] = [
    // Period 1
    [ Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10) ] +
    Array(repeating: nil, count: 16) +
    [ Atom(symbol: "He", color: realLifeColor(for: "He"), radius: 10) ],
    
    // Period 2
    [ Atom(symbol: "Li", color: realLifeColor(for: "Li"), radius: 10),
      Atom(symbol: "Be", color: realLifeColor(for: "Be"), radius: 10) ] +
    Array(repeating: nil, count: 10) +
    [ Atom(symbol: "B", color: realLifeColor(for: "B"), radius: 10),
      Atom(symbol: "C", color: realLifeColor(for: "C"), radius: 10),
      Atom(symbol: "N", color: realLifeColor(for: "N"), radius: 10),
      Atom(symbol: "O", color: realLifeColor(for: "O"), radius: 10),
      Atom(symbol: "F", color: realLifeColor(for: "F"), radius: 10),
      Atom(symbol: "Ne", color: realLifeColor(for: "Ne"), radius: 10) ],
    
    // Period 3
    [ Atom(symbol: "Na", color: realLifeColor(for: "Na"), radius: 10),
      Atom(symbol: "Mg", color: realLifeColor(for: "Mg"), radius: 10) ] +
    Array(repeating: nil, count: 10) +
    [ Atom(symbol: "Al", color: realLifeColor(for: "Al"), radius: 10),
      Atom(symbol: "Si", color: realLifeColor(for: "Si"), radius: 10),
      Atom(symbol: "P", color: realLifeColor(for: "P"), radius: 10),
      Atom(symbol: "S", color: realLifeColor(for: "S"), radius: 10),
      Atom(symbol: "Cl", color: realLifeColor(for: "Cl"), radius: 10),
      Atom(symbol: "Ar", color: realLifeColor(for: "Ar"), radius: 10) ],
    
    // Period 4
    [ Atom(symbol: "K", color: realLifeColor(for: "K"), radius: 10),
      Atom(symbol: "Ca", color: realLifeColor(for: "Ca"), radius: 10),
      Atom(symbol: "Sc", color: realLifeColor(for: "Sc"), radius: 10),
      Atom(symbol: "Ti", color: realLifeColor(for: "Ti"), radius: 10),
      Atom(symbol: "V", color: realLifeColor(for: "V"), radius: 10),
      Atom(symbol: "Cr", color: realLifeColor(for: "Cr"), radius: 10),
      Atom(symbol: "Mn", color: realLifeColor(for: "Mn"), radius: 10),
      Atom(symbol: "Fe", color: realLifeColor(for: "Fe"), radius: 10),
      Atom(symbol: "Co", color: realLifeColor(for: "Co"), radius: 10),
      Atom(symbol: "Ni", color: realLifeColor(for: "Ni"), radius: 10),
      Atom(symbol: "Cu", color: realLifeColor(for: "Cu"), radius: 10),
      Atom(symbol: "Zn", color: realLifeColor(for: "Zn"), radius: 10),
      Atom(symbol: "Ga", color: realLifeColor(for: "Ga"), radius: 10),
      Atom(symbol: "Ge", color: realLifeColor(for: "Ge"), radius: 10),
      Atom(symbol: "As", color: realLifeColor(for: "As"), radius: 10),
      Atom(symbol: "Se", color: realLifeColor(for: "Se"), radius: 10),
      Atom(symbol: "Br", color: realLifeColor(for: "Br"), radius: 10),
      Atom(symbol: "Kr", color: realLifeColor(for: "Kr"), radius: 10) ],
    
    // Period 5
    [ Atom(symbol: "Rb", color: realLifeColor(for: "Rb"), radius: 10),
      Atom(symbol: "Sr", color: realLifeColor(for: "Sr"), radius: 10),
      Atom(symbol: "Y", color: realLifeColor(for: "Y"), radius: 10),
      Atom(symbol: "Zr", color: realLifeColor(for: "Zr"), radius: 10),
      Atom(symbol: "Nb", color: realLifeColor(for: "Nb"), radius: 10),
      Atom(symbol: "Mo", color: realLifeColor(for: "Mo"), radius: 10),
      Atom(symbol: "Tc", color: realLifeColor(for: "Tc"), radius: 10),
      Atom(symbol: "Ru", color: realLifeColor(for: "Ru"), radius: 10),
      Atom(symbol: "Rh", color: realLifeColor(for: "Rh"), radius: 10),
      Atom(symbol: "Pd", color: realLifeColor(for: "Pd"), radius: 10),
      Atom(symbol: "Ag", color: realLifeColor(for: "Ag"), radius: 10),
      Atom(symbol: "Cd", color: realLifeColor(for: "Cd"), radius: 10),
      Atom(symbol: "In", color: realLifeColor(for: "In"), radius: 10),
      Atom(symbol: "Sn", color: realLifeColor(for: "Sn"), radius: 10),
      Atom(symbol: "Sb", color: realLifeColor(for: "Sb"), radius: 10),
      Atom(symbol: "Te", color: realLifeColor(for: "Te"), radius: 10),
      Atom(symbol: "I", color: realLifeColor(for: "I"), radius: 10),
      Atom(symbol: "Xe", color: realLifeColor(for: "Xe"), radius: 10) ],
    
    // Period 6 (main block); note gap at group 3.
    [ Atom(symbol: "Cs", color: realLifeColor(for: "Cs"), radius: 10),
      Atom(symbol: "Ba", color: realLifeColor(for: "Ba"), radius: 10),
      nil,
      Atom(symbol: "Hf", color: realLifeColor(for: "Hf"), radius: 10),
      Atom(symbol: "Ta", color: realLifeColor(for: "Ta"), radius: 10),
      Atom(symbol: "W", color: realLifeColor(for: "W"), radius: 10),
      Atom(symbol: "Re", color: realLifeColor(for: "Re"), radius: 10),
      Atom(symbol: "Os", color: realLifeColor(for: "Os"), radius: 10),
      Atom(symbol: "Ir", color: realLifeColor(for: "Ir"), radius: 10),
      Atom(symbol: "Pt", color: realLifeColor(for: "Pt"), radius: 10),
      Atom(symbol: "Au", color: realLifeColor(for: "Au"), radius: 10),
      Atom(symbol: "Hg", color: realLifeColor(for: "Hg"), radius: 10),
      Atom(symbol: "Tl", color: realLifeColor(for: "Tl"), radius: 10),
      Atom(symbol: "Pb", color: realLifeColor(for: "Pb"), radius: 10),
      Atom(symbol: "Bi", color: realLifeColor(for: "Bi"), radius: 10),
      Atom(symbol: "Po", color: realLifeColor(for: "Po"), radius: 10),
      Atom(symbol: "At", color: realLifeColor(for: "At"), radius: 10),
      Atom(symbol: "Rn", color: realLifeColor(for: "Rn"), radius: 10) ],
    
    // Period 7 (main block); gap at group 3.
    [ Atom(symbol: "Fr", color: realLifeColor(for: "Fr"), radius: 10),
      Atom(symbol: "Ra", color: realLifeColor(for: "Ra"), radius: 10),
      nil,
      Atom(symbol: "Rf", color: realLifeColor(for: "Rf"), radius: 10),
      Atom(symbol: "Db", color: realLifeColor(for: "Db"), radius: 10),
      Atom(symbol: "Sg", color: realLifeColor(for: "Sg"), radius: 10),
      Atom(symbol: "Bh", color: realLifeColor(for: "Bh"), radius: 10),
      Atom(symbol: "Hs", color: realLifeColor(for: "Hs"), radius: 10),
      Atom(symbol: "Mt", color: realLifeColor(for: "Mt"), radius: 10),
      Atom(symbol: "Ds", color: realLifeColor(for: "Ds"), radius: 10),
      Atom(symbol: "Rg", color: realLifeColor(for: "Rg"), radius: 10),
      Atom(symbol: "Cn", color: realLifeColor(for: "Cn"), radius: 10),
      Atom(symbol: "Nh", color: realLifeColor(for: "Nh"), radius: 10),
      Atom(symbol: "Fl", color: realLifeColor(for: "Fl"), radius: 10),
      Atom(symbol: "Mc", color: realLifeColor(for: "Mc"), radius: 10),
      Atom(symbol: "Lv", color: realLifeColor(for: "Lv"), radius: 10),
      Atom(symbol: "Ts", color: realLifeColor(for: "Ts"), radius: 10),
      Atom(symbol: "Og", color: realLifeColor(for: "Og"), radius: 10) ],
    
    // Lanthanides row:
    Array(repeating: nil, count: 2) +
    [ Atom(symbol: "La", color: realLifeColor(for: "La"), radius: 10),
      Atom(symbol: "Ce", color: realLifeColor(for: "Ce"), radius: 10),
      Atom(symbol: "Pr", color: realLifeColor(for: "Pr"), radius: 10),
      Atom(symbol: "Nd", color: realLifeColor(for: "Nd"), radius: 10),
      Atom(symbol: "Pm", color: realLifeColor(for: "Pm"), radius: 10),
      Atom(symbol: "Sm", color: realLifeColor(for: "Sm"), radius: 10),
      Atom(symbol: "Eu", color: realLifeColor(for: "Eu"), radius: 10),
      Atom(symbol: "Gd", color: realLifeColor(for: "Gd"), radius: 10),
      Atom(symbol: "Tb", color: realLifeColor(for: "Tb"), radius: 10),
      Atom(symbol: "Dy", color: realLifeColor(for: "Dy"), radius: 10),
      Atom(symbol: "Ho", color: realLifeColor(for: "Ho"), radius: 10),
      Atom(symbol: "Er", color: realLifeColor(for: "Er"), radius: 10),
      Atom(symbol: "Tm", color: realLifeColor(for: "Tm"), radius: 10),
      Atom(symbol: "Yb", color: realLifeColor(for: "Yb"), radius: 10),
      Atom(symbol: "Lu", color: realLifeColor(for: "Lu"), radius: 10)
    ] + [ nil ],
    
    // Actinides row:
    Array(repeating: nil, count: 2) +
    [ Atom(symbol: "Ac", color: realLifeColor(for: "Ac"), radius: 10),
      Atom(symbol: "Th", color: realLifeColor(for: "Th"), radius: 10),
      Atom(symbol: "Pa", color: realLifeColor(for: "Pa"), radius: 10),
      Atom(symbol: "U", color: realLifeColor(for: "U"), radius: 10),
      Atom(symbol: "Np", color: realLifeColor(for: "Np"), radius: 10),
      Atom(symbol: "Pu", color: realLifeColor(for: "Pu"), radius: 10),
      Atom(symbol: "Am", color: realLifeColor(for: "Am"), radius: 10),
      Atom(symbol: "Cm", color: realLifeColor(for: "Cm"), radius: 10),
      Atom(symbol: "Bk", color: realLifeColor(for: "Bk"), radius: 10),
      Atom(symbol: "Cf", color: realLifeColor(for: "Cf"), radius: 10),
      Atom(symbol: "Es", color: realLifeColor(for: "Es"), radius: 10),
      Atom(symbol: "Fm", color: realLifeColor(for: "Fm"), radius: 10),
      Atom(symbol: "Md", color: realLifeColor(for: "Md"), radius: 10),
      Atom(symbol: "No", color: realLifeColor(for: "No"), radius: 10),
      Atom(symbol: "Lr", color: realLifeColor(for: "Lr"), radius: 10)
    ] + [ nil ]
]

// MARK: - Data Persistence

class MoleculeLibrary: ObservableObject {
    @Published var customMolecules: [Molecule] = [] {
        didSet { saveData() }
    }
    
    private let key = "customMolecules"
    
    init() {
        loadData()
        // If no molecules were loaded, add default molecules.
        if customMolecules.isEmpty {
            customMolecules = MoleculeLibrary.defaultMolecules
        }
    }
    
    func saveData() {
        if let data = try? JSONEncoder().encode(customMolecules) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: key),
           let molecules = try? JSONDecoder().decode([Molecule].self, from: data) {
            self.customMolecules = molecules
        }
    }
    
    // Default molecules: Water, Carbon Dioxide, Methane, Ammonia, and Hydrogen Chloride.
    static let defaultMolecules: [Molecule] = [
        {
            var water = Molecule(name: "Water", formula: "H₂O")
            let oxygen = Molecule.AtomPlacement(
                atom: Atom(symbol: "O", color: realLifeColor(for: "O"), radius: 10),
                position: CGPoint(x: 150, y: 150)
            )
            let hydrogen1 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 100, y: 200)
            )
            let hydrogen2 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 200, y: 200)
            )
            water.atoms = [oxygen, hydrogen1, hydrogen2]
            water.bonds = [
                Bond(fromAtomID: oxygen.id, toAtomID: hydrogen1.id),
                Bond(fromAtomID: oxygen.id, toAtomID: hydrogen2.id)
            ]
            return water
        }(),
        {
            var co2 = Molecule(name: "Carbon Dioxide", formula: "CO₂")
            let carbon = Molecule.AtomPlacement(
                atom: Atom(symbol: "C", color: realLifeColor(for: "C"), radius: 10),
                position: CGPoint(x: 150, y: 150)
            )
            let oxygen1 = Molecule.AtomPlacement(
                atom: Atom(symbol: "O", color: realLifeColor(for: "O"), radius: 10),
                position: CGPoint(x: 100, y: 150)
            )
            let oxygen2 = Molecule.AtomPlacement(
                atom: Atom(symbol: "O", color: realLifeColor(for: "O"), radius: 10),
                position: CGPoint(x: 200, y: 150)
            )
            co2.atoms = [carbon, oxygen1, oxygen2]
            co2.bonds = [
                Bond(fromAtomID: carbon.id, toAtomID: oxygen1.id),
                Bond(fromAtomID: carbon.id, toAtomID: oxygen2.id)
            ]
            return co2
        }(),
        {
            var methane = Molecule(name: "Methane", formula: "CH₄")
            let carbon = Molecule.AtomPlacement(
                atom: Atom(symbol: "C", color: realLifeColor(for: "C"), radius: 10),
                position: CGPoint(x: 150, y: 150)
            )
            let hydrogen1 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 150, y: 100)
            )
            let hydrogen2 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 150, y: 200)
            )
            let hydrogen3 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 100, y: 150)
            )
            let hydrogen4 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 200, y: 150)
            )
            methane.atoms = [carbon, hydrogen1, hydrogen2, hydrogen3, hydrogen4]
            methane.bonds = [
                Bond(fromAtomID: carbon.id, toAtomID: hydrogen1.id),
                Bond(fromAtomID: carbon.id, toAtomID: hydrogen2.id),
                Bond(fromAtomID: carbon.id, toAtomID: hydrogen3.id),
                Bond(fromAtomID: carbon.id, toAtomID: hydrogen4.id)
            ]
            return methane
        }(),
        {
            var ammonia = Molecule(name: "Ammonia", formula: "NH₃")
            let nitrogen = Molecule.AtomPlacement(
                atom: Atom(symbol: "N", color: realLifeColor(for: "N"), radius: 10),
                position: CGPoint(x: 150, y: 150)
            )
            let hydrogen1 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 150, y: 100)
            )
            let hydrogen2 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 120, y: 180)
            )
            let hydrogen3 = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 180, y: 180)
            )
            ammonia.atoms = [nitrogen, hydrogen1, hydrogen2, hydrogen3]
            ammonia.bonds = [
                Bond(fromAtomID: nitrogen.id, toAtomID: hydrogen1.id),
                Bond(fromAtomID: nitrogen.id, toAtomID: hydrogen2.id),
                Bond(fromAtomID: nitrogen.id, toAtomID: hydrogen3.id)
            ]
            return ammonia
        }(),
        {
            var hcl = Molecule(name: "Hydrogen Chloride", formula: "HCl")
            let hydrogen = Molecule.AtomPlacement(
                atom: Atom(symbol: "H", color: realLifeColor(for: "H"), radius: 10),
                position: CGPoint(x: 130, y: 150)
            )
            let chlorine = Molecule.AtomPlacement(
                atom: Atom(symbol: "Cl", color: realLifeColor(for: "Cl"), radius: 10),
                position: CGPoint(x: 170, y: 150)
            )
            hcl.atoms = [hydrogen, chlorine]
            hcl.bonds = [
                Bond(fromAtomID: hydrogen.id, toAtomID: chlorine.id)
            ]
            return hcl
        }()
    ]
}

// MARK: - Helper Functions for Realistic 3D Models

func colorFor(element: String) -> UIColor {
    switch element {
    case "H": return .gray
    case "C": return .black
    case "O": return .red
    case "N": return .blue
    case "Cl": return .green
    case "F": return .purple
    default: return .gray
    }
}

func radiusFor(element: String) -> CGFloat {
    switch element {
    case "H": return 0.03
    case "C": return 0.05
    case "O": return 0.05
    case "N": return 0.05
    case "Cl": return 0.06
    case "F": return 0.04
    default: return 0.05
    }
}

func createAtomNode(element: String, position: SCNVector3) -> SCNNode {
    let sphere = SCNSphere(radius: radiusFor(element: element) * 1.5)
    sphere.firstMaterial?.diffuse.contents = colorFor(element: element)
    let node = SCNNode(geometry: sphere)
    node.position = position
    return node
}

func createBondNode(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
    let vector = end - start
    let distance = vector.length()
    let cylinder = SCNCylinder(radius: 0.008, height: CGFloat(distance))
    cylinder.firstMaterial?.diffuse.contents = UIColor.gray
    let bondNode = SCNNode(geometry: cylinder)
    bondNode.position = (start + end) / 2
    let up = SCNVector3(0, 1, 0)
    let axis = up.cross(vector).normalized()
    let angle = acos(up.dot(vector.normalized()))
    bondNode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
    return bondNode
}

func buildMoleculeNode(centerAtom: (element: String, position: SCNVector3),
                         substituents: [(element: String, position: SCNVector3)]) -> SCNNode {
    let node = SCNNode()
    let center = createAtomNode(element: centerAtom.element, position: centerAtom.position)
    node.addChildNode(center)
    for sub in substituents {
        let subNode = createAtomNode(element: sub.element, position: sub.position)
        node.addChildNode(subNode)
        node.addChildNode(createBondNode(from: centerAtom.position, to: sub.position))
    }
    return node
}

let realisticMoleculeGeometries: [String: (center: (element: String, position: SCNVector3),
                                              substituents: [(element: String, position: SCNVector3)])] = {
    let waterBondLength: Float = 0.15
    let waterAngle = (104.5 / 2.0) * Float.pi / 180.0
    let waterX = waterBondLength * sin(waterAngle)
    let waterY = waterBondLength * cos(waterAngle)
    
    let co2Distance: Float = 0.15
    let methaneDistance: Float = 0.15
    func tetrahedralPositions(distance: Float) -> [SCNVector3] {
        let vectors = [
            SCNVector3(1,1,1),
            SCNVector3(-1,-1,1),
            SCNVector3(-1,1,-1),
            SCNVector3(1,-1,-1)
        ]
        return vectors.map { $0.normalized() * distance }
    }
    
    let ammoniaDistance: Float = 0.15
    let ammoniaPositions: [SCNVector3] = [
        SCNVector3(ammoniaDistance, 0, 0),
        SCNVector3(-ammoniaDistance * 0.5, ammoniaDistance * 0.87, 0),
        SCNVector3(-ammoniaDistance * 0.5, -ammoniaDistance * 0.87, 0)
    ]
    
    let hclDistance: Float = 0.15
    let fmDistance: Float = 0.15
    let fmTetra = tetrahedralPositions(distance: fmDistance)
    
    return [
        "Water": (center: ("O", SCNVector3(0,0,0)),
                  substituents: [("H", SCNVector3(-waterX, waterY, 0)),
                                  ("H", SCNVector3(waterX, waterY, 0))]),
        "Carbon Dioxide": (center: ("C", SCNVector3(0,0,0)),
                           substituents: [("O", SCNVector3(-co2Distance,0,0)),
                                          ("O", SCNVector3(co2Distance,0,0))]),
        "Methane": (center: ("C", SCNVector3(0,0,0)),
                    substituents: tetrahedralPositions(distance: methaneDistance).map { ("H", $0) }),
        "Ammonia": (center: ("N", SCNVector3(0,0,0)),
                    substituents: ammoniaPositions.map { ("H", $0) }),
        "Hydrogen Chloride": (center: ("H", SCNVector3(0,0,0)),
                              substituents: [("Cl", SCNVector3(hclDistance, 0, 0))]),
        "Fluoromethane": (center: ("C", SCNVector3(0,0,0)),
                          substituents: [("F", fmTetra.first!)] + fmTetra.dropFirst().map { ("H", $0) })
    ]
}()

func generateVSEPRPositions(count: Int, distance: Float) -> [SCNVector3] {
    var positions: [SCNVector3] = []
    switch count {
    case 1:
        positions.append(SCNVector3(distance, 0, 0))
    case 2:
        positions.append(SCNVector3(distance, 0, 0))
        positions.append(SCNVector3(-distance, 0, 0))
    case 3:
        for i in 0..<3 {
            let angle = Float(i) * (2 * Float.pi / 3)
            positions.append(SCNVector3(distance * cos(angle), distance * sin(angle), 0))
        }
    case 4:
        positions = [
            SCNVector3(1, 1, 1).normalized() * distance,
            SCNVector3(1, -1, -1).normalized() * distance,
            SCNVector3(-1, 1, -1).normalized() * distance,
            SCNVector3(-1, -1, 1).normalized() * distance,
        ]
    case 5:
        positions.append(SCNVector3(0, distance, 0))
        positions.append(SCNVector3(0, -distance, 0))
        for i in 0..<3 {
            let angle = Float(i) * (2 * Float.pi / 3)
            positions.append(SCNVector3(distance * cos(angle), 0, distance * sin(angle)))
        }
    case 6:
        positions = [
            SCNVector3(distance, 0, 0),
            SCNVector3(-distance, 0, 0),
            SCNVector3(0, distance, 0),
            SCNVector3(0, -distance, 0),
            SCNVector3(0, 0, distance),
            SCNVector3(0, 0, -distance)
        ]
    default:
        for i in 0..<count {
            let angle = Float(i) * (2 * Float.pi / Float(count))
            positions.append(SCNVector3(distance * cos(angle), distance * sin(angle), 0))
        }
    }
    return positions
}

func createVSEPRMoleculeNode(for molecule: Molecule) -> SCNNode {
    var bondCountForAtom: [UUID: Int] = [:]
    for placement in molecule.atoms {
        bondCountForAtom[placement.id] = 0
    }
    for bond in molecule.bonds {
        bondCountForAtom[bond.fromAtomID, default: 0] += 1
        bondCountForAtom[bond.toAtomID, default: 0] += 1
    }
    if let centralID = bondCountForAtom.max(by: { $0.value < $1.value })?.key,
       let centralPlacement = molecule.atoms.first(where: { $0.id == centralID }) {
        let substituentBonds = molecule.bonds.filter { $0.fromAtomID == centralID || $0.toAtomID == centralID }
        let substituentCount = substituentBonds.count
        let distance: Float = 0.15
        let positions = generateVSEPRPositions(count: substituentCount, distance: distance)
        
        let node = SCNNode()
        let centralNode = createAtomNode(element: centralPlacement.atom.symbol, position: SCNVector3(0, 0, 0))
        node.addChildNode(centralNode)
        
        var usedIndex = 0
        for bond in substituentBonds {
            var substituentID: UUID?
            if bond.fromAtomID == centralID {
                substituentID = bond.toAtomID
            } else {
                substituentID = bond.fromAtomID
            }
            if let subPlacement = molecule.atoms.first(where: { $0.id == substituentID }),
               usedIndex < positions.count {
                let pos = positions[usedIndex]
                let subNode = createAtomNode(element: subPlacement.atom.symbol, position: pos)
                node.addChildNode(subNode)
                let bondNode = createBondNode(from: SCNVector3(0, 0, 0), to: pos)
                node.addChildNode(bondNode)
                usedIndex += 1
            }
        }
        return node
    }
    return createGenericMoleculeNode(from: molecule)
}

func createRealisticMoleculeNode(for molecule: Molecule) -> SCNNode {
    if let geometry = realisticMoleculeGeometries[molecule.name] {
        return buildMoleculeNode(centerAtom: geometry.center, substituents: geometry.substituents)
    }
    var bondCountForAtom: [UUID: Int] = [:]
    for placement in molecule.atoms {
        bondCountForAtom[placement.id] = 0
    }
    for bond in molecule.bonds {
        bondCountForAtom[bond.fromAtomID, default: 0] += 1
        bondCountForAtom[bond.toAtomID, default: 0] += 1
    }
    if let maxBondCount = bondCountForAtom.values.max() {
        let centralAtoms = bondCountForAtom.filter { $0.value == maxBondCount }
        if centralAtoms.count == 1 {
            return createVSEPRMoleculeNode(for: molecule)
        }
    }
    return createGenericMoleculeNode(from: molecule)
}

func createGenericMoleculeNode(from molecule: Molecule) -> SCNNode {
    let node = SCNNode()
    let scaleFactor: Float = 0.002
    var atomNodes: [UUID: SCNNode] = [:]
    for placement in molecule.atoms {
        let sphere = SCNSphere(radius: CGFloat(Float(placement.atom.radius) * scaleFactor))
        sphere.firstMaterial?.diffuse.contents = UIColor(placement.atom.color)
        let atomNode = SCNNode(geometry: sphere)
        let x = Float(placement.position.x - 150) * scaleFactor
        let y = Float(placement.position.y - 150) * scaleFactor
        atomNode.position = SCNVector3(x, y, 0)
        node.addChildNode(atomNode)
        atomNodes[placement.id] = atomNode
    }
    for bond in molecule.bonds {
        if let fromPlacement = molecule.atoms.first(where: { $0.id == bond.fromAtomID }),
           let toPlacement = molecule.atoms.first(where: { $0.id == bond.toAtomID }) {
            let x1 = Float(fromPlacement.position.x - 150) * scaleFactor
            let y1 = Float(fromPlacement.position.y - 150) * scaleFactor
            let start = SCNVector3(x1, y1, 0)
            let x2 = Float(toPlacement.position.x - 150) * scaleFactor
            let y2 = Float(toPlacement.position.y - 150) * scaleFactor
            let end = SCNVector3(x2, y2, 0)
            let bondNode = createBondNode(from: start, to: end)
            node.addChildNode(bondNode)
        }
    }
    return node
}

// MARK: - SCNVector3 Math Extensions

extension SCNVector3 {
    func length() -> Float { sqrt(x*x + y*y + z*z) }
    func normalized() -> SCNVector3 {
        let len = length()
        return len == 0 ? self : self / len
    }
    func dot(_ v: SCNVector3) -> Float { x * v.x + y * v.y + z * v.z }
    func cross(_ v: SCNVector3) -> SCNVector3 {
        SCNVector3(
            y * v.z - z * v.y,
            z * v.x - x * v.z,
            x * v.y - y * v.x
        )
    }
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x+rhs.x, lhs.y+rhs.y, lhs.z+rhs.z)
    }
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x-rhs.x, lhs.y-rhs.y, lhs.z-rhs.z)
    }
    static func /(vector: SCNVector3, scalar: Float) -> SCNVector3 {
        SCNVector3(vector.x/scalar, vector.y/scalar, vector.z/scalar)
    }
    static func *(vector: SCNVector3, scalar: Float) -> SCNVector3 {
        SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Welcome to DopeChem!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding()
                Text("Build your own molecules and experience realistic AR models with a minimalist design. In Bond Mode, tap two atoms to connect them.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                Button(action: {
                    isPresented = false
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                }
            }
            .padding()
        }
    }
}

// MARK: - ContentView (Main Screen)

struct ContentView: View {
    var body: some View {
        NavigationView {
            MoleculeLibraryView()
        }
        .accentColor(.purple)
    }
}
