//
//  CameraService.swift
//  TwoCam
//
//  Created by Adib Triki on 21/09/2025.
//

import Foundation
import AVFoundation
import Photos

class CameraService: NSObject, ObservableObject {
    
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
    
    // MARK: - Recording Management
    private var outputURL: URL?
    private var isRecording = false
    private var stopRecordingCompletion: ((Bool, String, URL?) -> Void)?
    
    override init() {
        super.init()
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
    
    func startRecording(completion: @escaping (Bool, String) -> Void) {
        guard let movieOutput = videoOutput else {
            completion(false, "Output non configuré")
            return
        }
        
        guard !movieOutput.isRecording else {
            completion(false, "Enregistrement déjà en cours")
            return
        }
        
        // Créer l'URL de sortie
        outputURL = createOutputURL()
        guard let url = outputURL else {
            completion(false, "Impossible de créer le fichier")
            return
        }
        
        // Démarrer l'enregistrement
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        
        print("🎬 Démarrage enregistrement: \(url.lastPathComponent)")
        completion(true, "Enregistrement démarré")
    }

    func stopRecording(completion: @escaping (Bool, String, URL?) -> Void) {
        guard let movieOutput = videoOutput else {
            completion(false, "Output non configuré", nil)
            return
        }
        
        guard movieOutput.isRecording else {
            completion(false, "Aucun enregistrement en cours", nil)
            return
        }
        
        // Stocker le callback pour l'utiliser dans le delegate
        stopRecordingCompletion = completion
        
        movieOutput.stopRecording()
        print("⏹️ Arrêt enregistrement demandé")
    }
    
    // MARK: - File Management
    private func createOutputURL() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoPath = documentsPath.appendingPathComponent("TwoCam_Videos")
        
        // Créer le dossier s'il n'existe pas
        try? FileManager.default.createDirectory(at: videoPath, withIntermediateDirectories: true)
        
        // Nom de fichier avec timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "TwoCam_\(timestamp).mov"
        
        return videoPath.appendingPathComponent(fileName)
    }

    // MARK: - Recording Status
    func isCurrentlyRecording() -> Bool {
        return isRecording
    }
    
    private func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0
            return String(format: "%.1f MB", Double(size) / 1_000_000)
        } catch {
            return "Inconnue"
        }
    }
    
    // MARK: - Photos Library
    private func saveVideoToPhotos(videoURL: URL, completion: @escaping (Bool, String) -> Void) {
        // Vérifier les permissions
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Sauvegarder la vidéo
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("📸 Vidéo sauvée dans Photos")
                            completion(true, "Vidéo sauvée dans Photos")
                            
                            // Supprimer le fichier temporaire
                            try? FileManager.default.removeItem(at: videoURL)
                        } else {
                            print("❌ Échec sauvegarde Photos: \(error?.localizedDescription ?? "Inconnue")")
                            completion(false, "Échec sauvegarde dans Photos")
                        }
                    }
                }
                
            case .denied, .restricted:
                DispatchQueue.main.async {
                    completion(false, "Permission Photos refusée")
                }
                
            case .notDetermined:
                DispatchQueue.main.async {
                    completion(false, "Permission Photos non définie")
                }
                
            case .limited:
                // iOS 14+ limited access
                DispatchQueue.main.async {
                    completion(false, "Accès Photos limité")
                }
                
            @unknown default:
                DispatchQueue.main.async {
                    completion(false, "État permission Photos inconnu")
                }
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("✅ Enregistrement démarré vers: \(fileURL.lastPathComponent)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print("❌ Erreur enregistrement: \(error)")
            isRecording = false
            stopRecordingCompletion?(false, "Erreur: \(error.localizedDescription)", nil)
            return
        }
        
        print("✅ Enregistrement terminé: \(outputFileURL.lastPathComponent)")
        print("📁 Taille fichier: \(getFileSize(url: outputFileURL))")
        isRecording = false
        
        // Sauvegarder dans Photos au lieu de Documents
        saveVideoToPhotos(videoURL: outputFileURL) { [weak self] success, message in
            if success {
                self?.stopRecordingCompletion?(true, "Vidéo sauvée dans Photos", outputFileURL)
            } else {
                self?.stopRecordingCompletion?(false, message, nil)
            }
            self?.stopRecordingCompletion = nil
        }
    }
}
