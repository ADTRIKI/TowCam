//
//  CameraService.swift
//  TwoCam
//
//  Created by Adib Triki on 21/09/2025.
//

import Foundation
import AVFoundation

class CameraService: ObservableObject {
    
    // MARK: - Session multi-caméra
    private var multiCamSession = AVCaptureMultiCamSession()
    private var canUseMultiCam = false
    
    // MARK: - Caméras physiques
    private var backWideCamera: AVCaptureDevice?      // Caméra principale
    private var backUltraWideCamera: AVCaptureDevice? // Caméra 0.5x
    
    // MARK: - Session components
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureMovieFileOutput?
    
    init() {
        print("📷 Service caméra initialisé")
        discoverCameras()
        requestPermissions()
        canUseMultiCam = AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    // MARK: - Permissions
    private func requestPermissions() {
        // Demander permission caméra
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                print("📷 Permission caméra: \(granted ? " Accordée" : " Refusée")")
            }
        }
        
        // Demander permission microphone
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                print(" Permission microphone: \(granted ? " Accordée" : " Refusée")")
            }
        }
    }
    
    // MARK: - Découvrir les caméras disponibles
    private func discoverCameras() {
        backWideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        backUltraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        
        print("📷 Caméra principale: \(backWideCamera != nil ? "ok" : "non")")
        print("📷 Caméra ultra-wide: \(backUltraWideCamera != nil ? "ok" : "non")")
    }
    
    // MARK: - Configuration Session
    func setupCameraSession() -> AVCaptureSession? {
        // Utiliser la session multi-cam si possible, sinon session normale
        let session: AVCaptureSession
        
        // Temporairement, utiliser session simple
        session = AVCaptureSession()
        print("📷 Utilisation session simple (multi-cam désactivé)")

        // TODO: Implémenter multi-cam plus tard

        
        // Configuration de base
//        session.beginConfiguration()
//        if session.canSetSessionPreset(.high) {
//            session.sessionPreset = .high
//        } else if session.canSetSessionPreset(.medium) {
//            session.sessionPreset = .medium
//        } else {
//            session.sessionPreset = .low
//        } // choix dla qualité
//        
        // Ajouter les inputs (caméra + micro)
        setupInputs(for: session)
        
        // Ajouter l'output (fichier vidéo)
        setupOutput(for: session)
        
        session.commitConfiguration()
        return session
    }
    
    private func setupInputs(for session: AVCaptureSession) {
        do {
            // Input Vidéo (caméra principale)
            if let camera = backWideCamera {
                videoInput = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                    print("Caméra principale connectée")
                }
            }
            
            // Input Audio (microphone)
            if let microphone = AVCaptureDevice.default(for: .audio) {
                audioInput = try AVCaptureDeviceInput(device: microphone)
                if session.canAddInput(audioInput!) {
                    session.addInput(audioInput!)
                    print("Microphone connecté")
                }
            }
            
        } catch {
            print("Erreur connexion: \(error)")
        }
    }
    
    private func setupOutput(for session: AVCaptureSession) {
        videoOutput = AVCaptureMovieFileOutput()
        
        if session.canAddOutput(videoOutput!) {
            session.addOutput(videoOutput!)
            print("Output vidéo connecté")
        }
    }
}
