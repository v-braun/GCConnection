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
    @IBOutlet weak var _cancelMatch: UIButton!
    
    
    @IBAction func connectTouched(_ sender: Any) {
        GCConnection.shared.authenticate()
    }
    
    @IBAction func findMatchTouched(_ sender: Any) {
        let match = try! GCConnection.shared.findMatch(minPlayers: 2, maxPlayers: 2, withTimeout: .now() + .seconds(15))
        
        match.handler = self
    }
    
    @IBAction func cancelMatchTouched(_ sender: Any) {
        GCConnection.shared.activeMatch?.cancel()
    }
    
    @IBAction func msgTxtPrimAction(_ sender: Any) {
        self.sendTouched(sender)
    }
    
    @IBAction func sendTouched(_ sender: Any) {
        let data = _msgTxt.text!.data(using: .utf8)
        try! GCConnection.shared.activeMatch!.broadCast(data: data!, withMode: GKMatch.SendDataMode.reliable)
        
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
        
        _cancelMatch.layer.cornerRadius = 5
        _cancelMatch.layer.borderColor = UIColor.white.cgColor
        _cancelMatch.layer.borderWidth = 1
        
        
        
        self.updateAuthUIStates()
        
        GCConnection.shared.authHandler = self
        
    }
    
    func updateAuthUIStates(){
        set(enable: false, onBtn: _sendBtn)
        set(enable: false, onBtn: _connectBtn)
        set(enable: false, onBtn: _findMatchBtn)
        set(enable: false, onBtn: _sendBtn)
        set(enable: false, onBtn: _cancelMatch)

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
        case .loginRequired:
            _statusLbl.text = "login required"
            set(enable: true, onBtn: _connectBtn)
            _connectBtn.titleLabel?.text = "show login view"
        case .ok:
            _statusLbl.text = "authenticated"
            set(enable: true, onBtn: _findMatchBtn)
        }
        
    }
    
    func updateMatchUIStates(state : MatchState){
        switch state {
        case .connected:
            var stat = "connected to match \n"
            let match = GCConnection.shared.activeMatch!
            for p in match.players {
                stat += "\(p.alias) \n"
            }
            _statusLbl.text = stat
            set(enable: true, onBtn: _sendBtn)
            set(enable: false, onBtn: _findMatchBtn)
            set(enable: true, onBtn: _cancelMatch)
            _msgTxt.isEnabled = true
        case .disconnected(let reason) where reason == .cancel:
            _statusLbl.text = "disconnected from match"
            set(enable: true, onBtn: _findMatchBtn)
            set(enable: false, onBtn: _cancelMatch)
        case .disconnected(let reason) where reason == .matchMakingTimeout:
            _statusLbl.text = "matchmaking timeout"
            set(enable: true, onBtn: _findMatchBtn)
            set(enable: false, onBtn: _cancelMatch)
        case .disconnected(let reason) where reason == .matchEmpty:
            _statusLbl.text = "no players in match"
            set(enable: true, onBtn: _findMatchBtn)
            set(enable: false, onBtn: _cancelMatch)
        case .disconnected(let reason) where reason == .error:
            _statusLbl.text = "disconnect because of an error"
        case .disconnected(let reason):
            _statusLbl.text = "unknown disconnect reason \(reason)"
        case .pending:
            _statusLbl.text = "pending match"
            set(enable: false, onBtn: _findMatchBtn)
            set(enable: true, onBtn: _cancelMatch)
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
        
        self.updateMatchUIStates(state: .disconnected(reason: .error))
        _statusLbl.text = "match err: \(error.localizedDescription)"
    }
    
    func handle(_ state: MatchState) {
        self.updateAuthUIStates()
        guard GCConnection.shared.authenticated else{
            return
        }
        
        self.updateMatchUIStates(state: state)
    }
    
    func handle(data: Data, fromPlayer: GKPlayer) {
        guard GCConnection.shared.authenticated else{
            return
        }
        
        self.updateMatchUIStates(state: GCConnection.shared.activeMatch!.state)
        
        let msg = String(data: data, encoding: .utf8)!
        _statusLbl.text = "\(fromPlayer.alias): \(msg)"
    }
    
    func handle(playerDisconnected: GKPlayer) {
        if let match = GCConnection.shared.activeMatch{
            self.updateMatchUIStates(state: match.state)
            _statusLbl.text = "disconnected: \(playerDisconnected.alias)"
        }
        
    }
    
}
