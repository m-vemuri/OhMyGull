//
//  GameOverScene.swift
//  OhMyGull
//
//  Created by Mukund Vemuri on 2017-06-17.
//  Copyright © 2017 Mukund Vemuri. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameOverScene: SKScene {
    
    init(size: CGSize, won: Bool) {
        
        super.init(size: size)
        
        let background = SKSpriteNode(imageNamed: "background")
        addChild(background)
        background.position = CGPoint(x:self.size.width/2,y:self.size.height/2)
        background.lightingBitMask = 1
        background.size = CGSize(width: self.size.width, height: self.size.height)
        background.zPosition = -1

        
        let message = won ? "You Won!! ;)" : "You Lose :/"
        
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0), SKAction.run() {
                let reveal = SKTransition.flipHorizontal(withDuration: 3.0)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition: reveal)
            }]))
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
