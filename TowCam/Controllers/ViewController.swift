//
//  ViewController.swift
//  TowCam
//
//  Created by Adib Triki on 21/09/2025.
//

import UIKit
import AVFoundation



class ViewController: UIViewController {
    
    //prop
    private let cameraModel = CameraModel()
    private let cameraService = CameraService()
    
    //interface
    private var recordButton: UIButton!
    private var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupCamera()
        setupUI()
            
    }
    //config
    private func setupCamera() {
        // Créer la session caméra
        cameraSession = cameraService.setupCameraSession()
        
        // Connecter la session à la preview
        if let session = cameraSession {
            previewLayer?.session = session
            
            // Démarrer la preview
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
                DispatchQueue.main.async {
                    print("📷 Preview démarrée !")
                }
            }
        }
    }

    
    private func setupUI() {
        view.backgroundColor = .black
        
        createVideoPreview()
        
        createRecordButton()
        
        createStatusLabel()
        
        layoutElements()
        
    }
        
        private func createRecordButton() {
            recordButton = UIButton(type: .system)
            
            // Apparence du bouton
            recordButton.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            recordButton.layer.cornerRadius = 40
            recordButton.backgroundColor = .white
            recordButton.layer.borderWidth = 4
            recordButton.layer.borderColor = UIColor.red.cgColor
            
            // Action quand on appuie
            recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
            
            // Ajouter à l'écran
            view.addSubview(recordButton)
        }
    
    
    //Action
    @objc private func recordButtonTapped() {
        if cameraModel.isRecording {
            stopRecording()
        }else {
            startRecording()
        }
    }
    
    private func startRecording() {
        cameraModel.startRecording()
        startTimer()
        updateButtonAppearance()
        print("🎬 Interface: Enregistrement démarré")
    }
    
    private func stopRecording (){
        cameraModel.stopRecording()
        stopTimer()
        updateButtonAppearance()
        print("Enregistrement arreter")
    }
    
    private func updateButtonAppearance() {
        if cameraModel.isRecording {
            // Mode enregistrement : bouton rouge
            recordButton.backgroundColor = .red
            recordButton.layer.borderColor = UIColor.white.cgColor
        } else {
            // Mode arrêt : bouton blanc
            recordButton.backgroundColor = .white
            recordButton.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    private func createStatusLabel() {
        statusLabel = UILabel()
        
        // Texte et style
        statusLabel.text = "00:00"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        statusLabel.textAlignment = .center
        
        // Taille et position temporaire
        statusLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        
        // Ajouter à l'écran
        view.addSubview(statusLabel)
    }
    
    private func layoutElements() {
        // Centre de l'écran
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        
        // Bouton en bas au centre
        recordButton.center = CGPoint(x: centerX, y: centerY + 200)
        
        // Label au-dessus du bouton
        statusLabel.center = CGPoint(x: centerX, y: centerY + 100)
    }
    
    // MARK: - Timer
    private var recordingTimer: Timer?
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.cameraModel.recordingDuration += 0.1
            self.updateStatusLabel()
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func updateStatusLabel() {
        let minutes = Int(cameraModel.recordingDuration) / 60
        let seconds = Int(cameraModel.recordingDuration) % 60
        statusLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private func createVideoPreview() {
        // Créer la couche de preview
        previewLayer = AVCaptureVideoPreviewLayer()
        
        // Taille plein écran
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        
        // Ajouter en arrière-plan (sous les boutons)
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        print("🎥 Preview vidéo créée")
    }
    
    // MARK: - Session caméra
    private var cameraSession: AVCaptureSession?









}

