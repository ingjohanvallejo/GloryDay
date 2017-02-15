//
//  MemoriesCollectionViewController.swift
//  GloryDays
//
//  Created by Johan Vallejo on 1/11/16.
//  Copyright © 2016 kijho. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech
import CoreSpotlight
import MobileCoreServices

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, UISearchBarDelegate {

    var memories : [URL] = []
    var filteredMemories : [URL] = []
    var currentMemory : URL!
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var recordingURL : URL!
    var searchQuery :CSSearchQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.recordingURL = try? getDocumentDirectory().appendingPathComponent("memory-recording.m4a")
        
        self.loadMemories()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))

        self.hideKeyboardWhenTappingAround()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // self.collectionView!.register(MemoryCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    //Se agrega en el viewDidAppear pq allí ya se han cargado los elementos
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkForGrantedPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Verifico que tenga los permisos, si no los tengo lo envio al ViewController de permisos
    func checkForGrantedPermissions() {
        let photosAuth : Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth : Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth : Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let  authorized = photosAuth && recordingAuth && transcriptionAuth
        
        //Si no estoy autorizado muestro la pantalla para pedirlos
        if !authorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "showTerms") {
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func loadMemories() {
        self.memories.removeAll()
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }

        for file in files {
            //Así no se pueda obtener el nombre del archivo se continua
            //guard let fileName = String(file.lastPathComponent) else {
            //    continue
            //}
            
            let fileName = file.lastPathComponent
        
            //Obtengo el nombre del archivo sin extensión
            if fileName.hasSuffix(".thumb") {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                //Se guarda en el arreglo memories, este nombre lo podemos utilizar con las diferentes extensiones
                let memoryPath =  getDocumentDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        filteredMemories = memories
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    //Se obtiene un directorio del usuario
    func getDocumentDirectory() -> URL {
        let paths =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    //Ingresar imagen
    func addImagePressed() {
        
        let  vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    //Se genera el modal con la imagen seleccionada
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addNewMemory(image: theImage)
            self.loadMemories()
            self.dismiss(animated: true)
        }
    }
    
    //Se agreag una memoria
    func addNewMemory(image: UIImage) {
        let memoryName = "Memory-\(Date())"
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        //Se guarda la imagen en disco
        do {
            let imagePath = getDocumentDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbail = resizeImage(image: image, to: 200) {
                let thumbPath = getDocumentDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbail, 80) {
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
                
            }
            
        } catch {
            print("Ha fallado la escritura en disco")
        }
    }
    
    //Se redimensiona la imagen para mostrarla en miniatura
    func resizeImage(image: UIImage, to width: CGFloat) -> UIImage? {
        //Se calcula el factor de escalado y su altura con este mismo
        let scaleFactor = width / image.size.width
        let height = image.size.height * scaleFactor
        //Se redimensiona la imagen
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imgeURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    //Secciones
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    //Numero de elementos
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 0 {
            return 0
        } else {
            return filteredMemories.count
        }
    }

    //configuración de la celda
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Configure the cell

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        let memory = self.filteredMemories[indexPath.row]
        let memoryName = self.thumbailURL(for: memory).path 
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageMemory.image = image

        //pulsasion larga en la pantalla
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
        }
        return cell
    }
    
    //Cuando una celda se presione de forma prolongada se llama este metodo
    func memoryLongPressed(sender : UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell) {
                self.currentMemory = self.filteredMemories[index.row]
                self.startRecordingMemory()
            }
        }
        
        if sender.state == .ended {
            self.finishRecordingMemory(success: true)
        }
    }
    
    //Empezar la grabación
    func startRecordingMemory() {
        
        audioPlayer?.stop()
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let recordingSetting = [AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                                    AVSampleRateKey : 44100.0,
                                    AVNumberOfChannelsKey : 2 as NSNumber,
                                    AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue] as [String : Any]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSetting)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
        } catch let error {
            print(error)
            finishRecordingMemory(success: false)
        }
        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {

        if !flag {
            self.finishRecordingMemory(success: false)
        }
    }
    
    //Parar la grabación
    func finishRecordingMemory(success : Bool) {

        collectionView?.backgroundColor = UIColor(red: 94.0/255.0, green: 100.0/255.0, blue: 171.0/255.0, alpha: 1.0)
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = try self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioURL.path) {
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                self.transcribeAudioToText(memory: self.currentMemory)
            } catch let error {
                print("Existe eroro Finish - \(error)")
            }
        }
        
    }
    
    //Transcribir de Audio a Texto
    func transcribeAudioToText(memory : URL) {

        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)

        recognizer?.recognitionTask(with: request, resultHandler: {[unowned self](result, error) in
            
            guard let result = result else {
                print("Ha existido un error trancibe - \(error)")
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.indexMemory(memory: memory, text: text)
                } catch {
                    print("Ha existido un error al guardar la transcripción")
                }
            }
            
        })
        
    }
    
    //Por medio de este meto-do se busca con el spotlight por fuera de la app en la app
    func indexMemory(memory : URL,text : String) {
        
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Recuerdo de Glory Day"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbailURL(for: memory)
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.johan", attributeSet: attributeSet)
        item.expirationDate = Date.distantFuture
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            if let error = error {
                print("No se ha podido Indexar: \(error)")
            } else{
                print("Hemos podido indexar correctamente: \(text)")
            }
        }
        
    }
    
    //Activo la funcionaldiad e buscardor
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        return header
    }
    
    //Se muestra el buscador solo para la primera sección
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: 0, height: 50)
        } else {
            return CGSize.zero
        }
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let memory = self.filteredMemories[indexPath.row]
        let fileManager = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path) {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            
            if fileManager.fileExists(atPath: transcriptionName.path) {
                let content = try String(contentsOf: transcriptionName)
                print(content)
                //Se agrega un alert para mostrar el texto al usuario
                let alertController = UIAlertController(title: "Description" , message: content, preferredStyle: .alert)
                let cancelAlert = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alertController.addAction(cancelAlert)
            }

        } catch {
            print("Error al cargar el audio para reproducir")
        }
    }

    //Buscar las imagenes en el listado de imagenes
    func filterMemories(text: String) {
        
        guard text.characters.count > 0 else {
            
            self.filteredMemories = self.memories
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer : 1))
            }

            return
        }
        var allTheItems : [CSSearchableItem] = []
        self.searchQuery?.cancel()
        /*Buscar en el contentDescription las las palabras que ventan en text sin importar loq ue venga adelante o atrás. 
            la c indica que sea indiferente si es mayuscula o minuscula.*/
        let queryString = "contentDescription == \"*\(text)*\"c"
        self.searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        self.searchQuery?.foundItemsHandler = { items in
            allTheItems.append(contentsOf: items)
        }
        
        self.searchQuery?.completionHandler = { error in
            //se ejecuta en el hilo principal
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allTheItems)
            }
        }
        
        self.searchQuery?.start()
    }
    
    func activateFilter(matches : [CSSearchableItem]) {
        
        self.filteredMemories = matches.map { item in
            let uniqueID = item.uniqueIdentifier
            let url = URL(fileURLWithPath: uniqueID)
            return url
        }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer : 1))
        }
    }
    
    //Realiza el filtrado cada vez que el usuario introduce una letra
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    
    //cuando el usuario presiona el botón de buscar, oculta el teclado
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension UICollectionViewController {
    
    func hideKeyboardWhenTappingAround() {
        let tap :  UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UICollectionViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
