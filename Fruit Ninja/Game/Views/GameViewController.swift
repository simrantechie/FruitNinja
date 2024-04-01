//
//  GameViewController.swift
//  Fruit Ninja
//
//  Created by Simranjeet Kaur on 19/03/24.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = GameScene(size: CGSize(width: view.bounds.width - 20, height: view.bounds.height))
        scene.scaleMode = .aspectFill

        let skView = SKView(frame: view.frame)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        skView.ignoresSiblingOrder = true

        skView.presentScene(scene)
        view.addSubview(skView)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        }
        else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


}

