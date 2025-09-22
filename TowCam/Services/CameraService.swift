//
//  CameraService.swift
//  TwoCam
//
//  Created by Adib Triki on 21/09/2025.
//

import Foundation
import AVFoundation

class CameraService: ObservableObject {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureMovieFileOutput?
    
    // MARK: - Camera devices
    private var backWideCamera: AVCaptureDevice?
    private var backUltraWideCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    
    // MARK: - Current camera type
    enum CameraType {
        case wide      // 1x
        case ultraWide // 0.5x
    }
    private var currentCameraType: CameraType = .wide
    
    init() {
        print("📷 CameraService: Initialisation")
        setupCameras()
        requestPermissions()
    }
    
    // MARK: - Setup
    private func setupCameras() {
        backWideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        backUltraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        
        // Commencer avec la caméra principale
        currentCamera = backWideCamera
        
        print("📷 Caméra 1x: \(backWideCamera != nil ? "✅" : "❌")")
        print("📷 Caméra 0.5x: \(backUltraWideCamera != nil ? "✅" : "❌")")
    }
    
    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            print("📷 Permission caméra: \(granted ? "✅" : "❌")")
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("🎤 Permission microphone: \(granted ? "✅" : "❌")")
        }
    }
    
    // MARK: - Session Management
    func createSession() -> AVCaptureSession? {
        // Créer une session standard
        captureSession = AVCaptureSession()
        
        guard let session = captureSession else {
            print("❌ Impossible de créer la session")
            return nil
        }
        
        // Configuration
        session.beginConfiguration()
        
        // Ajouter les inputs (caméra + micro)
        guard setupInputs(for: session) else {
            print("❌ Échec configuration inputs")
            session.commitConfiguration()
            return nil
        }
        
        // Ajouter l'output (enregistrement)
        setupOutput(for: session)
        
        // Valider la configuration
        session.commitConfiguration()
        
        print("✅ Session créée avec succès")
        return session
    }

    private func setupInputs(for session: AVCaptureSession) -> Bool {
        do {
            // Input vidéo (caméra courante)
            if let camera = currentCamera {
                videoInput = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                    print("📷 Caméra connectée: \(currentCameraType == .wide ? "1x" : "0.5x")")
                } else {
                    print("❌ Impossible d'ajouter l'input vidéo")
                    return false
                }
            }
            
            // Input audio (microphone)
            if let microphone = AVCaptureDevice.default(for: .audio) {
                audioInput = try AVCaptureDeviceInput(device: microphone)
                if session.canAddInput(audioInput!) {
                    session.addInput(audioInput!)
                    print("🎤 Microphone connecté")
                }
            }
            
            return true
            
        } catch {
            print("❌ Erreur inputs: \(error)")
            return false
        }
    }

    private func setupOutput(for session: AVCaptureSession) {
        videoOutput = AVCaptureMovieFileOutput()
        
        if let output = videoOutput, session.canAddOutput(output) {
            session.addOutput(output)
            print("💾 Output configuré")
        }
    }
    
    // MARK: - Camera Switching
    func switchCamera(completion: @escaping (Bool, CameraType) -> Void) {
        guard let session = captureSession else {
            completion(false, currentCameraType)
            return
        }
        
        // Déterminer la nouvelle caméra
        let newCameraType: CameraType = currentCameraType == .wide ? .ultraWide : .wide
        let newCamera: AVCaptureDevice?
        
        switch newCameraType {
        case .wide:
            newCamera = backWideCamera
        case .ultraWide:
            newCamera = backUltraWideCamera
        }
        
        guard let camera = newCamera else {
            print("❌ Caméra non disponible: \(newCameraType)")
            completion(false, currentCameraType)
            return
        }
        
        // Changer la caméra
        session.beginConfiguration()
        
        // Retirer l'ancien input
        if let oldInput = videoInput {
            session.removeInput(oldInput)
        }
        
        // Ajouter le nouveau input
        do {
            videoInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoInput!) {
                session.addInput(videoInput!)
                currentCamera = camera
                currentCameraType = newCameraType
                session.commitConfiguration()
                
                print("✅ Switch vers: \(newCameraType == .wide ? "1x" : "0.5x")")
                completion(true, newCameraType)
            } else {
                session.commitConfiguration()
                completion(false, currentCameraType)
            }
        } catch {
            session.commitConfiguration()
            print("❌ Erreur switch: \(error)")
            completion(false, currentCameraType)
        }
    }


}
