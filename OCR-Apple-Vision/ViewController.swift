//
//  ViewController.swift
//  OCR-Apple-Vision
//
//  Created by Pawan kumar on 24/01/20.
//  Copyright © 2020 Pawan Kumar. All rights reserved.
//


import UIKit
import Vision
import VisionKit

struct ReadItem {
    var title: String = ""
}

class ViewController: UIViewController {
    
    //Declare Local Array here
    var wordlists: Array <ReadItem> = Array <ReadItem>()
    
    @IBOutlet weak var chooseImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var _textRecognitionRequest: Any? = nil
    @available(iOS 13.0, *)
    fileprivate var textRecognitionRequest: VNRecognizeTextRequest {
        if _textRecognitionRequest == nil {
            _textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
        }
        return _textRecognitionRequest as! VNRecognizeTextRequest
    }
    
    private let textRecognitionWorkQueue = DispatchQueue(label: "OCR_Apple_Vision", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Get Device Local
        let langStr = Locale.current.languageCode
        print("Locale:- ", langStr) //Locale:-  Optional("en")
        
        let preferredLanguage = Locale.preferredLanguages[0] as String
        print ("preferredLanguage:-", preferredLanguage) //en-US //preferredLanguage:- ja-JP

        let arr = preferredLanguage.components(separatedBy: "-")
        let deviceLanguage = arr.first
        print ("deviceLanguage:- ", deviceLanguage) //en //deviceLanguage:-  Optional("ja")
        
        //daynamic Height Set
        self.tableView.estimatedRowHeight = 1 //Use less when recived data No 0 otherwise not set cell size default
        self.tableView.rowHeight = UITableView.automaticDimension

        setupVision()
    }
}

//#MARK:- UITableView DataSource & Delegate

extension ViewController {

    private func setupVision() {
        
        if #available(iOS 13.0, *) {
            
            let language_preference = ["ja-JP"]
            //let language_preference = ["en-US", "en-GB", "fr-FR","en-JP","ja-JP", "de-DE", "ru-RU"]
                  
            _textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
                       guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                       
                       var detectedText = ""
                       for observation in observations {
                           guard let topCandidate = observation.topCandidates(1).first else { return }
                           print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                        
                           detectedText += topCandidate.string
                           detectedText += "\n"
                        
                        self.wordlists.append(ReadItem.init(title: topCandidate.string))
                        
                       }
                       
                       DispatchQueue.main.async {
                            print("detectedText text:- ", detectedText)
                           //self.textView.text = detectedText
                           //self.textView.flashScrollIndicators()
                       
                        self.tableView.reloadData()
                        
                        //Loader
                        self.activityIndicatorView.stopAnimating()
                        self.activityIndicatorView.isHidden = true
                       }
                   }

            //Set Property
            textRecognitionRequest.recognitionLevel = .accurate  //[.fast, .accurate]
            textRecognitionRequest.recognitionLanguages = language_preference

            textRecognitionRequest.usesLanguageCorrection = true
           
            print("textRecognitionRequest.recognitionLanguages ", textRecognitionRequest.recognitionLanguages)
            print("textRecognitionRequest.usesLanguageCorrection ", textRecognitionRequest.usesLanguageCorrection)
            
            // current revision number of Vision
            let revision = VNRecognizeTextRequest.currentRevision
            var possibleLanguages: Array<String> = []

            do {
                possibleLanguages = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: revision)
            } catch {
                print("Error getting the supported languages.")
            }

            print("Possible languages for revision \(revision): \(possibleLanguages.joined(separator: "--"))")
            
            DispatchQueue.main.async {
            
                let images = ["Pawan_en.png","Pawan_de.png","Pawan_fr.png","Pawan_jp.png","Pawan_ru.png"]
                
                guard let image = UIImage(named: images[3]) else {
                    print("\(images[3]) file not available")
                    return
                }

                self.chooseImageView.image = image
                
                self.processImage(image)
            }
               
        } else {
            print("\(UIDevice.current.name) device with Version \(UIDevice.current.systemVersion) iOS not supported VNRecognizeTextRequest")
        }
    }
    
    
    private func processImage(_ image: UIImage) {
           //imageView.image = image
           recognizeTextInImage(image)
       }
       
       private func recognizeTextInImage(_ image: UIImage) {
           guard let cgImage = image.cgImage else { return }
           
        if #available(iOS 13.0, *) {
            
            //Loader
            self.activityIndicatorView.startAnimating()
            self.activityIndicatorView.isHidden = false
            
            self.wordlists.removeAll()
            self.wordlists = []
            
           //textView.text = ""
           textRecognitionWorkQueue.async {
               let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
               do {
                   try requestHandler.perform([self.textRecognitionRequest])
               } catch {
                   print(error)
               }
           }
        } else {
            print("\(UIDevice.current.name) device with Version \(UIDevice.current.systemVersion) iOS not supported VNRecognizeTextRequest")
        }
    }
}

//#MARK:- UITableView DataSource & Delegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
           return 1
    }
    //PK-New-Added
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.wordlists.count > 0 {
            return self.wordlists.count
        }
       return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier: String = "ReadCell"
        var cell : ReadCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? ReadCell
        if (cell == nil)
        {
            let nib: Array = Bundle.main.loadNibNamed(cellIdentifier, owner: self, options: nil)!
            cell = nib[0] as? ReadCell
        }
        
        let readItem: ReadItem  = self.wordlists[indexPath.row]
        
        //cell?.titleLabel.text? = NSLocalizedString(readItem.title, comment: "")
        cell?.titleLabel.text? = readItem.title
        
        //Cell Selection
        cell?.selectionStyle = .none
            
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let readItem: ReadItem  = self.wordlists[indexPath.row]
        print("readItem:- ", readItem)
    }
}
