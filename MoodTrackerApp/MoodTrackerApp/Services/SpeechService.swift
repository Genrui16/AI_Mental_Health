import Foundation
import Speech
import AVFoundation

@available(iOS 15.0, macOS 10.15, *)
@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.errorMessage = nil
                    self.record()
                case .denied:
                    self.errorMessage = "语音识别权限被拒绝"
                case .restricted:
                    self.errorMessage = "设备不支持语音识别"
                case .notDetermined:
                    self.errorMessage = "语音识别权限未确定"
                @unknown default:
                    self.errorMessage = "未知的授权状态"
                }
            }
        }
    }
    
    private func record() {
        isRecording = true
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = error.localizedDescription
            transcribedText = ""
            isRecording = false
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            request.endAudio()
            self.request = nil
            self.task = nil
            return
        }
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            } else if result?.isFinal ?? false {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
        audioEngine.stop()
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
}
