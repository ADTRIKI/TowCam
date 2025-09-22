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
    
    // MARK: - Camera Devices
    
    private var backWideCamera: AVCaptureDevice?
    private var backUltraWideCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    
    // MARK: - Camera Configuration
    
    enum CameraType {
        case wide
        case ultraWide
    }
    
    private var currentCameraType: CameraType = .wide
    
    // MARK: - Recording Management
    
    private var outputURL: URL?
    private var isRecording = false
    private var stopRecordingCompletion: ((Bool, String, URL?) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        print("CameraService initialization started")
        setupCameras()
        requestPermissions()
    }
    
    // MARK: - Camera Setup
    
    /// Fonction pour configurer les dispositifs caméra disponibles
    private func setupCameras() {
        backWideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        backUltraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        currentCamera = backWideCamera
        
        print("Wide camera (1x): \(backWideCamera != nil ? "Available" : "Not available")")
        print("Ultra-wide camera (0.5x): \(backUltraWideCamera != nil ? "Available" : "Not available")")
    }
    
    /// Fonction pour demander les permissions caméra et microphone
    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            print("Camera permission: \(granted ? "Granted" : "Denied")")
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("Microphone permission: \(granted ? "Granted" : "Denied")")
        }
    }
    
    // MARK: - Session Management
    
    /// Fonction pour créer et configurer la session de capture
    func createSession() -> AVCaptureSession? {
        captureSession = AVCaptureSession()
        
        guard let session = captureSession else {
            print("Failed to create capture session")
            return nil
        }
        
        session.beginConfiguration()
        
        guard setupInputs(for: session) else {
            print("Failed to configure inputs")
            session.commitConfiguration()
            return nil
        }
        
        setupOutput(for: session)
        session.commitConfiguration()
        
        print("Capture session created successfully")
        return session
    }
    
    /// Fonction pour configurer les entrées vidéo et audio
    private func setupInputs(for session: AVCaptureSession) -> Bool {
        do {
            if let camera = currentCamera {
                videoInput = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                    print("Camera connected: \(currentCameraType == .wide ? "1x" : "0.5x")")
                } else {
                    print("Cannot add video input")
                    return false
                }
            }
            
            if let microphone = AVCaptureDevice.default(for: .audio) {
                audioInput = try AVCaptureDeviceInput(device: microphone)
                if session.canAddInput(audioInput!) {
                    session.addInput(audioInput!)
                    print("Microphone connected")
                }
            }
            
            return true
            
        } catch {
            print("Input setup error: \(error)")
            return false
        }
    }
    
    /// Fonction pour configurer la sortie d'enregistrement
    private func setupOutput(for session: AVCaptureSession) {
        videoOutput = AVCaptureMovieFileOutput()
        
        if let output = videoOutput, session.canAddOutput(output) {
            session.addOutput(output)
            print("Output configured")
        }
    }
    
    // MARK: - Camera Switching
    
    /// Fonction pour changer entre les caméras wide et ultra-wide
    func switchCamera(completion: @escaping (Bool, CameraType) -> Void) {
        guard let session = captureSession else {
            completion(false, currentCameraType)
            return
        }
        
        let newCameraType: CameraType = currentCameraType == .wide ? .ultraWide : .wide
        let newCamera: AVCaptureDevice?
        
        switch newCameraType {
        case .wide:
            newCamera = backWideCamera
        case .ultraWide:
            newCamera = backUltraWideCamera
        }
        
        guard let camera = newCamera else {
            print("Camera not available: \(newCameraType)")
            completion(false, currentCameraType)
            return
        }
        
        session.beginConfiguration()
        
        if let oldInput = videoInput {
            session.removeInput(oldInput)
        }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoInput!) {
                session.addInput(videoInput!)
                currentCamera = camera
                currentCameraType = newCameraType
                session.commitConfiguration()
                
                print("Camera switched to: \(newCameraType == .wide ? "1x" : "0.5x")")
                completion(true, newCameraType)
            } else {
                session.commitConfiguration()
                completion(false, currentCameraType)
            }
        } catch {
            session.commitConfiguration()
            print("Camera switch error: \(error)")
            completion(false, currentCameraType)
        }
    }
    
    // MARK: - Recording Control
    
    /// Fonction pour démarrer l'enregistrement vidéo
    func startRecording(completion: @escaping (Bool, String) -> Void) {
        guard let movieOutput = videoOutput else {
            completion(false, "Output not configured")
            return
        }
        
        guard !movieOutput.isRecording else {
            completion(false, "Recording already in progress")
            return
        }
        
        outputURL = createOutputURL()
        guard let url = outputURL else {
            completion(false, "Cannot create output file")
            return
        }
        
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        
        print("Recording started: \(url.lastPathComponent)")
        completion(true, "Recording started")
    }
    
    /// Fonction pour arrêter l'enregistrement vidéo
    func stopRecording(completion: @escaping (Bool, String, URL?) -> Void) {
        guard let movieOutput = videoOutput else {
            completion(false, "Output not configured", nil)
            return
        }
        
        guard movieOutput.isRecording else {
            completion(false, "No recording in progress", nil)
            return
        }
        
        stopRecordingCompletion = completion
        movieOutput.stopRecording()
        print("Recording stop requested")
    }
    
    // MARK: - File Management
    
    /// Fonction pour créer l'URL de sortie pour les fichiers vidéo
    private func createOutputURL() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoPath = documentsPath.appendingPathComponent("TwoCam_Videos")
        
        try? FileManager.default.createDirectory(at: videoPath, withIntermediateDirectories: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "TwoCam_\(timestamp).mov"
        
        return videoPath.appendingPathComponent(fileName)
    }
    
    /// Fonction pour obtenir la taille d'un fichier
    private func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0
            return String(format: "%.1f MB", Double(size) / 1_000_000)
        } catch {
            return "Unknown"
        }
    }
    
    // MARK: - Recording Status
    
    /// Fonction pour vérifier l'état d'enregistrement
    func isCurrentlyRecording() -> Bool {
        return isRecording
    }
    
    // MARK: - Photos Integration
    
    /// Fonction pour sauvegarder la vidéo dans la bibliothèque Photos
    private func saveVideoToPhotos(videoURL: URL, completion: @escaping (Bool, String) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Video saved to Photos")
                            completion(true, "Video saved to Photos")
                            try? FileManager.default.removeItem(at: videoURL)
                        } else {
                            print("Failed to save to Photos: \(error?.localizedDescription ?? "Unknown")")
                            completion(false, "Failed to save to Photos")
                        }
                    }
                }
                
            case .denied, .restricted:
                DispatchQueue.main.async {
                    completion(false, "Photos permission denied")
                }
                
            case .notDetermined:
                DispatchQueue.main.async {
                    completion(false, "Photos permission not determined")
                }
                
            case .limited:
                DispatchQueue.main.async {
                    completion(false, "Limited Photos access")
                }
                
            @unknown default:
                DispatchQueue.main.async {
                    completion(false, "Unknown Photos permission state")
                }
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    /// Fonction pour traiter le début d'enregistrement
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Recording started to: \(fileURL.lastPathComponent)")
    }
    
    /// Fonction pour traiter la fin d'enregistrement et sauvegarder
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print("Recording error: \(error)")
            isRecording = false
            stopRecordingCompletion?(false, "Error: \(error.localizedDescription)", nil)
            return
        }
        
        print("Recording completed: \(outputFileURL.lastPathComponent)")
        print("File size: \(getFileSize(url: outputFileURL))")
        isRecording = false
        
        saveVideoToPhotos(videoURL: outputFileURL) { [weak self] success, message in
            if success {
                self?.stopRecordingCompletion?(true, "Video saved to Photos", outputFileURL)
            } else {
                self?.stopRecordingCompletion?(false, message, nil)
            }
            self?.stopRecordingCompletion = nil
        }
    }
}
