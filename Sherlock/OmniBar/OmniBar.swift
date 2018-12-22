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
        set(colors: _sherlockGradientColors)
    }
    
    override func awakeFromNib() {
        self.searchField.delegate = self
        self.searchField.becomeFirstResponder()
    }
    
    // MARK: User Interface Actions
    @IBAction func settingsButtonPressed(_ sender: Any) {
        self.delegate?.omniBarButtonPressed(.settings)
    }
    
    @IBAction func historyButtonPressed(_ sender: Any) {
        self.delegate?.omniBarButtonPressed(.history)
    }
    
    func resignActive(){
        self.searchField.resignFirstResponder()
    }
}

extension OmniBar: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.omniBarSelected()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldInput = self.searchField.text else { return true}
        let newInput = NSString(string: oldInput).replacingCharacters(in: range, with: string)
        self.delegate?.inputChanged(input: newInput)
        if newInput.isEmpty {
            self.delegate?.inputCleared()
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.omnibarSubmitted()
        return true
    }
}

