import Foundation
import UIKit
import ARKit
import SwiftUI

// MARK: - AR Container & Detail Views, ShareSheet
struct ARContainerView: View {
    var molecule: Molecule
    @State private var isSharing = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARMoleculeDetailView(molecule: molecule)
                .edgesIgnoringSafeArea(.all)
            Button(action: {
                isSharing = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .padding()
            }
            .sheet(isPresented: $isSharing) {
                ShareSheet(activityItems: ["Check out this molecule: \(molecule.name) (\(molecule.formula))"])
            }
        }
    }
}

struct ARMoleculeDetailView: UIViewRepresentable {
    var molecule: Molecule

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        arView.automaticallyUpdatesLighting = true

        let scene = SCNScene()
        let moleculeNode = createRealisticMoleculeNode(for: molecule)
        moleculeNode.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi / 8, z: 0, duration: 2)
        ))
        moleculeNode.position = SCNVector3(0, 0, -0.5)
        scene.rootNode.addChildNode(moleculeNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 1.5)
        scene.rootNode.addChildNode(cameraNode)

        arView.scene = scene
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No update needed.
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
