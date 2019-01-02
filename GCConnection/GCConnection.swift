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
            
            switch cm.state {
            case .disconnected(_):
                _currentMatch = nil
                return _currentMatch
            default:
                // none
                return _currentMatch
            }
            
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
        let defaultTimeout : DispatchTime = .now() + .seconds(60)
        let result = try findMatch(minPlayers: minPlayers, maxPlayers: maxPlayers, withTimeout: defaultTimeout )
        
        return result
    }
    
    func findMatch(minPlayers: Int, maxPlayers: Int, withTimeout : DispatchTime) throws -> Match{
        if activeMatch != nil {
            throw createError(withMessage: "there is already an active match")
        }
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let result = Match(rq: request, matchMaker: GKMatchmaker.shared())
        result.find(timeout: withTimeout)
        
        _currentMatch = result
        
        return result
    }
}
public enum DisconnectedReason{
    case matchEmpty
    case matchMakingTimeout
    case cancel
    case error
}
public enum MatchState{
    case pending
    case connected
    case disconnected(reason : DisconnectedReason)
}
public protocol MatchHandler{
    func handle(_ error : Error)
    func handle(_ state : MatchState)
    func handle(data : Data, fromPlayer : GKPlayer)
    func handle(playerDisconnected : GKPlayer)
}

public class Match : NSObject, GKMatchDelegate{
    fileprivate var _request : GKMatchRequest
    fileprivate var _matchMaker : GKMatchmaker
    fileprivate var _match : GKMatch?
    
    public var state : MatchState = .pending
    
    public var handler : MatchHandler? {
        didSet{
            DispatchQueue.main.async {
                self.handler?.handle(self.state)
            }
        }
    }
    
    public var players : [GKPlayer] {
        get{
            guard let p = self._match?.players else {
                return []
            }
            
            return p
        }
    }
    
    private func updateState(_ newState : MatchState){
        self.state = newState
        DispatchQueue.main.async {
            self.handler?.handle(self.state)
        }
    }
    
    private func error(_ err : Error){
        if err is GKError && (err as! GKError).code == GKError.Code.cancelled{
            return
        }
        
        DispatchQueue.main.async {
            self.handler?.handle(err)
        }
        self.cancelInternal(reason: .error)
    }
    
    init(rq : GKMatchRequest, matchMaker : GKMatchmaker){
        self._request = rq
        self._matchMaker = matchMaker
        super.init()
    }
    
    fileprivate func find(timeout : DispatchTime) {
        DispatchQueue.main.asyncAfter(deadline: timeout, execute: {
            switch self.state{
                case .pending:
                    self.cancelInternal(reason: .matchMakingTimeout)
                default:
                return
            }
            
            
            
        })
        
        self.state = .pending
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
            DispatchQueue.main.async {
                self.handler?.handle(playerDisconnected: player)
            }
            
            if match.players.count == 0{
                self.cancelInternal(reason: .matchEmpty)
            }
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
        guard let match = self._match else {
            return
        }
        
        switch self.state {
        case .connected:
            try match.sendData(toAllPlayers: data, with: withMode)
        default:
            return
        }
    
        
    }
    
    
    private func cancelInternal(reason : DisconnectedReason){
        self._matchMaker.cancel()
        if let match = self._match {
            self._match = nil
            match.disconnect()
        }
        
        self.updateState(.disconnected(reason: reason))
    }
    
    public func cancel(){
        cancelInternal(reason: .cancel)
    }
    
}

fileprivate func createError(withMessage: String) -> Error{
    let err = NSError(domain: "GCConnection", code: 2, userInfo: [ NSLocalizedDescriptionKey: "received unexpected nil match"])
    return err
}
