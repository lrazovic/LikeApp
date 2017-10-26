//
//  ViewController.swift
//  LikeApp
//
//  Created by Leonardo Razovic on 18/10/17.
//  Copyright © 2017 Leonardo Razovic. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AVFoundation


class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        cityPicker.dataSource = self
        cityPicker.delegate = self
        urlField.delegate = self
        if(UIPasteboard.general.string?.contains("instagram"))! {
            urlString = UIPasteboard.general.string!
            urlField.insertText(urlString)
        }
    }
    
    // MARK: Variables
    let pickerData = ["Roma","Torino","Milano","Bologna","Napoli"]
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
    var urlString: String = ""
    var pickedCity: String = "Roma"
    var player: AVAudioPlayer?
    
    // MARK: Outlets
    @IBOutlet weak var buttonUi: UIButton!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var cityPicker: UIPickerView!
    @IBOutlet weak var downloadedPhoto: UIImageView!
    @IBOutlet weak var locationText: UILabel!
    
    // MARK: Functions
    @IBAction func generateButton(_ sender: UIButton) {
        self.buttonPressed()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickedCity = pickerData[row]
        return pickerData[row] as String
    }
    
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        self.buttonPressed()
        return true
    }
    
    func getPhoto(swiftyJsonVar:JSON) -> String {
      return swiftyJsonVar["graphql"]["shortcode_media"]["display_url"].stringValue
    }
    
    func getUrl() -> String {
        return urlField.text! + "?__a=1"
    }
        
    func getUsername(swiftyJsonVar:JSON) -> String {
        return swiftyJsonVar["graphql"]["shortcode_media"]["owner"]["username"].stringValue
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
    
    func downloadImage(url: URL) {
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            DispatchQueue.main.async() {
                self.downloadedPhoto.image = UIImage(data: data)
            }
        }
        UIViewPropertyAnimator(duration: 1, curve: .easeIn) {
            self.downloadedPhoto.layer.cornerRadius = 8
            self.setShadow()
            }.startAnimation()
        self.playSound(name: "complete")
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if (self.downloadedPhoto.image != nil) {
            let shareText = ""
            let vc = UIActivityViewController(activityItems: [shareText, self.downloadedPhoto.image!], applicationActivities: [])
            self.present(vc, animated: true, completion: nil) } else { return }
    }
    
    func generateDescription(swiftyJsonVar:JSON)  {
        let ret: String = getRightDesc(pickedCity: pickedCity, username: getUsername(swiftyJsonVar: swiftyJsonVar))
        UIPasteboard.general.string = ret;
    }
    
    func getRightDesc(pickedCity: String, username: String) -> String {
        switch pickedCity {
            case "Roma":
                return "📍 Roma\n📸 Foto di @\(username)\n-\nSeguici su ➡️ @likerome\n-\nTag:#️⃣ #likerome\n-\n\n#roma #igerslazio #igersroma #ig_rome #volgoroma #noidiroma #unlimitedrome #ilmegliodiroma #yallerslazio #visit_rome #igersitalia #ig_europe #igers_italia #total_italy #noidiroma #italiainunoscatto #likeitaly #TheGlobeWanderer"
            case "Torino":
                return "📍 Torino\n📸 Foto di @\(username)\n-\nSeguici su ➡️ @liketorino\n-\nTag:#️⃣ #liketorino\n-\n\n#torino #ig_piemonte #ig_piedmont #instaitalia #igersitaly #italiainunoscatto #bellaitalia #ilmegliodiroma #yallerslazio #visit_rome #igersitalia #ig_europe #igers_italia #total_italy #noidiroma #italiainunoscatto #likeitaly #TheGlobeWanderer"
            case "Milano":
                return "📍 Milano\n📸 Foto di @\(username)\n-\nSeguici su ➡️ @likemilano\n-\nTag:#️⃣ #likemilano\n-\n\n#torino #igerslazio #igersroma #ig_rome #volgoroma #noidiroma #unlimitedrome #ilmegliodiroma #yallerslazio #visit_rome #igersitalia #ig_europe #igers_italia #total_italy #noidiroma #italiainunoscatto #likeitaly #TheGlobeWanderer"
            case _:
                return "Altra Citta"
        }
    }
    
    func buttonPressed(){
        //Levo la tastiera
        self.hideKeyboardWhenTappedAround()
        
        if urlField.text!.contains("instagram") {
            self.playSound(name: "done")
            let url = getUrl()
            Alamofire.request(url).validate().responseJSON { response in
                switch response.result {
                case .success:
                    //Scarico JSON
                    let swiftyJsonVar = JSON(response.result.value!)
                    
                    //Genero la Descrcizione
                    self.generateDescription(swiftyJsonVar: swiftyJsonVar)
                    
                    //Scarico la Foto e la inserisco nella UI
                    if let url = URL(string: self.getPhoto(swiftyJsonVar: swiftyJsonVar)) {
                        self.downloadedPhoto.contentMode = .scaleAspectFit
                        self.downloadImage(url: url)
                    }
                    
                    //Scrivo il Geotag
                    self.locationText.text = self.getLocation(swiftyJsonVar: swiftyJsonVar)
                case .failure(_):
                    self.playSound(name: "error")
                    let alert = UIAlertController(title: "URL Instagram non valido!", message: "Inserisci un URL valido", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Riprova"), style: .`default`, handler: { _ in
                        NSLog("The \"OK\" alert occured.")
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }
        } else {
            self.playSound(name: "error")
            let alert = UIAlertController(title: "URL non valido!", message: "Inserisci un URL valido", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Riprova"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func getLocation(swiftyJsonVar:JSON) -> String {
        let locationString = swiftyJsonVar["graphql"]["shortcode_media"]["location"]["name"].stringValue
        if (locationString == "") { return "📍" + "Non Impostata" }
        else { return "📍" + locationString }
    }
    
    func playSound(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func setUI(){
        // Button
        self.buttonUi.layer.cornerRadius = 20
        self.buttonUi.center = view.center
        
        // Picker
        self.cityPicker.center = view.center
        
        // Image
        self.downloadedPhoto.contentMode = .scaleAspectFill
        self.downloadedPhoto.clipsToBounds = true
        self.downloadedPhoto.isUserInteractionEnabled = true
        self.downloadedPhoto.addGestureRecognizer(longPressRecognizer)
        
        // Keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    func setShadow() {
        self.downloadedPhoto.layer.shadowOpacity = 0.45
        //self.downloadedPhoto.layer.shadowColor = .CGColor
        self.downloadedPhoto.layer.shadowRadius = 8
        self.downloadedPhoto.layer.shadowOffset = CGSize(width: 10, height: 10)
    }
}




