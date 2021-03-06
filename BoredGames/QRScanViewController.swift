//
//  QRScanViewController.swift
//  BoredGames
//
//  Created by Isaiah Smith on 1/29/16.
//  Copyright © 2016 Isaiah Smith. All rights reserved.
//

import UIKit
import AVFoundation // Not in tvOS SDK?
import AudioToolbox

class QRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var hadIssue = false
    
    var scanFound = false
    
    @IBOutlet weak var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var input: AVCaptureDeviceInput?
        
        do {
            input = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            print(error.localizedDescription)
            input = nil
        }
        
        captureSession = AVCaptureSession()
        
        guard let theInput = input else {
            print("Input nonexistent");
            hadIssue = true
            return
        }
        
        captureSession?.addInput(theInput)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        
        captureSession?.addOutput(captureMetadataOutput)
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        captureSession?.startRunning()
        
        view.bringSubviewToFront(cancelButton)
        
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2.0
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)
    }
    
    override func viewDidAppear(animated: Bool) {
        if hadIssue {
            self.alertIssue("We weren't able to connect with an input to scan for a game QR code.")
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if scanFound {
            return
        }
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj) as! AVMetadataMachineReadableCodeObject
            
            qrCodeFrameView?.frame = barCodeObject.bounds
            
            if metadataObj.stringValue != nil {
                scanFound = true
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                print(metadataObj.stringValue)
                
                // TODO: Handle QR Code Here
                let json = JSON.parse(metadataObj.stringValue)
                
                let gameTitle = json["title"].stringValue
                let room = json["id"].stringValue
                
                var player: Player?
                
                switch gameTitle {
                case Utilities.Constants.get("TimelineTitle") as! String:
                    player = TimelinePlayer(room: room)
                    break;
                default:
                    player = nil
                }
                
                if let thePlayer = player {
                    thePlayer.setup()
                    
                    let vc = thePlayer.getPlayerViewController()
                    
                    self.presentViewController(vc, animated: true, completion: nil)
                
                } else {
                    self.alertIssue("We weren't able to find a game based on that QR code. Please try again.")
                    return
                }
            }
        }
    }
    
    func alertIssue(msg: String){
        let confirmation = UIAlertController(title: "Uh Oh!", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        
        confirmation.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
            // Handle user confirming word reset
            self.cancelPressed(self)
        }))
        
        self.presentViewController(confirmation, animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
