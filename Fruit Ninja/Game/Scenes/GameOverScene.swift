//
//  GameOverScene.swift
//  Fruit Ninja
//
//  Created by Simranjeet Kaur on 26/03/24.
//

import SpriteKit
import AVKit

class GameOverScene: SKScene {
    
    var restartLbl: SKLabelNode!
    var totalScoreLbl: SKLabelNode!
    var gameOverSound: AVAudioPlayer!
    
    override func didMove(to view: SKView) {
        iniScene()
    }
    
    func iniScene() {
        createBackground()
        playGameOverSound()
        createRestartButton()
        createTotalScoreLbl()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        let objects = nodes(at: touchLocation)
        
        if objects.contains(restartLbl) {
            let scene = GameScene(size: CGSize(width: self.view!.bounds.width - 20, height: self.view!.bounds.height))
            scene.scaleMode = .aspectFill
            self.view!.presentScene(scene)
        }
    }
    
    func createBackground() {
        guard let viewFrame = view?.frame else {
            return
        }
        
        let background = SKSpriteNode(imageNamed: "gameOverBG")
        background.position = CGPoint(x: viewFrame.width / 2, y: viewFrame.height / 2)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
    }
    
    func playGameOverSound() {
        let path = Bundle.main.path(forResource: "gameover.caf", ofType: nil)
        let url = URL(fileURLWithPath: path!)
        let sound = try! AVAudioPlayer(contentsOf: url)
        gameOverSound = sound
        sound.play()
    }
    
    func createRestartButton() {
        restartLbl = SKLabelNode(fontNamed: "Inter")
        restartLbl.text = "Restart"
        restartLbl.horizontalAlignmentMode = .center
        restartLbl.fontSize = 50
        restartLbl.position = CGPoint(x: (self.view?.frame.width)! / 2, y: (self.view?.frame.width)! / 10)
        addChild(restartLbl)
    }
    
    func createTotalScoreLbl() {
        totalScoreLbl = SKLabelNode(fontNamed: "Inter")
        let score = UserDefaults.standard.value(forKey: "score")
        totalScoreLbl.text = "Total Score: \(score!)"
        totalScoreLbl.horizontalAlignmentMode = .center
        totalScoreLbl.fontSize = 30
        totalScoreLbl.position = CGPoint(x: (self.view?.frame.width)! / 2, y: (self.view?.frame.width)! / 20)
        addChild(totalScoreLbl)
    }
}
