//
//  GameScene.swift
//  Fruit Ninja
//
//  Created by Simranjeet Kaur on 20/03/24.
//

import SpriteKit

enum SequenceType: Int {
    case one
    case two
    case three
    case four
    case chain
    case fastChain
}

class GameScene: SKScene {
    
    // enemy spawning
    var spawnTime = 0.0
    var sequence: [SequenceType]!
    var sequenceIndex = 0
    var chainDelay = 3.0
    var nextSequencedQueued = true
    
    // touchpoints
    var activeSlicePoints = [CGPoint]()
    
    // slash mechanic
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    let sliceLength = 8
    var isSwooshSFXPlaying = false
    
    // gameplay
    var gameScore: SKLabelNode!
    var livesImages = [SKSpriteNode]()
    var livesRemaining = 3
    var gameEnded = false
    var score: Int = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
            UserDefaults.standard.set(score, forKey: "score")
        }
    }
    
    // enemies
    var actionEniemies = [SKSpriteNode]()
    
    let enemyVelocityScalar = 40
    
    var sprite: SKSpriteNode = SKSpriteNode()
    var startPoint: CGPoint = CGPoint.zero
    var endPoint: CGPoint = CGPoint.zero
    
    var fruits = ["strawberry", "banana", "mango", "apple", "pineapple", "watermelon"]
    
    override func didMove(to view: SKView) {
        self.initScene()
        
        sequence = [.one, .two, .three, .four, .chain, .fastChain]
        
        for _ in 0...1000 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 5))!
            sequence.append(nextSequence)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tossEnemies()
        }
    }
    
    override func update(_ curentTime: TimeInterval) {
        if actionEniemies.count > 0 {
            for enemy in actionEniemies {
                if enemy.position.y < -140 {
                    enemy.removeAllActions()
                    if let enemyName = enemy.name, fruits.contains(enemyName) {
                        enemy.name = ""
                        enemy.removeFromParent()
                        subtractLife()
                        
                        if let index = actionEniemies.index(of: enemy) {
                            actionEniemies.remove(at: index)
                        }
                    }
                }
            }
        }
        else {
            if !nextSequencedQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + spawnTime, execute: { [unowned self] in
                    self.tossEnemies()
                })
                nextSequencedQueued = true
            }
        }
    }
    
    func addFruit() {
        
        let fruit = SKSpriteNode(imageNamed: fruits.randomElement()!)
        // big size
        fruit.setScale(1.5)
        fruit.position = CGPoint(x: CGFloat.random(in: 0..<size.width), y: 400)
        fruit.physicsBody = SKPhysicsBody(rectangleOf: fruit.size)
        
        fruit.physicsBody?.isDynamic = true
        addChild(fruit)
        
        fruit.physicsBody?.velocity.dy = 100
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            fruit.physicsBody?.velocity.dy = 100
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        activeSlicePoints.append(touchLocation)
        
        // Bexier curve construction
        redrawActiveSlice()
        
        activeSliceBG.removeAllActions()
        activeSliceFG.removeAllActions()
        
        activeSliceBG.alpha = 1.0
        activeSliceFG.alpha = 1.0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard !gameEnded else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            let nodes = nodes(at: location)
            activeSlicePoints.append(location)
            
            // bezier curve construction
            redrawActiveSlice()
            
            if !isSwooshSFXPlaying { playSwooshSFX() }
            
            for node in nodes {
                if let nodeName = node.name, fruits.contains(nodeName) {
                    
                    // particles
                    let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")
                    emitter?.position = node.position
                    addChild(emitter!)
                    
                    //Prevent multiple swipes
                    node.name = ""
                    node.physicsBody?.isDynamic = false
                    
                    // Death Animation
                    let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.2)
                    let fadeOutAction = SKAction.fadeIn(withDuration: 0.2)
                    let actionGroup = [scaleOutAction, fadeOutAction]
                    let deathAction = SKAction.sequence(actionGroup)
                    node.run(deathAction)
                    
                    //Remove from Scene
                    let index = actionEniemies.index(of: node as! SKSpriteNode)
                    actionEniemies.remove(at: index!)
                    
                    score += 1
                    
                    // Death Sound
                    run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeIn(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeIn(withDuration: 0.25))
    }
}


extension GameScene {
    
    func initScene() {
        createBackground()
        setWorldProperties()
        createScore()
        createLives()
        createSlices()
    }
    
    func createBackground() {
        guard let viewFrame = view?.frame else { return }
        
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: viewFrame.width / 2, y: viewFrame.height / 2)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
    }
    
    func setWorldProperties() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
    }
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Inter")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 30
        gameScore.position = CGPoint(x: 30, y: 20)
        addChild(gameScore)
    }
    
    func createLives() {
        for index in 0..<3 {
            let lifeSprite = SKSpriteNode(imageNamed: "sliceLife")
            lifeSprite.position = CGPoint(x: 834 + (index * 70), y: 720)
            addChild(lifeSprite)
            
            livesImages.append(lifeSprite)
        }
    }
    
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        activeSliceBG.strokeColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.8)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        activeSliceFG.strokeColor = UIColor.red
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    func redrawActiveSlice() {
        // if not enough data -0 early out
        guard activeSlicePoints.count > 2 else { self.activeSliceFG.path = nil; self.activeSliceBG.path = nil;  return }
        
        while activeSlicePoints.count > sliceLength {
            // pop oldest points
            activeSlicePoints.remove(at: 0)
        }
        
        // Construct path
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for index in 1..<activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[index])
        }
        
        // Assign path
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
        
    }
    
    func subtractLife() {
        livesRemaining -= 1
        run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        switch livesRemaining {
        case 2:
            life = livesImages[0]
        case 1:
            life = livesImages[1]
        default:
            life = livesImages[2]
            endGame()
        }
        
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        life.xScale = 1.3
        life.yScale = 1.3
        life.run(SKAction.scale(by: 1.0, duration: 0.1))
    }
    
    func showfruit() {
        createFruit()
    }
    
    func createFruit() {
        let randomIndex = Int(arc4random_uniform(UInt32(fruits.count)))
        let imagename = fruits[randomIndex]
        
        let enemy = SKSpriteNode(imageNamed: imagename)
        enemy.name = imagename
        run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
        
        setOrientation(enemy: enemy)
        
        actionEniemies.append(enemy)
        addChild(enemy)
    }
    
    func setOrientation(enemy: SKSpriteNode) {
        // position
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        enemy.position = randomPosition
        
        // angular velocity
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        
        // linear velocity
        var randomLinearVelocity = 0
        if randomPosition.x < 256 {
            randomLinearVelocity = RandomInt(min: 8, max: 15)
        }
        else if randomPosition.x < 512 {
            randomLinearVelocity = RandomInt(min: 3, max: 5)
        }
        else if randomPosition.x < 756 {
            randomLinearVelocity = -RandomInt(min: 3, max: 5)
        }
        else {
            randomLinearVelocity = -RandomInt(min: 8, max: 15)
        }
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        // physics
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomLinearVelocity * enemyVelocityScalar, dy: randomYVelocity * enemyVelocityScalar)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0
    }
    
    func tossEnemies() {
        guard !gameEnded else { return }
        
        spawnTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequenceIndex]
        
        switch sequenceType {
        case .one:
            showfruit()
        case .two:
            showfruit()
            showfruit()
        case .three:
            showfruit()
            showfruit()
            showfruit()
        case .four:
            showfruit()
            showfruit()
            showfruit()
            showfruit()
        case .chain:
            showfruit()
            
            for index in 1...4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0) * Double(index) , execute: { [unowned self] in
                    self.showfruit()
                })
            }
        case .fastChain:
            showfruit()
            
            for index in 1...4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0) * Double(index) , execute: { [unowned self] in
                    self.showfruit()
                })
            }
        }
        sequenceIndex += 1
        nextSequencedQueued = false
    }
    
    func endGame() {
        guard !gameEnded else { return }
        
        gameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        UserDefaults.standard.set(score, forKey: "score")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            let scene = GameOverScene(size: CGSize(width: self.view!.bounds.width - 20, height: self.view!.bounds.height))
            scene.scaleMode = .aspectFill
            
            self.view!.presentScene(scene)
        })
    }
    
    func playSwooshSFX() {
        isSwooshSFXPlaying = !isSwooshSFXPlaying
        
        let randomIndex = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomIndex).caf"
        let playSwooshSFXAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        run(playSwooshSFXAction) { [unowned self] in
            self.isSwooshSFXPlaying = false
        }
    }
    
}

func RandomInt(min: Int, max: Int) -> Int {
    if max < min { return min }
    return Int(arc4random_uniform(UInt32((max - min) + 1))) + min
}
