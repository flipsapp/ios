//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import AVFoundation

public typealias RecordError = (String?) -> Void

public class AudioRecorderService: NSObject, AVAudioRecorderDelegate {
    
    private var recorder: AVAudioRecorder!
    private var soundFileURL: NSURL?
    
    weak var delegate: AudioRecorderServiceDelegate?
    
    private func setupRecorder() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_hh:mm:ss.SSS"
        let currentFileName = "recording-\(dateFormatter.stringFromDate(NSDate())).m4a"
        
        var dirPaths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        var docsDir: AnyObject = dirPaths[0]
        var soundFilePath = docsDir.stringByAppendingPathComponent(currentFileName)
        soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        
        var recordSettings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        var error: NSError?
        recorder = AVAudioRecorder(URL: soundFileURL!, settings: recordSettings as [NSObject : AnyObject], error: &error)
        if let e = error {
            println(e.localizedDescription)
        } else {
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        }
    }
    
    private func setSessionPlayAndRecord() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker, error:&error) {
            println("could not set session category")
            if let e = error {
                println(e.localizedDescription)
            }
        }
        if !session.setActive(true, error: &error) {
            println("could not make session active")
            if let e = error {
                println(e.localizedDescription)
            }
        }
    }
    
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        println("finished recording with success? \(flag)")
        self.delegate?.audioRecorderService(self, didFinishRecordingAudioURL: recorder.url, success: flag)
    }
    
    func removeLastRecordedAudio() {
        self.recorder.deleteRecording()
    }
    
    func startRecording(error: RecordError) {
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool) -> Void in
            self.delegate?.audioRecorderService(self, didRequestRecordPermission: granted)
            
            if (granted) {
                self.setupRecorder()
                self.setSessionPlayAndRecord()
                self.recorder.record()
                NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "stopRecording", userInfo: nil, repeats: false)
            } else {
                error(LocalizedString.ERROR)
            }
        })
    }
    
    func startManualRecording(error: RecordError) {
        
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool) -> Void in
            
            self.delegate?.audioRecorderService(self, didRequestRecordPermission: granted)
            
            if (granted)
            {
                self.setupRecorder()
                self.setSessionPlayAndRecord()
                self.recorder.record()
            }
            else
            {
                error(LocalizedString.ERROR)
            }
            
        })
        
    }
    
    func stopRecording() {
        
        self.recorder.stop()
        
        var error: NSError?
        
        if (!AVAudioSession.sharedInstance().setActive(false, error: &error))
        {
            println("could not deactivate audio session")
            if let e = error {
                println(e.localizedDescription)
            }
        }
        
        self.recorder = nil
        
    }

}

protocol AudioRecorderServiceDelegate: class {
    
    func audioRecorderService(audioRecorderService: AudioRecorderService!, didFinishRecordingAudioURL: NSURL?, success: Bool!)
    
    func audioRecorderService(audioRecorderService: AudioRecorderService!, didRequestRecordPermission: Bool)
    
}
