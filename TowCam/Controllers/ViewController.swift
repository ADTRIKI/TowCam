//
//  ViewController.swift
//  TowCam
//
//  Created by Adib Triki on 21/09/2025.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private let cameraModel = CameraModel()
    private let cameraService = CameraService()
    private var cameraSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordingTimer: Timer?
    
    // MARK: - UI Elements
    
    private var recordButton: UIButton!
    private var statusLabel: UILabel!
    private var cameraSwitch: UIButton!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    // MARK: - Camera Configuration
    
    /// Fonction pour configurer la session caméra principale
    private func setupCamera() {
        cameraSession = cameraService.createSession()
        
        guard let session = cameraSession else {
            print("Failed to create camera session")
            return
        }
        
        createVideoPreview()
        previewLayer?.session = session
        
        DispatchQueue.main.async {
            self.previewLayer?.connection?.videoOrientation = .portrait
            print("Preview layer configured")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                print("Camera started successfully")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.debugCameraState()
        }
    }
    
    /// Fonction pour créer la couche de prévisualisation vidéo
    private func createVideoPreview() {
        previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer!, at: 0)
        print("Video preview created")
    }
    
    /// Fonction pour débugger l'état de la caméra
    private func debugCameraState() {
        print("DEBUG Camera State:")
        print("- previewLayer exists: \(previewLayer != nil)")
        print("- session exists: \(cameraSession != nil)")
        print("- session connected to preview: \(previewLayer?.session != nil)")
        print("- session running: \(cameraSession?.isRunning ?? false)")
    }
    
    // MARK: - UI Setup
    
    /// Fonction pour configurer l'interface utilisateur
    private func setupUI() {
        view.backgroundColor = .black
        createRecordButton()
        createStatusLabel()
        createCameraSwitchButton()
        layoutElements()
    }
    
    /// Fonction pour créer le bouton d'enregistrement
    private func createRecordButton() {
        recordButton = UIButton(type: .system)
        recordButton.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        recordButton.layer.cornerRadius = 40
        recordButton.backgroundColor = .white
        recordButton.layer.borderWidth = 4
        recordButton.layer.borderColor = UIColor.red.cgColor
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    /// Fonction pour créer le bouton de changement de caméra
    private func createCameraSwitchButton() {
        cameraSwitch = UIButton(type: .system)
        cameraSwitch.setTitle("1x", for: .normal)
        cameraSwitch.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        cameraSwitch.setTitleColor(.white, for: .normal)
        cameraSwitch.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cameraSwitch.layer.cornerRadius = 25
        cameraSwitch.addTarget(self, action: #selector(switchCameraTapped), for: .touchUpInside)
        view.addSubview(cameraSwitch)
    }
    
    /// Fonction pour créer le label de statut du timer
    private func createStatusLabel() {
        statusLabel = UILabel()
        statusLabel.text = "00:00"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        view.addSubview(statusLabel)
    }
    
    /// Fonction pour positionner les éléments de l'interface
    private func layoutElements() {
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        
        recordButton.center = CGPoint(x: centerX, y: centerY + 200)
        statusLabel.center = CGPoint(x: centerX, y: centerY + 100)
        
        cameraSwitch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraSwitch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cameraSwitch.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cameraSwitch.widthAnchor.constraint(equalToConstant: 50),
            cameraSwitch.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Recording Actions
    
    /// Fonction pour gérer l'appui sur le bouton d'enregistrement
    @objc private func recordButtonTapped() {
        if cameraModel.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    /// Fonction pour démarrer l'enregistrement
    private func startRecording() {
        cameraService.startRecording { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.cameraModel.startRecording()
                    self?.updateUI()
                    print("Recording started: \(message)")
                } else {
                    print("Failed to start recording: \(message)")
                }
            }
        }
    }
    
    /// Fonction pour arrêter l'enregistrement
    private func stopRecording() {
        cameraService.stopRecording { [weak self] success, message, fileURL in
            DispatchQueue.main.async {
                self?.cameraModel.stopRecording()
                self?.updateUI()
                
                if success, let url = fileURL {
                    print("Recording completed: \(message)")
                    print("File saved: \(url.lastPathComponent)")
                } else {
                    print("Failed to stop recording: \(message)")
                }
            }
        }
    }
    
    // MARK: - Camera Controls
    
    /// Fonction pour changer de caméra
    @objc private func switchCameraTapped() {
        print("Camera switch tapped")
        
        cameraService.switchCamera { [weak self] success, newCameraType in
            DispatchQueue.main.async {
                if success {
                    let buttonText = newCameraType == .wide ? "1x" : "0.5x"
                    self?.cameraSwitch.setTitle(buttonText, for: .normal)
                    print("Camera switched to: \(buttonText)")
                } else {
                    print("Failed to switch camera")
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    /// Fonction pour mettre à jour l'interface utilisateur
    private func updateUI() {
        updateButtonAppearance()
        
        if cameraModel.isRecording {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    /// Fonction pour mettre à jour l'apparence du bouton d'enregistrement
    private func updateButtonAppearance() {
        if cameraModel.isRecording {
            recordButton.backgroundColor = .red
            recordButton.layer.borderColor = UIColor.white.cgColor
        } else {
            recordButton.backgroundColor = .white
            recordButton.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    // MARK: - Timer Management
    
    /// Fonction pour démarrer le timer d'enregistrement
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.cameraModel.recordingDuration += 0.1
            self.updateStatusLabel()
        }
    }
    
    /// Fonction pour arrêter le timer d'enregistrement
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    /// Fonction pour mettre à jour le label du timer
    private func updateStatusLabel() {
        let minutes = Int(cameraModel.recordingDuration) / 60
        let seconds = Int(cameraModel.recordingDuration) % 60
        statusLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
}
