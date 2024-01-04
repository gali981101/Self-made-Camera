//
//  PhotoViewController.swift
//  SelfmadeCamera
//
//  Created by Terry Jason on 2024/1/3.
//

import UIKit

class PhotoViewController: UIViewController {
    
    var image: UIImage?
    
    // MARK: - @IBOulet
    
    @IBOutlet var imageView: UIImageView!
    
}

// MARK: - Life Cycle

extension PhotoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
}

// MARK: - @IBAction

extension PhotoViewController {
    
    @IBAction func save(sender: UIButton) {
        guard let imageToSave = image else { return }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true)
    }
    
}

