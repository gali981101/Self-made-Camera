//
//  ViewController.swift
//  SelfmadeCamera
//
//  Created by Terry Jason on 2024/1/3.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    
    var currentDevice: AVCaptureDevice!
    
    var stillImageOutput: AVCapturePhotoOutput!
    var stillImage: UIImage?
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
    // MARK: - @IBOulet
    
    @IBOutlet var cameraButton:UIButton!
}

// MARK: - Life Cycle

extension CameraViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
}

// MARK: - @IBAction

extension CameraViewController {
    
    @IBAction func capture(sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        stillImageOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
}

// MARK: - Set Up

extension CameraViewController {
    
    private func configure() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera
        
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else { return }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(stillImageOutput)
        
        provideCameraPreview(session: captureSession)
        
        toggleCameraGestureRecognizer.direction = .up
        toggleCameraGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
        
        view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
    }
    
}

// MARK: - @Objc Methods

extension CameraViewController {
    
    @objc func toggleCamera() {
        captureSession.beginConfiguration()
        
        guard let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontFacingCamera : backFacingCamera else { return }
        
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        let cameraInput: AVCaptureDeviceInput
        
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    @objc func zoomIn() {
        guard let zoomFactor = currentDevice?.videoZoomFactor else { fatalError() }
        
        if zoomFactor < 5.0 {
            let newZoomFactor = min(zoomFactor + 1.0, 5.0)
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                currentDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    @objc func zoomOut() {
        guard let zoomFactor = currentDevice?.videoZoomFactor else { fatalError() }
        
        if zoomFactor > 1.0 {
            let newZoomFactor = max(zoomFactor - 1.0, 1.0)
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                currentDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
}

// MARK: - Segues

extension CameraViewController {
    
    @IBAction func unwindToCameraView(segue: UIStoryboardSegue) {
    }
    
}

// MARK: - Prepare Segue

extension CameraViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            let destinationVC = segue.destination as! PhotoViewController
            destinationVC.image = stillImage
        }
    }
    
}

// MARK: - Helper Methods

extension CameraViewController {
    
    private func provideCameraPreview(session: AVCaptureSession) {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(cameraPreviewLayer!)
        
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        
        view.bringSubviewToFront(cameraButton)
        
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
        guard let imageData = photo.fileDataRepresentation() else { return }
        stillImage = UIImage(data: imageData)
        performSegue(withIdentifier: "showPhoto", sender: self)
    }
    
}
