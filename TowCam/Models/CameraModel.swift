//
//  CameraModel.swift
//  TowCam
//
//  Created by Adib Triki on 21/09/2025.
//

import Foundation
import AVFoundation

class CameraModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var canUseMultiCam = false
    
    // MARK: - Initialization
    
    init() {
        checkMultiCamSupport()
    }
    
    // MARK: - Multi-Camera Support
    
    /// Fonction pour vérifier la compatibilité multi-caméra du dispositif
    private func checkMultiCamSupport() {
        canUseMultiCam = AVCaptureMultiCamSession.isMultiCamSupported
        print("Multi-cam supported: \(canUseMultiCam)")
    }
    
    // MARK: - Recording Management
    
    /// Fonction pour démarrer l'enregistrement et initialiser la durée
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        print("Recording started")
    }
    
    /// Fonction pour arrêter l'enregistrement et afficher la durée totale
    func stopRecording() {
        isRecording = false
        print("Recording stopped after \(recordingDuration) seconds")
    }
}
