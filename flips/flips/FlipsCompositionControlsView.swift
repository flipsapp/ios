//
//  FlipsCompositionControlsView.swift
//  flips
//
//  Created by Taylor Bell on 8/27/15.
//
//

import Foundation

class FlipsCompositionControlsView : UIView, ComposeCaptureControlsViewDelegate, ComposeEditControlsViewDelegate {
    
    weak var delegate : FlipsCompositionControlsDelegate!
    weak var dataSource : FlipsViewDataSource? {
        set {
            self.editControlsView!.dataSource = newValue
            self.captureControlsView!.dataSource = newValue
        }
        get { return self.captureControlsView!.dataSource }
    }
    
    // UI
    private var editControlsView : ComposeEditControlsView!
    private var captureControlsView : ComposeCaptureControlsView!
    
    
    
    ////
    // MARK: - Init
    ////
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRectZero)
        initSubviews()
        initConstraints()
    }

    
    
    ////
    // MARK: - Subview Initialization
    ////
    
    func initSubviews() {
        
        editControlsView = ComposeEditControlsView()
        editControlsView.delegate = self
        editControlsView.hidden = true
        
        captureControlsView = ComposeCaptureControlsView()
        captureControlsView.delegate = self
        captureControlsView.hidden = true
        
        self.addSubview(editControlsView)
        self.addSubview(captureControlsView)
        
    }
    
    func initConstraints() {
        
        editControlsView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self)
        }
        
        captureControlsView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self)
        }
        
    }
    
    
    
    ////
    // MARK: - Control View Management
    ////
    
    internal func enableCameraControls() {
        captureControlsView.enableCameraControls()
    }
    
    internal func disableCameraControls() {
        captureControlsView.disableCameraControls()
    }
    
    internal func showCaptureControls() {
        editControlsView.hidden = true
        captureControlsView.hidden = false
    }
    
    internal func showEditControls() {
        captureControlsView.hidden = true
        editControlsView.hidden = false
    }
    
    
    
    ////
    // MARK: - ComposeCaptureControlsViewDelegate
    ////
    
    func didSelectStockFlipAtIndex(index: Int) {
        delegate?.didSelectStockFlipAtIndex(index)
    }
    
    func didSelectFlipAtIndex(index: Int) {
        delegate?.didSelectFlipAtIndex(index)
    }
    
    func didPressVideoButton() {
        delegate?.didPressVideoButton()
    }
    
    func didReleaseVideoButton() {
        delegate?.didReleaseVideoButton()
    }
    
    func didTapCapturePhotoButton() {
        delegate?.didTapCapturePhotoButton()
    }
    
    func didTapGalleryButton() {
        delegate?.didTapGalleryButton()
    }
    
    
    
    ////
    // MARK: - ComposeCaptureControlsViewDelegate
    ////
    
    func didTapDeleteButton() {
        delegate?.didTapDeleteButton()
    }
    
}

protocol FlipsCompositionControlsDelegate : class {
    
    func didSelectStockFlipAtIndex(index: Int)
    
    func didSelectFlipAtIndex(index: Int)
    
    func didPressVideoButton()
    
    func didReleaseVideoButton()
    
    func didTapCapturePhotoButton()
    
    func didTapGalleryButton()
    
    func didTapDeleteButton()
    
}