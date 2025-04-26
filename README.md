**DopeChem**  
_A Feb '25 Swift Student Challenge Submission_

[![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13%2B-brightgreen.svg)](https://developer.apple.com/ios)
[![ARKit](https://img.shields.io/badge/ARKit-Yes-blue.svg)](https://developer.apple.com/arkit)

---

## 🚀 About
DopeChem is an immersive iOS application that brings molecules to life using Augmented Reality. Designed as part of the Apple Swift Student Challenge (Feb 2025), DopeChem allows users to **build**, **visualize**, and **share** interactive 3D molecular models, making chemistry learning fun and hands-on.

## ✨ Features  
- **AR-Powered Molecule Builder**: Create custom molecules atom by atom in your real environment using Apple ARKit and SwiftUI.
- **Real-Time Visualization**: Rotate, zoom, and explore 3D models from every angle.
- **Share Models**: Export your creations as `.usdz` files or share via AirDrop, Messages, and social media.
- **Intuitive UI**: Smooth drag-and-drop atom placement, pinch-to-scale, and easy reset.

## 🎥 Demo
![DopeChem Demo](./assets/demo.gif)  
*Designing a benzene ring in AR with DopeChem.*

## 🛠 Built With  
- **SwiftUI** — Declarative UI framework  
- **ARKit** — Apple’s framework for AR experiences  
- **SceneKit** — 3D graphics rendering  

## 🏗 Getting Started

### Prerequisites
- Xcode 14 or later  
- iOS 13.0+ device (ARKit-compatible)  

### Installation
1. Clone the repo:  
   ```bash
   [git clone https://github.com/yourusername/DopeChem.git](https://github.com/anishumar/DopeChem.git)
   ```
2. Open the project in Xcode:  
   ```bash
   cd DopeChem
   open DopeChem.xcodeproj
   ```
3. Select your device or simulator, then hit **Run** (⌘R).

## 📚 Usage
1. Launch DopeChem on your ARKit-compatible device.  
2. Point the camera at a flat surface to initialize the AR session.  
3. Tap the **+** button to add atoms; drag to position each atom.  
4. Connect atoms by dragging from one atom to another.  
5. Pinch to scale, rotate the model with two fingers, and reset with the **⟲** button.  
6. Share or export your molecular model using the **Share** icon.

## 🤝 Contributing
Contributions are welcome! Please open an issue or submit a pull request to:
1. Fork the repository.  
2. Create a new branch (`git checkout -b feature/YourFeature`).  
3. Commit your changes (`git commit -m 'Add some feature'`).  
4. Push to the branch (`git push origin feature/YourFeature`).  
5. Open a pull request.

## 📜 License
This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgements
- Apple Swift Student Challenge 2025  
- ARKit and SceneKit documentation  
- [SwiftUI Lab](https://swiftui-lab.com/) tutorials

