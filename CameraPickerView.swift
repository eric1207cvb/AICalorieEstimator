import SwiftUI
import UIKit
import AVFoundation

struct CameraPickerView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let camera = FoodCameraViewController()
            camera.onImageCaptured = { image in
                context.coordinator.finish(with: image)
            }
            camera.onCancel = {
                context.coordinator.cancel()
            }
            return camera
        }

        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: CameraPickerView

        init(parent: CameraPickerView) {
            self.parent = parent
        }

        func finish(with image: UIImage) {
            parent.selectedImage = image.fixOrientation()
            parent.dismiss()
        }

        func cancel() {
            parent.dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                finish(with: image)
            } else {
                cancel()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            cancel()
        }
    }
}

private final class FoodCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImageCaptured: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "tw.yian.AICalorieEstimator.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false

    private let closeButton = UIButton(type: .system)
    private let shutterButton = UIButton(type: .custom)

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePreview()
        configureControls()
        configureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        applyCameraFeedOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let self else { return }
            self.previewLayer?.frame = CGRect(origin: .zero, size: size)
            self.applyCameraFeedOrientation()
        }
    }

    private func configurePreview() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    private func configureControls() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        closeButton.layer.cornerRadius = 22
        closeButton.accessibilityLabel = NSLocalizedString("camera.close", comment: "Close camera")
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)

        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 38
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.38).cgColor
        shutterButton.accessibilityLabel = NSLocalizedString("button.take_photo", comment: "Take Photo")
        shutterButton.isEnabled = false
        shutterButton.alpha = 0.65
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            shutterButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            shutterButton.widthAnchor.constraint(equalToConstant: 76),
            shutterButton.heightAnchor.constraint(equalToConstant: 76)
        ])
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    ?? AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: camera),
                self.session.canAddInput(input),
                self.session.canAddOutput(self.photoOutput)
            else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.onCancel?() }
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)
            self.photoOutput.maxPhotoQualityPrioritization = .balanced
            self.session.commitConfiguration()
            self.isConfigured = true
            self.session.startRunning()

            DispatchQueue.main.async {
                self.applyCameraFeedOrientation()
                self.shutterButton.isEnabled = true
                self.shutterButton.alpha = 1
            }
        }
    }

    private func applyCameraFeedOrientation() {
        applyCameraFeedOrientation(to: previewLayer?.connection)
        applyCameraFeedOrientation(to: photoOutput.connection(with: .video))
    }

    private func applyCameraFeedOrientation(to connection: AVCaptureConnection?) {
        guard let connection else { return }

        let rotationAngle = currentVideoRotationAngle()
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }
    }

    private func currentVideoRotationAngle() -> CGFloat {
        switch currentInterfaceOrientation() {
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return 270
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        default:
            return view.bounds.width > view.bounds.height ? 0 : 90
        }
    }

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch currentInterfaceOrientation() {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return view.bounds.width > view.bounds.height ? .landscapeRight : .portrait
        }
    }

    private func currentInterfaceOrientation() -> UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation ?? .unknown
    }

    @objc private func capturePhoto() {
        guard isConfigured else { return }
        shutterButton.isEnabled = false
        shutterButton.alpha = 0.65
        applyCameraFeedOrientation()

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .balanced
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func closeCamera() {
        onCancel?()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.shutterButton.isEnabled = true
            self.shutterButton.alpha = 1
        }

        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }

        DispatchQueue.main.async {
            self.onImageCaptured?(image)
        }
    }
}

// [Extensions] 修正圖片方向的工具
extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}
