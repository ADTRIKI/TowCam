import Foundation
import AVFoundation

class CameraModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var canUseMultiCam = false
    
    init() {
        checkMultiCamSupport()
    }
    
    private func checkMultiCamSupport() {
        canUseMultiCam = AVCaptureMultiCamSession.isMultiCamSupported
        print ("Multi-cam supporté : \(canUseMultiCam)")
    }
    
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        print("Enregistrement commencé")
    }
    
    func stopRecording() {
        isRecording = false
        print("Enregistrement arrêté après \(recordingDuration) secondes")
    }
}
