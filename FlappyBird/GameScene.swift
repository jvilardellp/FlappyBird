//
//  GameScene.swift
//  FlappyBird
//
//  Created by Jaume Vilardell Pons on 04/02/2020.
//  Copyright © 2020 jvp. All rights reserved.
//
//  CREDITS:
//          fullstackio/FlappySwift (flappy example)
//          jotajotavm: http://goo.gl/ZPioOq (games tutorial)
//          https://patrickdearteaga.com/es/musica-libre-derechos-gratis/ (sound effects and music)
//

import SpriteKit // Class for the graphics
import AVFoundation // Class for the sound effects and the music

// SKScene -> Graphics
// SKPhysicsContactDelegate -> Collisions
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // OBJECTS
    private var skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    private var bird = SKSpriteNode()
    private let skyTexture = SKTexture(imageNamed: "Sky")
    private let groundTexture = SKTexture(imageNamed: "Ground")
    private var birdFlyingFrames: [SKTexture] = []
    private let pipeTextureDown = SKTexture(imageNamed: "Pipe_Down")
    private let pipeTextureUp = SKTexture(imageNamed: "Pipe_Up")
    private var verticalPipeGap = 180.0
    private var movePipesAndRemove:SKAction!
    private var moving:SKNode! // This node has all the objects (bird, pipes and ground) in movement
    private var pipes:SKNode! // This node has all the pipes (up and down) in the movement
    
    // Collision category
    private let birdCategory: UInt32 = 1 << 0
    private let worldCategory: UInt32 = 1 << 1
    private let pipeCategory: UInt32 = 1 << 2
    private let scoreCategory: UInt32 = 1 << 3
    
    // Reset for the play
    private var reset = Bool()
    
    // Score
    private var scoreLabelNode:SKLabelNode!
    private var score = NSInteger()
    
    // Sound effects
    private var crash: AVAudioPlayer?
    
    // Game music
    private var music: AVAudioPlayer?
    
    // Setup the scene when the game start
    override func didMove(to view: SKView) {
        // VARIABLES
        // Reset condition
        reset = false
        
        // Setup physics conditions
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        // This class control the collision
        self.physicsWorld.contactDelegate = self
        
        // Node with the objects in movement
        moving = SKNode()
        self.addChild(moving) // Movement the bird, pipes and ground limit
        pipes = SKNode()
        moving.addChild(pipes)
        
        // BACKGROUND (sky and ground)
        buildSKY()
        buildGROUND()
        paintingBackground()
        buildGroundLimit()
        
        
        // BIRD
        // Creating the Bird
        buildBIRD()
        // Animating the Bird
        animateBird()
        
        
        //PIPES
        // Creating the pipes (Up & Down set) and the movement
        buildPIPES()
        
        //STONES
        // Adding the stones to the game
        buildSTONES()
                
        
        // TITLE
        titleFlappyBird()
        
        
        // SCORE
        showingScore()
        
        
        // MUSIC
        playMusic()
    }
    
    // FUNCTIONS OF THE GAME SCENE CLASS
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // The bird can move if the app has movement (the bird has not contact with the pipes or the ground limit
        if moving.speed > 0 {
            // Moving the bird using the touch function of the screen
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0) // Speed in the coordinates x and y
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 6)) // Ascendent impulse
        } else if reset {
            self.resetScene()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Rotating the bird during the movement. This functions is called before each frame be rendered
        let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    
    //
    // USER FUNCTIONS.
    //
    
    // SKY
    // Creating the sky
    func buildSKY() {
        // Variables
        skyTexture.filteringMode = .nearest
        
        // Variables to move the sky
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width, y: 0, duration: TimeInterval(0.05 * skyTexture.size().width))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        // Loop to draw the sky as times as required to fill out the screen
        for i in 0 ..< 2 + Int(self.frame.size.width / (skyTexture.size().width)) {
            // Variables
            let i = CGFloat(i) // Counter
            let skySprite = SKSpriteNode(texture: skyTexture) // Creating the sprite
            let positionX = self.frame.minX + (i * skySprite.size.width) // Positioning in the beginning of the X coordinate
            let positionY = self.frame.midY // Positioning in the middle of the screen
            
            // Sprite setup
            skySprite.setScale(1.0)
            skySprite.zPosition = -60
            skySprite.position = CGPoint(x: positionX, y: positionY)
            
            // Moving the sky
            skySprite.run(moveSkySpritesForever)
            
            // Adding the sky sprite to the screen background
            moving.addChild(skySprite)
        }
    }

    // GROUND
    // Creating the ground
    func buildGROUND() {
        // Variables
        // Define the ground texture
        groundTexture.filteringMode = .nearest
            
        // Variables to move the ground
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: TimeInterval(0.01 * groundTexture.size().width))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        
        // Loop to draw the sky as times as required to fill out the screen
        for i in 0 ..< 2 + Int(self.frame.size.width / (groundTexture.size().width)) {
            // Variables
            let i = CGFloat(i) // Counter
            let groundSprite = SKSpriteNode(texture: groundTexture) // Creating the sprite -> ground
            let skySprite = SKSpriteNode(texture: skyTexture) // Creating the sprite -> sky
            let positionX = self.frame.minX + (i * groundSprite.size.width) // Positioning in the beginning of the X coordinate
            let positionY = self.frame.midY - (skySprite.size.height / 2) // Positioning below the sky
                
            // Sprite setup
            groundSprite.setScale(1.0)
            groundSprite.zPosition = -30
            groundSprite.position = CGPoint(x: positionX, y: positionY)
            
            // Moving the ground
            groundSprite.run(moveGroundSpritesForever)
                
            // Adding the ground sprite to the screen background
            moving.addChild(groundSprite)
        }
    }
    
    // BACKGROUND
    // Painting the background with the sky color
    func paintingBackground() {
        self.backgroundColor = skyColor
    }
    
    // Limit of the ground used to stop the bird when fall down
    func buildGroundLimit() {
        // VARIABLE
        // Creating the ground limit
        let groundLimit = SKNode()
        // Creating the sky to used to calculate the position of the ground limit
        let skySprite = SKSpriteNode(texture: skyTexture)
        
        // SETUP
        // Position
        groundLimit.position = CGPoint(x: self.frame.minX, y: self.frame.midY - (skySprite.size.height / 2))
        // Physical proprieties
        groundLimit.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height))
        // Action among the objects
        groundLimit.physicsBody?.isDynamic = false // False -> The object cannot be in the same place.
        
        // Collision category
        groundLimit.physicsBody?.categoryBitMask = worldCategory
        
        // Adding the ground limit to the screen. This limit is used to stop the bird when it fall down.
        self.addChild(groundLimit)
    }

    
    // BIRD
    // Creating the bird object
    func buildBIRD() {
        // Creating the textures array for the bird
        // Indicating the the origin of the images
        let birdAnimatedAtlas = SKTextureAtlas(named: "BirdImages")
        // Texture array
        var flyFrames: [SKTexture] = []
        // Number of images
        let numImages = birdAnimatedAtlas.textureNames.count
      
        // Adding the images to the array
        for i in 1...numImages {
            let birdTextureName = "Bird\(i)"
            flyFrames.append(birdAnimatedAtlas.textureNamed(birdTextureName))
        }
        
        // Coping array
        birdFlyingFrames = flyFrames
        
        // Positioning the bird in the screen
        let firstFrameTexture = birdFlyingFrames[0]
        bird = SKSpriteNode(texture: firstFrameTexture)
        bird.position = CGPoint(x: (self.frame.size.width / -5.0), y: self.frame.midY + 300)
        
        // Physical proprieties for the bird
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0) // The bird is defined as circle.
        bird.physicsBody?.isDynamic = true // Two objects cannot be in the same place, the objects crash when try to be in the same place
        bird.physicsBody?.allowsRotation = false // The bird cannot rotate.
        
        // Controlling the collision between the bird with the tubes and the ground
        bird.physicsBody?.categoryBitMask = birdCategory // Category of the bird
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory // Indicating the collision objects. The bird can collision with the ground and the tubes
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory // Testing the collisions
        
        // Adding the bird object in the screen
        addChild(bird)
    }
    
    // Animating the bird
    func animateBird() {
        // Animating the bird.
        bird.run(SKAction.repeatForever(SKAction.animate(with: birdFlyingFrames, timePerFrame: 0.15, resize: false, restore: true)),
            withKey:"flyingBird")
    }
    
    // PIPES
    // Creating the pipes object
    func buildPIPES() {
        // Define thew pipes image
        pipeTextureDown.filteringMode = .nearest
        pipeTextureUp.filteringMode = .nearest
        
        // Create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + pipeTextureUp.size().width * 2)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // Spawn the pipes
        let spawn = SKAction.run(spawnTubes)
        let delay = SKAction.wait(forDuration: TimeInterval(4.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
    }
    
    // Spawn the pipes (generating the pipe set)
    func spawnTubes() {
        // Pipe set
        let pipePair = SKNode() // Pipes set
        pipePair.position = CGPoint( x: (self.frame.size.width / 2) + pipeTextureDown.size().width * 2, y: 0 )
        pipePair.zPosition = -50 // Z Level
         
        
        // DOWN PIPE
        // Calculating the height to put the pipe
        let height = UInt32( self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height)
         
        // Pipe position
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(1.0)
        pipeDown.position = CGPoint(x: 0.0, y: y - Double(pipeDown.size.height))
         
        // Adding the physical properties
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        
        // Category collision
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
         
        // Adding the pipe down to the pipes set
        pipePair.addChild(pipeDown)
         
         
        // UP PIPE
        // Pipe position
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(1.0)
        pipeUp.position = CGPoint(x: 0.0, y: y + verticalPipeGap)
         
        // Adding the physical properties
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        
        // Collision category
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory

        // Adding the pipe down to the pipes set
        pipePair.addChild(pipeUp)
        
        // Not visible object used to increase the score. It is placed in gap between the pipes
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        // Moving the tubes
        pipePair.run(movePipesAndRemove)
                
        // Adding the pipes set to the screen
        pipes.addChild(pipePair)
    }
    
    
    // TITLE
    // Adding the title of the game
    func titleFlappyBird() {
        // Variables
        // Title
        var title = SKSpriteNode()
        let image = UIImage(named: "Flappy_Bird")
        let texture = SKTexture(image: image!)
        
        title = SKSpriteNode(texture: texture)
        title.setScale(1.0)
        title.position = CGPoint(x: self.frame.midX, y: self.frame.midY + (self.frame.minY) / 1.5)
        title.zPosition = -10
        
        addChild(title)
    }
    
    
    // STONES
    // Adding the stones of the game
    func buildSTONES() {
        // Variables
        // Title
        var stones = SKSpriteNode()
        let image = UIImage(named: "Stones")
        let texture = SKTexture(image: image!)
        
        stones = SKSpriteNode(texture: texture)
        stones.setScale(2.0)
        stones.position = CGPoint(x: self.frame.midX, y: self.frame.midY - (skyTexture.size().height) * 1.34)
        stones.zPosition = -40
        
        addChild(stones)
    }
    
    
    // SCORE
    // Showing the score of the player
    func showingScore() {
        // Initialize label and create a label which holds the score
         score = 0
         scoreLabelNode = SKLabelNode(fontNamed:"Arial")
         scoreLabelNode.position = CGPoint( x: self.frame.midX, y: self.frame.maxY - 200)
         scoreLabelNode.alpha = 0.6
         scoreLabelNode.zPosition = 0
         scoreLabelNode.fontSize = 100
         scoreLabelNode.text = String(score)
         self.addChild(scoreLabelNode)
    }
    
    
    // MUSIC
    // Crash sound for the bird
    func playMusic (){
        // Load the file
        let path = Bundle.main.path(forResource: "GameOver.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)

        // TRY-CATCH to play the sound
        do {
            crash = try AVAudioPlayer(contentsOf: url)
            crash?.play()
            crash?.numberOfLoops = -1
            
        } catch {
            // Couldn't load file :(
        }
    }
        
    // END USER FUNCTIONS
    
    
    // EXTRA FUNCTIONS
    
    // COLLISION USED BY SKPhysicsContactDelegate
    // Function for the collision
    func didBegin(_ contact: SKPhysicsContact) {
        // Checking if the app has movement and there is contact
        if moving.speed > 0 {
            // Checking if the bird save the pipe and increase the score
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
                
                // Reducing the gap between pipes to increase the difficulty of the game
                if verticalPipeGap > 120 {
                    verticalPipeGap -= 2
                }
            } else {
                // Stop the music
                crash?.stop()
                
                // Play sound crash
                playSound()
                
                // Stopping the movement
                moving.speed = 0
               
                // Set of actions when the game finishes
                // Change the sky to red
                let skyRed = SKAction.run(skyRedColor)
                // Reset the game
                let resetGame = SKAction.run(gameOver)
                
                // Actions to do
                let setGameOver = SKAction.group([skyRed, resetGame])
                self.run(setGameOver)
            }
        }

    }
    
    
    // Change the status of the game to game over
    func gameOver() {
        reset = true
    }
    
    // Painting the sky in red. Used when the bird contact with the pipes or the ground limit
    func skyRedColor() {
        self.backgroundColor = UIColor.red
    }
    
    // Reset of the game. Changing to the initial status
    func resetScene() {
        // Set the values of the object in the initiating status
        // Sky color
        self.backgroundColor = skyColor
        
        // Bird
        // Move bird to original position and reset velocity
        bird.position = CGPoint(x: (self.frame.size.width / -5.0), y: self.frame.midY + 300)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Change the reset variable a false
        reset = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Reset the gap to the original size
        verticalPipeGap = 180
        
        // Change the speed of the game
        moving.speed = 1
        
        // Removing all the tubes
        pipes.removeAllChildren()
        
        // Reset the game music
        playMusic()
    }
    
    
    // Crash sound for the bird
    func playSound (){
        // Load the file
        let path = Bundle.main.path(forResource: "BirdCrash.wav", ofType:nil)!
        let url = URL(fileURLWithPath: path)

        // TRY-CATCH to play the sound
        do {
            crash = try AVAudioPlayer(contentsOf: url)
            crash?.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    // END EXTRA FUNCTIONS
}
