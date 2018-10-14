//
//  Position.swift
//  FlexQueryLayout
//
//  Created by Joshua Beacom on 10/14/18.
//  Copyright © 2018 Joshua Beacom. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController, XMLParserDelegate {

    let contentCellIdentifier = "ContentCellIdentifier"
    var positions: [Position] = []
    var errorCode: String = ""
    var errorMessage: String = ""
    var currentParsingElement:String = ""
    var referenceCode = ""
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: "ContentCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: contentCellIdentifier)
        
        getXMLDataFromServer()
        NSLog("Read XML, reloading collection view")
        self.collectionView?.reloadData()
    }
    
    //MARK:- Custom methods
    func getXMLDataFromServer(){

        // Add token and queryID here
        
        let token : String = ""
        let queryId : String = ""
        
        // https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=TOKEN&q=QUERY_ID&v=3
        
        guard let initURL  = NSURL(string: "https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=" + token + "&q=" + queryId + "&v=3")
            else {
                NSLog("initURL could not be created")
                return
        }
        
        NSLog("initURL is: \(initURL.absoluteString!)")
        
        synchronousDataTask(with: initURL as URL)
        
        if referenceCode.isEmpty {
            NSLog("1 sec pause to wait for reference code")
            sleep(1)
        }
        
        if referenceCode.isEmpty {
            NSLog("ReferenceCode not received")
            referenceCode = "3261443368"
        }
        else {NSLog("ReferenceCode: \(referenceCode)")}
        
        // https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.GetStatement?q=REFERENCE_CODE&t=TOKEN&v=VERSION
        
        guard let url = NSURL(string: "https://gdcdyn.interactivebrokers.com/Universal/servlet/FlexStatementService.GetStatement?q=" + referenceCode + "&t=" + token + "&v=3")
            else {
                NSLog("GetStatement URL could not be created")
                return
        }
        
        NSLog("1 sec pause to allow statement generation")
        sleep(1)
        
        NSLog("GetStatement URL: \(url.absoluteString!)")
        
        synchronousDataTask(with: url as URL)
        
    }
    
    func synchronousDataTask(with url: URL) {
        var data: Data?
        var error: Error?
            
        let semaphore = DispatchSemaphore(value: 0)
            
        let dataTask = URLSession.shared.dataTask(with: url) {
            data = $0
            error = $2
                
            semaphore.signal()
        }
        dataTask.resume()
            
        _ = semaphore.wait(timeout: .distantFuture)
        
        if data == nil {
            print("dataTaskWithRequest error: \(String(describing: error?.localizedDescription))")
            return
        }
        
        let parser = XMLParser(data: data!)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentParsingElement = elementName
        
        if currentParsingElement == "NetStockPosition" {
            
            let position = Position()
            
            for (key,value) in attributeDict {
                //NSLog("key, \(key): value, \(value)")
                if (key == "conid") {position.conid = value}
                if (key == "netShares") {position.netShares = value}
                if (key == "symbol") {position.symbol = value}
                if (key == "description") {position.desc = value}
            }
            positions.append(position)
            
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundedChar = string.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
    
        if (!foundedChar.isEmpty) {
            if currentParsingElement == "ErrorMessage" {
                errorMessage = foundedChar
                NSLog("ErrorMessage: \(errorMessage)")
            }
            else if (currentParsingElement == "ErrorCode") {
                errorCode = foundedChar
                NSLog("ErrorCode: \(errorCode)")
            }
            else if (currentParsingElement == "ReferenceCode") {
                referenceCode = foundedChar
                NSLog("ReferenceCode: \(referenceCode)")
            }
        }
    }
    
    /* func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "ErrorCode" {
            print("Ended parsing...")
        }
    } */
    
    /* func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            // Update UI
            //self.displayOnUI()
        }
    } */
}

// MARK: - UICollectionViewDataSource
extension CollectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Two rows if there is an error condition
        let ns : Int = (errorCode.isEmpty) ? positions.count : 2
        NSLog("returning numberofSections: \(ns)")
        return ns
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: contentCellIdentifier,
                                                      for: indexPath) as! ContentCollectionViewCell

        if indexPath.section % 2 != 0 {
            cell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.white
        }

        // If there is an error display on two rows with code and message
        if (!errorCode.isEmpty) {
            //NSLog("ErrorCode: plotting a cell")
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.contentLabel.text = "ErrorCode"
                }
                else if indexPath.row == 1 {
                    cell.contentLabel.text = errorCode
                }
            }
            else if indexPath.section == 1 {
                if indexPath.row == 0 {
                    cell.contentLabel.text = "ErrorMessage"
                }
                else if indexPath.row == 1 {
                    cell.contentLabel.text = errorMessage
                }
            }
            else {
                NSLog("Error condition for cell with no content")
                cell.contentLabel.text = ""
            }
        } else {
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.contentLabel.text = "Symbol"
                } else if indexPath.row == 1 {
                    cell.contentLabel.text = "Desc"
                } else if indexPath.row == 2 {
                    cell.contentLabel.text = "ConId"
                } else if indexPath.row == 3 {
                    cell.contentLabel.text = "Shares"
                } else {
                    cell.contentLabel.text = ""
                }
            } else {
                if (indexPath.section < positions.count && indexPath.row < 4){
                    //NSLog("indexPath.row: \(indexPath.section), positions.count: \(positions.count)")

                    if indexPath.row == 0 {
                        cell.contentLabel.text = positions[indexPath.section].symbol
                    } else if indexPath.row == 1 {
                        cell.contentLabel.text = positions[indexPath.section].desc
                    } else if indexPath.row == 2 {
                        cell.contentLabel.text = positions[indexPath.section].conid
                    } else if indexPath.row == 3 {
                        cell.contentLabel.text = positions[indexPath.section].netShares
                    }
                }
                else {
                        cell.contentLabel.text = ""
                }
            }
        }
    
        return cell
    }

}

// MARK: - UICollectionViewDelegate
extension CollectionViewController: UICollectionViewDelegate {
}
