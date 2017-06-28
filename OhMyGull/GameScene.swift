//
//  GameScene.swift
//  OhMyGull
//
//  Created by Mukund Vemuri on 2017-06-13.
//  Copyright © 2017 Mukund Vemuri. All rights reserved.
//

import SpriteKit
import GameplayKit


func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Seagull: UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: added by MV
    
    let player = SKSpriteNode(imageNamed: "fighterJet")
    
    var seagullsDestroyed = 0
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        run(SKAction.playSoundFileNamed("laser_shot.caf", waitForCompletion: false))
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        let projectile = SKSpriteNode(imageNamed: "laser")
        
        
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width / 2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Seagull
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        let offset = touchLocation - projectile.position
        
        if(offset.x < 0) {
            return
        }
        
        let direction = offset.normalized()
        let distance = direction * 1000
        let destination = projectile.position + distance
        
        let angle = asin(offset.x/offset.length())
        projectile.zRotation = angle
        
        addChild(projectile)

        moveSpriteNode(name: projectile, to: destination, isRandom: false)
        
    }
    
    func moveSpriteNode(name node: SKSpriteNode, to: CGPoint, isRandom: Bool) {
        var actualDuration: CGFloat
        var actionMove: SKAction
        if(isRandom) {
            actualDuration = random(min: CGFloat(3.0), max: CGFloat(4.0))
        } else {
            actualDuration = CGFloat(4.0)
        }
        
        actionMove = SKAction.move(to: to, duration: TimeInterval(actualDuration))

        let actionMoveDone = SKAction.removeFromParent()
        
        node.run(SKAction.sequence([actionMove, actionMoveDone]))

    }
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background")
        addChild(background)
        background.position = CGPoint(x:self.size.width/2,y:self.size.height/2)
        background.lightingBitMask = 1
        background.size = CGSize(width: self.size.width, height: self.size.height)
        background.zPosition = -1
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.white
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addSeagull),
                SKAction.wait(forDuration: 1.0)
             ])
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background_CAF.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
    }
    
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    
    func addSeagull() {
        let number = arc4random_uniform(2)+1
        let imageName = String(format:"seagull_\(number)")
        let seagull = SKSpriteNode(imageNamed: imageName)
        
        
        seagull.physicsBody = SKPhysicsBody(rectangleOf: seagull.size)
        seagull.physicsBody?.isDynamic = true
        seagull.physicsBody?.categoryBitMask = PhysicsCategory.Seagull
        seagull.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        seagull.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        let actualY = random(min: seagull.size.height/2, max: size.height - seagull.size.height/2)
        
        seagull.position = CGPoint(x: size.width + seagull.size.width/2, y: actualY)

        addChild(seagull)
        
        moveSpriteNode(name: seagull, to: CGPoint(x: -seagull.size.width/2, y: actualY), isRandom: true)
        
    }
    
    
    func projectileDidCollideWithSeagull(projectile: SKSpriteNode, seagull: SKSpriteNode) {
        projectile.removeFromParent()
        seagull.removeFromParent()
        
        seagullsDestroyed += 1
        if(seagullsDestroyed > 10) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if((firstBody.categoryBitMask & PhysicsCategory.Seagull != 0) && (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)){
            if let seagull = firstBody.node as? SKSpriteNode, let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithSeagull(projectile: projectile, seagull: seagull)
            }
        }
    }
}
