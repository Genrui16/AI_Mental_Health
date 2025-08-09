import Foundation
import Speech
import AVFoundation

final class SpeechService: NSObject, ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.main.async {
                self.record()
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
        try? audioEngine.start()
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
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
