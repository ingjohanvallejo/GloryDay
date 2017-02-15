//
//  ViewController.swift
//  GloryDays
//
//  Created by Johan Vallejo on 1/11/16.
//  Copyright © 2016 kijho. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet var infoLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func askForPermissions(_ sender: UIButton) {
        self.askForPhotoPermissions()
    }

    //Pedir permisos de fotos
    func askForPhotoPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] (authStatus) in
            //Se envia al hilo principal (main) el permiso de fotos, tiempo real
            DispatchQueue.main.async {
                //Comprobamos si el usuario acepto los permisos para acceder a las fotos
                if authStatus == .authorized {
                    self.askForRecordPermissions()
                } else {
                    self.infoLabel.text = "You've refused permission photo. Please turn in your device settings to continue"
                }
            }
        }
    }
    
    //Pedir permisos de grabado de voz
    func askForRecordPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] (allowed) in
            //Se envia al hilo principal (main) el permiso de grabar audio, tiempo real
            DispatchQueue.main.async {
                //Comprobamos si el usuario acepto los permisos para acceder a grabar audio
                if allowed {
                    self.askForTranscriptionPermissions()
                } else {
                    self.infoLabel.text = "You've refused permission audio record. Please turn in your device settings to continue"
                }
            }
        }
    }
    
    //Pedir permisos de transcribir text
    func askForTranscriptionPermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            //Se envia al hilo principal (main) el permiso de transcribir texto, tiempo real
            DispatchQueue.main.async {
                //Comprobamos si el usuario acepto los permisos para acceder a transcribir texto
                if authStatus == .authorized {
                    self.authorizationCompleted()
                } else {
                    self.infoLabel.text = "You've refused permission transcribing text. Please turn in your device settings to continue"
                }
            }
        }
    }
    
    //Se oculta la pantalla de pedir permisos después de que todos son aceptados
    func authorizationCompleted() {
        dismiss(animated: true, completion: nil)
    }
    
}

