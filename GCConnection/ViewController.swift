//
//  ViewController.swift
//  GCConnection
//
//  Created by Viktor Braun on 02.01.2019.
//  Copyright © 2019 Viktor Braun - Software Development. All rights reserved.
//

import UIKit
import GameKit

class ViewController: UIViewController{
    

    
    @IBOutlet weak var _statusLbl: UILabel!
    @IBOutlet weak var _connectBtn: UIButton!
    @IBOutlet weak var _findMatchBtn: UIButton!
    @IBOutlet weak var _msgTxt: UITextField!
    @IBOutlet weak var _sendBtn: UIButton!
    
    
    @IBAction func connectTouched(_ sender: Any) {
        GCConnection.shared.authenticate()
    }
    @IBAction func findMatchTouched(_ sender: Any) {
    }
    
    
    @IBAction func msgTxtPrimAction(_ sender: Any) {
    }
    @IBAction func sendTouched(_ sender: Any) {
    }
    
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        _statusLbl.text = "..."
        
        _sendBtn.layer.cornerRadius = 5
        _sendBtn.layer.borderColor = UIColor.white.cgColor
        _sendBtn.layer.borderWidth = 1
        
        _connectBtn.layer.cornerRadius = 5
        _connectBtn.layer.borderColor = UIColor.white.cgColor
        _connectBtn.layer.borderWidth = 1
        
        _findMatchBtn.layer.cornerRadius = 5
        _findMatchBtn.layer.borderColor = UIColor.white.cgColor
        _findMatchBtn.layer.borderWidth = 1
        
        self.updateAuthUIStates()
        
        GCConnection.shared.authHandler = self
    }
    
    func updateAuthUIStates(){
        set(enable: false, onBtn: _sendBtn)
        set(enable: false, onBtn: _connectBtn)
        set(enable: false, onBtn: _findMatchBtn)
        set(enable: false, onBtn: _sendBtn)

        _msgTxt.isEnabled = false;
        _statusLbl.text = ""
        
        switch GCConnection.shared.authStatus {
        case .undef:
            _statusLbl.text = "not authenticated"
            set(enable: true, onBtn: _connectBtn)
        case .loginCancelled:
            _statusLbl.text = "login canccelled"
            set(enable: true, onBtn: _connectBtn)
        case .error(let err):
            _statusLbl.text = "auth err: \(err.localizedDescription)"
            set(enable: true, onBtn: _connectBtn)
        case .loginRequired(let viewController):
            _statusLbl.text = "login required"
            set(enable: true, onBtn: _connectBtn)
            _connectBtn.titleLabel?.text = "show login view"
        case .ok(let localPlayer):
            _statusLbl.text = "authenticated"
        }
        
    }
    
    func updateMatchUIStates(){
        set(enable: false, onBtn: _sendBtn)
        set(enable: false, onBtn: _connectBtn)
        set(enable: false, onBtn: _findMatchBtn)
        set(enable: false, onBtn: _sendBtn)
        
        _msgTxt.isEnabled = false;
        _statusLbl.text = ""
        
        switch GCConnection.shared.authStatus {
        case .undef:
            _statusLbl.text = "not authenticated"
            set(enable: true, onBtn: _connectBtn)
        case .loginCancelled:
            _statusLbl.text = "login canccelled"
            set(enable: true, onBtn: _connectBtn)
        case .error(let err):
            _statusLbl.text = "auth err: \(err.localizedDescription)"
            set(enable: true, onBtn: _connectBtn)
        case .loginRequired(let viewController):
            _statusLbl.text = "login required"
            set(enable: true, onBtn: _connectBtn)
            _connectBtn.titleLabel?.text = "show login view"
        case .ok(let localPlayer):
            _statusLbl.text = "authenticated"
            set(enable: true, onBtn: _findMatchBtn)
        }
        
    }

    func set(enable: Bool, onBtn : UIButton){
        onBtn.isEnabled = enable
        if enable{
            onBtn.setTitleColor(UIColor.white, for: .normal)
            onBtn.layer.borderColor = UIColor.white.cgColor
        }
        else{
            onBtn.setTitleColor(UIColor.lightGray, for: .normal)
            onBtn.layer.borderColor = UIColor.lightGray.cgColor
        }
    }

    
    

}



extension ViewController : AuthHandler{
    func handle(connection: GCConnection, authStatusChanged: AuthStatus) {
        self.updateAuthUIStates()
    }
}

extension ViewController : MatchHandler{
    func handle(_ error: Error) {
        self.updateAuthUIStates()
        guard GCConnection.shared.authenticated else{
            return
        }
    }
    
    func handle(_ state: MatchState) {
        guard GCConnection.shared.authenticated else{
            return
        }
    }
    
    func handle(data: Data, fromPlayer: GKPlayer) {
        guard GCConnection.shared.authenticated else{
            return
        }
        
        
        
    }
    
    
}
