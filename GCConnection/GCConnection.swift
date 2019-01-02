//
//  GCConnection.swift
//  GCConnection
//
//  Created by Viktor Braun on 02.01.2019.
//  Copyright © 2019 Viktor Braun - Software Development. All rights reserved.
//

import Foundation
import UIKit
import GameKit

public enum AuthStatus{
    case undef
    case ok(localPlayer : GKLocalPlayer)
    case loginRequired(viewController : UIViewController)
    case error(err : Error)
    case loginCancelled
}

public protocol AuthHandler{
    func handle(connection : GCConnection, authStatusChanged : AuthStatus)
}

public class GCConnection{
    
    private var _currentMatch : Match? = nil
    
    private static var _default = GCConnection()
    public static var shared : GCConnection{
        get{
            return ._default
        }
    }
    
    public var authHandler : AuthHandler?{
        didSet{
            DispatchQueue.main.async {
                self.authHandler?.handle(connection: self, authStatusChanged: self.authStatus)
            }
        }
    }
    
    public var authenticated : Bool{
        switch self.authStatus {
        case .ok( _):
            return true
        default:
            return false
        }
    }
    
    public var authStatus : AuthStatus = .undef
    
    public var activeMatch : Match?{
        get{
            guard let cm = _currentMatch else{
                return nil
            }
            
            if cm.state == .disconnected {
                _currentMatch = nil
            }
            
            return _currentMatch
        }
    }
    
    fileprivate func log(_ items : Any...){
        let itemString = items.map { String(describing: $0) }.joined(separator: " ")
        print(itemString)
    }
    
    public func authenticate(){
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { (controller, error) in
            
            if let error = error{
                if let gkErr = error as? GKError{
                    if gkErr.code == GKError.Code.cancelled {
                        self.authStatus = .loginCancelled
                    } else{
                        self.authStatus = .error(err: error)
                    }
                }
                else{
                    self.authStatus = .error(err: error)
                }
            }
            else if localPlayer.isAuthenticated{
                self.authStatus = .ok(localPlayer: localPlayer)
            }
            else if let controller = controller {
                self.authStatus = .loginRequired(viewController: controller)
            }
            else{
                self.authStatus = .undef
            }
            
            DispatchQueue.main.async {
                self.authHandler?.handle(connection: self, authStatusChanged: self.authStatus)
            }
            
        }
    }
    
    func findMatch(minPlayers: Int, maxPlayers: Int) throws -> Match{
        if activeMatch != nil {
            throw createError(withMessage: "there is already an active match")
        }
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let result = Match(rq: request, matchMaker: GKMatchmaker.shared())
        result.find()
        
        _currentMatch = result
        
        return result
    }
}

public enum MatchState{
    case pending
    case connected
    case disconnected
}
public protocol MatchHandler{
    func handle(_ error : Error)
    func handle(_ state : MatchState)
    func handle(data : Data, fromPlayer : GKPlayer)
}

public class Match : NSObject, GKMatchDelegate{
    fileprivate var _request : GKMatchRequest
    fileprivate var _matchMaker : GKMatchmaker
    fileprivate var _match : GKMatch?
    
    public var state : MatchState = .pending
    
    public var handler : MatchHandler?
    public var players : [GKPlayer] = []
    
    private func updateState(_ newState : MatchState){
        if newState == self.state{
            return
        }
        
        self.state = newState
        
        DispatchQueue.main.async {
            self.handler?.handle(self.state)
        }
    }
    
    private func error(_ err : Error){
        DispatchQueue.main.async {
            self.handler?.handle(err)
        }
        self.cancel()
    }
    
    init(rq : GKMatchRequest, matchMaker : GKMatchmaker){
        self._request = rq
        self._matchMaker = matchMaker
        super.init()
    }
    
    fileprivate func find() {
        
        self._matchMaker.findMatch(for: self._request) { (match, err) in
            if let err = err {
                self.error(err)
            }
            else if let match = match {
                self._match = match
                self._match!.delegate = self
            }
            else{
                self.error(createError(withMessage: "received unexpected nil match"))
            }
        }
    }
    
    fileprivate func initPlayers() {
        guard let match = self._match else{
            return
        }
        
        let playerIDs = match.players.map { $0.playerID }
        GKPlayer.loadPlayers(forIdentifiers: playerIDs) { (players, error) in
            if let error = error {
                self.error(error)
                return
            }
            
            guard let players = players else {
                self.error(createError(withMessage: "unexpected nil while retrieve player list"))
                return
            }
            
            self.players = players
            self.updateState(.connected)
            GKMatchmaker.shared().finishMatchmaking(for: match)
        }
    }
    
    
    public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState){
        guard self._match == match else {
            return
        }
        
        switch state {
        case .connected where self._match != nil && match.expectedPlayerCount == 0:
            initPlayers()
        case .disconnected:
            self.updateState(.disconnected)
        default:
            break
        }
    }
    
    public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        DispatchQueue.main.async {
            self.handler?.handle(data: data, fromPlayer: player)
        }
    }
    
    public func match(_ match: GKMatch, didFailWithError error: Error?) {
        guard self._match == match else {
            return
        }
        
        guard let error = error else{
            return
        }
        
        self.error(error)
    }
    
    public func broadCast(data : Data, withMode : GKMatch.SendDataMode) throws{
        guard self.state == .connected else{
            return
        }
        
        guard let match = self._match else {
            return
        }
        
        try match.sendData(toAllPlayers: data, with: withMode)
    }
    
    
    
    public func cancel(){
        self._matchMaker.cancel()
        if let match = self._match {
            self._match = nil
            match.disconnect()
        }
        
        self.updateState(.disconnected)
    }
    
}

fileprivate func createError(withMessage: String) -> Error{
    let err = NSError(domain: "GCConnection", code: 2, userInfo: [ NSLocalizedDescriptionKey: "received unexpected nil match"])
    return err
}
