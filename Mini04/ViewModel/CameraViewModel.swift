//
//  File.swift
//  Mini04
//
//  Created by luis fontinelles on 18/03/24.
//

import SwiftUI
import AVFoundation
import AppKit
import Vision

class CameraViewModel: NSObject, ObservableObject {
    var cameraDevice: AVCaptureDevice!
    var cameraInput: AVCaptureInput!
    var micDevice: AVCaptureDevice!
    var micInput: AVCaptureInput!
    
    var previewLayer =  AVCaptureVideoPreviewLayer()
    @Published var videoFileOutput = AVCaptureMovieFileOutput()
    @Published var videoDataOutput = AVCaptureVideoDataOutput()
    @Published var audioOutput = AVCaptureAudioDataOutput()
    @Published var captureSession =  AVCaptureSession()

    @Published var isRecording = false
    
    @Published var handPoseModelController: HandGestureController?
    @Published var detectedGestureModel1: String = ""
    @Published var detectedGestureModel2: String = ""

    var urltemp: URL?
    
    override init() {
        super.init()
        self.handPoseModelController = HandGestureController()
        self.handPoseModelController?.onResultModel1Changed = { [weak self] resultModel in
            DispatchQueue.main.async {
                self?.detectedGestureModel1 = resultModel
            }
        }
    }
    
    // MARK: - Start/Stop Session

    func startSession() {
        guard !captureSession.isRunning else {
            return
        }

        DispatchQueue.global().async {
            self.captureSession.startRunning()
            print("sessão iniciada")
        }
    }

    func stopSession() {
        guard captureSession.isRunning else {
            return
        }

        DispatchQueue.global().async {
            self.captureSession.stopRunning()
            print("sessão finalizada")
        }
    }
    
    // MARK: - Session Configuration
    func configureSession() {
        captureSession.beginConfiguration()
        
        // Remove existing inputs and outputs before reconfiguring
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }

        setupInputs()
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }

        if captureSession.canAddOutput(videoFileOutput) {
            captureSession.addOutput(videoFileOutput)
        }
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        captureSession.commitConfiguration()
    }
    
    func setupInputs(){
        // setting devices
        if let device = AVCaptureDevice.default(for: .video) {
            cameraDevice = device
        } else {
            fatalError("Cant catch camera device")
        }

        
        if let microphoneDevice = AVCaptureDevice.default(for: .audio) {
            micDevice = microphoneDevice
        } else {
            fatalError("no mic")
        }
        
        //setting inputs
        if let audioInput = try? AVCaptureDeviceInput(device: micDevice) {
            micInput = audioInput
        } else {
            fatalError("no input mic")
        }
        
        if let cInput = try? AVCaptureDeviceInput(device: cameraDevice) {
            cameraInput = cInput
        } else {
            fatalError("could not create input device from back camera")
        }

        // conficurar os devices na sessão
        captureSession.addInput(micInput)
        captureSession.addInput(cameraInput)
    }

}

/// MARK: VIDEO RECORDING
extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        print("nome do arquivo: \(outputFileURL)")
        
        self.urltemp = outputFileURL
    }
    
    func startRecording() {
        isRecording = true
        print("começou a gravar")
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        videoFileOutput.startRecording(to: URL(filePath: tempURL), recordingDelegate: self)
    }
    
    func stopRecording() {
        isRecording = false
        guard videoFileOutput.isRecording else {
            print("Nenhuma gravação em andamento.")
            return
        }
        
        videoFileOutput.stopRecording()
    }

    
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handPoseModelController?.performHandPoseRequest(sampleBuffer: sampleBuffer)
        
    }
}


struct CameraRepresentable: NSViewRepresentable {
    @EnvironmentObject var camVM: CameraViewModel
    var size: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        view.wantsLayer = true // Certifique-se de que a view tenha uma camada

        DispatchQueue.main.async {
            self.camVM.previewLayer = AVCaptureVideoPreviewLayer(session: self.camVM.captureSession)
            self.camVM.previewLayer.frame = view.bounds
            self.camVM.previewLayer.videoGravity = .resizeAspect
            self.camVM.previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
            self.camVM.previewLayer.connection?.isVideoMirrored = true // Espelhando horizontalmente
            view.layer?.addSublayer(self.camVM.previewLayer)
        }


        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Atualizações de visualização, se necessário
    }
}

struct CameraOverlayView: View {
    @EnvironmentObject var camVM: CameraViewModel
    let size: CGSize
    
    @State private var previousPosition: CGPoint = .zero
    @State private var previousSize: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            if let observationsBuffer = self.camVM.handPoseModelController?.observationsBuffer.last,
               let allPoints = try? self.camVM.handPoseModelController?.processPoints(from: observationsBuffer) {
                
                let averageDistance = calculateAverageDistance(allPoints: allPoints)
                
                let averageX = allPoints.reduce(0, { $0 + $1.location.x }) / CGFloat(allPoints.count)
                let averageY = allPoints.reduce(0, { $0 + $1.location.y }) / CGFloat(allPoints.count)

                Circle()
                    .stroke(lineWidth: averageDistance * size.width / 10)
                    .foregroundColor(.red)
                    .frame(width: averageDistance * size.width * 2, height: averageDistance * size.height * 2)
                    .position(x: averageX * size.width, y: averageY * size.height)
                    .onAppear {
                        previousPosition = CGPoint(x: averageX * size.width, y: averageY * size.height)
                        previousSize = averageDistance * size.width
                    }
                    .onChange(of: averageX)  { oldx, newX in
                        withAnimation {
                            previousPosition.x = newX * size.width
                        }
                    }
                    .onChange(of: averageY) { oldY, newY in
                        withAnimation {
                            previousPosition.y = newY * size.height
                        }
                    }
                    .onChange(of: averageDistance){ oldDistance, newDistance in
                        withAnimation {
                            previousSize = newDistance * size.width
                        }
                    }
                    .animation(.easeInOut, value: 0.3) // Adjust duration as needed
            }
        }
    }
    
    func calculateAverageDistance(allPoints: [VNRecognizedPoint]) -> CGFloat {
        var distances: [CGFloat] = []
        
        for point1 in allPoints {
            for point2 in allPoints {
                let distance = sqrt(pow(point1.location.x - point2.location.x, 2) + pow(point1.location.y - point2.location.y, 2))
                distances.append(distance)
            }
        }
        
        return distances.reduce(0.0, +) / CGFloat(distances.count)
    }
}












