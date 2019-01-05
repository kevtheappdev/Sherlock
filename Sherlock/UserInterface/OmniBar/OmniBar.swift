//
//  OmniBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class OmniBar: UIGradientView {

    @IBOutlet weak var searchField: UITextField!
    weak var delegate: OmniBarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        set(colors: ApplicationConstants._sherlockGradientColors)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        searchField.delegate = self
        searchField.becomeFirstResponder()
    }
    
    // MARK: User Interface Actions
    @IBAction func settingsButtonPressed(_ sender: Any) {
        delegate?.omniBarButtonPressed(.settings)
    }
    
    @IBAction func historyButtonPressed(_ sender: Any) {
        delegate?.omniBarButtonPressed(.history)
    }
    
    func resignActive(){
        searchField.resignFirstResponder()
    }
}

extension OmniBar: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.omniBarSelected()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldInput = searchField.text else { return true}
        let newInput = NSString(string: oldInput).replacingCharacters(in: range, with: string)
        delegate?.inputChanged(input: newInput)
        if newInput.isEmpty {
            delegate?.inputCleared()
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.inputCleared()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.omnibarSubmitted()
        return true
    }
}

