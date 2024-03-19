//
//  CameraPreview.swift
//  Mini04
//
//  Created by luis fontinelles on 18/03/24.
//

import SwiftUI

struct CameraPreview : View {
    @EnvironmentObject var cameraVC: CameraViewModel
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            CameraRepresentable(size: size)
        }
        .onAppear(perform: cameraVC.configureSession)
        
        .onAppear {
            cameraVC.startSession()
        }
        .onDisappear {
            cameraVC.stopSession()
        }
    }
}