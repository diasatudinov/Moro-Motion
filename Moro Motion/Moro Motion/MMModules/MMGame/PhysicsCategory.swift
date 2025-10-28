import SwiftUI
import SpriteKit

#Preview {
    MMGameView()
}
//===============================================
final class HUDModel: ObservableObject {
    @Published var ammoLeft: Int = 0
    @Published var ammoTotal: Int = 0
    @Published var enemiesLeft: Int = 0
    @Published var enemiesTotal: Int = 0

    init() {
        NotificationCenter.default.addObserver(forName: .hudUpdate, object: nil, queue: .main) { [weak self] n in
            guard let u = n.userInfo as? [String: Any] else { return }
            self?.ammoLeft     = u["ammoLeft"] as? Int ?? 0
            self?.ammoTotal    = u["ammoTotal"] as? Int ?? 0
            self?.enemiesLeft  = u["enemiesLeft"] as? Int ?? 0
            self?.enemiesTotal = u["enemiesTotal"] as? Int ?? 0
        }
    }
}


enum Outcome {
    case win, lose
}

struct MMGameView: View {
    @StateObject private var hud = HUDModel()
        @State private var scene = GameScene()   // одна сцена на всё время
        @State private var outcome: Outcome? = nil
    @Environment(\.presentationMode) var presentationMode

        var body: some View {
            ZStack {
                Image(.gameBgMM)
                    .resizable()
                    .ignoresSafeArea()

                TransparentSpriteView(scene: scene)
                    .ignoresSafeArea()

                // HUD
                VStack {
                    HStack {
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()

                        } label: {
                            Image(.backIconMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 55)
                        }
                        
                        Button {
                            outcome = nil
                            NotificationCenter.default.post(name: .resetScene, object: nil)
                        } label: {
                            Image(.restartBtnMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 55)
                        }
                        Spacer()
                        
                        ZStack {
                            Image(.grenadeBgMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 55)
                            Text("\(hud.ammoLeft)/\(hud.ammoTotal)")
                                .bold()
                                .padding(.leading, 20)
                        }
                        
                    }
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer()

                    
                }

                // RESULT OVERLAY
                if let outcome {
                    resultOverlay(outcome: outcome)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: outcome != nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .levelWon)) { _ in
                outcome = .win
            }
            .onReceive(NotificationCenter.default.publisher(for: .levelLost)) { _ in
                outcome = .lose
            }
        }

        @ViewBuilder
        private func resultOverlay(outcome: Outcome) -> some View {
            VStack(spacing: 16) {
                Text(outcome == .win ? "Победа! 🎉" : "Поражение 😵")
                    .font(.system(size: 44, weight: .bold))
                HStack(spacing: 24) {
                    Label("Гранаты: \(hud.ammoLeft)/\(hud.ammoTotal)", systemImage: "bolt.circle")
                    Label("Враги: \(hud.enemiesLeft)/\(hud.enemiesTotal)", systemImage: "target")
                }
                .font(.title3.weight(.semibold))

                HStack(spacing: 12) {
                    Button("Играть снова") {
                        withAnimation { self.outcome = nil }
                        NotificationCenter.default.post(name: .resetScene, object: nil)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())

                    // Кнопка «Следующий уровень»: увеличим кол-во врагов на 1 (простой пример)
                    Button("Следующий уровень") {
                        withAnimation { self.outcome = nil }
                        // Простейший способ: отправим reset, а GameScene можно расширить,
                        // чтобы читать желаемое число врагов из Notification userInfo (если захочешь).
                        NotificationCenter.default.post(name: .resetScene, object: nil)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(24)
            .foregroundStyle(.white)
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 20)
            )
        }
    }

extension Notification.Name {
    static let resetScene = Notification.Name("resetScene")
    static let hudUpdate  = Notification.Name("hudUpdate")
    static let levelWon   = Notification.Name("levelWon")
    static let levelLost   = Notification.Name("levelLost")
}

struct TransparentSpriteView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let v = SKView()
        v.backgroundColor = .clear
        v.allowsTransparency = true
        v.ignoresSiblingOrder = true
        v.presentScene(scene)
        return v
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== scene { uiView.presentScene(scene) }
    }
}


final class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private let minGapFromPlayerX: CGFloat = 0.10
    
    // MARK: Nodes
    private var ground: SKSpriteNode?
    private var player: SKSpriteNode?
    private var platforms: [SKSpriteNode] = []
    private var enemies:   [SKSpriteNode] = []
    
    // MARK: Config
    private let groundHeight: CGFloat = 120
    private let playerHeight: CGFloat = 106
    private var didBuild = false
    
    // Level / ammo
    private var enemiesTotal = 0
    private var enemiesLeft  = 0
    private var ammoTotal    = 0
    private var ammoLeft     = 0
    
    // Throw/aim
    private var aimStart: CGPoint?
    private var aimArrow: SKShapeNode?
    private var aimPowerLabel: SKLabelNode?
    private let maxPull: CGFloat = 240
    private let minPull: CGFloat = 20
    private let powerScale: CGFloat = 2.5
    private let playerThrowOffset = CGPoint(x: 20, y: 20)
    
    
    // Рандомайзер уровня
    private let enemyRange: ClosedRange<Int> = 2...5      // врагов на уровень
    private let platformCountRange: ClosedRange<Int> = 3...5
    private let platformHeight: CGFloat = 24
    
    // Храним нормализованные позиции/размеры, чтобы не «перестраивать» при повороте
    private struct NormRect { var cx: CGFloat; var cy: CGFloat; var wRatio: CGFloat; var h: CGFloat }
    private var platformNorms: [NormRect] = []     // для платформ
    private var enemyNorms:    [CGPoint] = []      // для врагов (норм. центр)
    
    
    private var didPostWin = false
        private var didPostLose = false
    
    // Offscreen tracking (по идентификатору узла)
    private var offscreenStart: [ObjectIdentifier: TimeInterval] = [:]
    
    private var levelInitialized = false  // ← флаг, чтобы стартовать уровень один раз корректно
        private var exploding = Set<ObjectIdentifier>()
    
    // MARK: Physics categories
    struct Category {
        static let ground:    UInt32 = 1 << 0
        static let player:    UInt32 = 1 << 1
        static let grenade:   UInt32 = 1 << 2
        static let world:     UInt32 = 1 << 3   // бока+низ; верх открыт
        static let platform:  UInt32 = 1 << 4
        static let enemy:     UInt32 = 1 << 5
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Lifecycle
    override func sceneDidLoad() {
            scaleMode = .resizeFill
            backgroundColor = .clear
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
            physicsWorld.contactDelegate = self
        
        
        
        }
    
    override func didMove(to view: SKView) {
        ensureBuilt()
        safeLayout()
        rebuildWorldEdges()

        if !levelInitialized, size.width > 1, size.height > 1 {
            levelInitialized = true
            run(.wait(forDuration: 0)) { [weak self] in self?.startLevelRandom() }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(resetScene), name: .resetScene, object: nil)
    }
    
    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        ensureBuilt()
        safeLayout()
        resetScene()
        run(.wait(forDuration: 0)) { [weak self] in
            self?.rebuildWorldEdges()
            self?.layoutPlatformsAndEnemies()
        }
        
    }
    
    
    @objc private func resetScene() {
        for node in children where node !== ground && node !== player { node.removeFromParent() }
        platforms.removeAll()
        platformNorms.removeAll()
        enemies.removeAll()
        enemyNorms.removeAll()
        offscreenStart.removeAll()
        exploding.removeAll()
        aimCleanup()

        ensureBuilt()
        safeLayout()
        rebuildWorldEdges()
        startLevelRandom()
    }
    
    private func buildRandomPlatformsAndEnemies(rightOfPlayerXNorm px: CGFloat) {
        guard size.width > 1, size.height > 1 else { return }

        // 1) Сгенерим НОРМАЛИЗОВАННЫЕ платформы ТОЛЬКО справа от игрока
        let count = Int.random(in: platformCountRange)
        platformNorms = generatePlatformNormsRightOf(playerXNorm: px, count: count)

        // 2) Создадим платформы по нормам
        let tex = SKTexture(imageNamed: "platform_texture")
        tex.filteringMode = .nearest
        platforms.removeAll()
        for norm in platformNorms {
            let w = size.width * norm.wRatio
            let center = CGPoint(x: size.width * norm.cx, y: size.height * norm.cy)
            let p = SKSpriteNode(texture: tex, color: .clear, size: CGSize(width: w, height: platformHeight))
            p.zPosition = 2
            p.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            p.position = center
            p.physicsBody = SKPhysicsBody(rectangleOf: p.size)
            p.physicsBody?.isDynamic = false
            p.physicsBody?.categoryBitMask = Category.platform
            p.physicsBody?.collisionBitMask = Category.grenade | Category.player
            addChild(p)
            platforms.append(p)
        }

        // 3) Точки спауна врагов — над платформами; фильтруем по «строго правее игрока»
        var spots: [CGPoint] = []
        for p in platforms {
            let yTop = p.position.y + p.size.height/2
            let slots = Int.random(in: 3...5)
            for s in 0..<slots {
                let t = CGFloat(s + 1) / CGFloat(slots + 1)
                let x = p.position.x + (t - 0.5) * p.size.width * 0.8
                // правее игрока с небольшим запасом (тот же minGapFromPlayerX)
                if x > size.width * (px + minGapFromPlayerX * 0.5) {
                    spots.append(CGPoint(x: x, y: yTop + 22))
                }
            }
        }
        spots.shuffle()

        enemyNorms = spots.prefix(enemiesTotal).map { CGPoint(x: $0.x / size.width, y: $0.y / size.height) }
        spawnEnemiesFromNorms()
    }
    
    private func generatePlatformNormsRightOf(playerXNorm px: CGFloat, count: Int) -> [NormRect] {
        var result: [NormRect] = []
        guard count > 0 else { return result }

        let minW: CGFloat = 0.16
        let maxW: CGFloat = 0.28
        let minY: CGFloat = 0.25
        let maxY: CGFloat = 0.80
        let minYGap: CGFloat = 0.12

        // минимальный центр X для платформ, чтобы они были явно справа от игрока
        let baseMinCx = min(0.95, px + minGapFromPlayerX)

        // 1) Выбираем набор Y «ярусов» без сильных пересечений
        var yBands: [CGFloat] = []
        var tries = 0
        while yBands.count < count && tries < 60 {
            let y = CGFloat.random(in: minY...maxY)
            if yBands.allSatisfy({ abs($0 - y) >= minYGap }) { yBands.append(y) }
            tries += 1
        }
        if yBands.isEmpty { yBands = [0.35, 0.55, 0.75].prefix(count).map { $0 } }

        // 2) Для каждого яруса — ширина платформы и центр X в «правой области»
        for y in yBands.prefix(count) {
            let wRatio = CGFloat.random(in: minW...maxW)
            let marginX = max(wRatio * 0.6, 0.04) // чтобы платформа не упиралась в край
            // левая граница центра — правее игрока + отступ + половина платформы
            let minCx = max(baseMinCx + wRatio/2, marginX)
            let maxCx = max(minCx, 1 - marginX)   // защитимся от переполнения

            // если реально не остаётся места, уменьшим ширину и пересчитаем
            var cxRangeMin = minCx
            var cxRangeMax = 1 - marginX
            var w = wRatio
            var safeguard = 0
            while cxRangeMin > cxRangeMax && safeguard < 5 {
                w *= 0.85
                cxRangeMin = max(px + minGapFromPlayerX + w/2, marginX)
                cxRangeMax = 1 - marginX
                safeguard += 1
            }
            if cxRangeMin > cxRangeMax {
                // вообще нет места справа — пропускаем эту платформу
                continue
            }

            let cx = CGFloat.random(in: cxRangeMin...cxRangeMax)
            result.append(NormRect(cx: cx, cy: y, wRatio: w, h: platformHeight))
        }

        // Если платформ получилось меньше, чем просили, просто вернём что есть.
        return result
    }
    
    private func generatePlatformNorms(count: Int) -> [NormRect] {
        var result: [NormRect] = []
        let minW: CGFloat = 0.16
        let maxW: CGFloat = 0.28
        let minY: CGFloat = 0.25
        let maxY: CGFloat = 0.80

        // разбиваем вертикаль на «ярусы», но с рандомом
        var yBands: [CGFloat] = []
        for _ in 0..<count {
            yBands.append(CGFloat.random(in: minY...maxY))
        }
        // убираем слишком близкие по Y
        yBands.sort()
        var filtered: [CGFloat] = []
        let minYGap: CGFloat = 0.12
        for y in yBands {
            if let last = filtered.last {
                if abs(y - last) < minYGap { continue }
            }
            filtered.append(y)
        }
        // если в итоге получилось меньше — дозаполним попытками
        var tries = 0
        while filtered.count < count && tries < 30 {
            let y = CGFloat.random(in: minY...maxY)
            if filtered.allSatisfy({ abs($0 - y) >= minYGap }) { filtered.append(y) }
            tries += 1
        }
        filtered = Array(filtered.prefix(count))

        // на каждом ярусе — случайная ширина и центр X (с отступами)
        for y in filtered {
            let wRatio = CGFloat.random(in: minW...maxW)
            let marginX = wRatio * 0.6
            let cx = CGFloat.random(in: marginX...(1 - marginX))
            result.append(NormRect(cx: cx, cy: y, wRatio: wRatio, h: platformHeight))
        }
        return result
    }

    // Создать врагов на основе сохранённых норм
    private func spawnEnemiesFromNorms() {
        let enemyTex = SKTexture(imageNamed: "enemy")
        enemyTex.filteringMode = .nearest
        let enemySize: CGFloat = 42

        enemies.removeAll()
        for npos in enemyNorms {
            let pos = CGPoint(x: size.width * npos.x, y: size.height * npos.y)
            let e = SKSpriteNode(texture: enemyTex, color: .clear, size: CGSize(width: enemySize, height: enemySize))
            e.name = "enemy"
            e.zPosition = 4
            e.position = pos

            let body = SKPhysicsBody(circleOfRadius: enemySize * 0.45)
            body.isDynamic = false
            body.categoryBitMask = Category.enemy
            body.collisionBitMask = Category.grenade
            e.physicsBody = body

            addChild(e)
            enemies.append(e)
        }
    }
    
    
    private func ensureBuilt() {
        guard !didBuild else { return }
        buildGround()
        buildPlayer()
        didBuild = true
    }
    
    // MARK: Build
    private func buildGround() {
        let texture = SKTexture(imageNamed: "ground_texture")
        texture.filteringMode = .nearest
        
        let node = SKSpriteNode(texture: texture, color: .clear,
                                size: CGSize(width: max(size.width, 1), height: groundHeight))
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = CGPoint(x: size.width/2, y: 0)
        node.zPosition = 1
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size,
                                         center: CGPoint(x: 0, y: node.size.height/2))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = Category.ground
        node.physicsBody?.collisionBitMask = Category.player | Category.grenade
        
        addChild(node)
        ground = node
    }
    
    private func buildPlayer() {
        let pTexture = SKTexture(imageNamed: "player_idle")
        let aspect = max(0.5, pTexture.size().width / max(1, pTexture.size().height))
        let pSize = CGSize(width: playerHeight * aspect, height: playerHeight)
        
        let node = SKSpriteNode(texture: pTexture, color: .clear, size: pSize)
        node.name = "player"
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 5
        
        let body = SKPhysicsBody(texture: pTexture, size: pSize)
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.8
        body.linearDamping = 0.2
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = Category.player
        body.collisionBitMask = Category.ground | Category.world
        body.contactTestBitMask = Category.ground | Category.world
        body.affectedByGravity = false
        node.physicsBody = body
        
        addChild(node)
        player = node
    }
    
    private func safeLayout() {
          guard let ground, let player else { return }
          guard size.width > 1, size.height > 1 else { return }

          ground.size = CGSize(width: size.width, height: groundHeight)
          ground.position = CGPoint(x: size.width/2, y: 0)
          ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size,
                                             center: CGPoint(x: 0, y: ground.size.height/2))
          ground.physicsBody?.isDynamic = false
          ground.physicsBody?.categoryBitMask = Category.ground
          ground.physicsBody?.collisionBitMask = Category.player | Category.grenade

          player.physicsBody?.affectedByGravity = false
          player.physicsBody?.velocity = .zero
          player.physicsBody?.angularVelocity = 0
          let playerY = ground.position.y + ground.size.height + player.size.height/2
          player.position = CGPoint(x: size.width * 0.2, y: playerY)
          run(.wait(forDuration: 0)) { [weak self] in
              self?.player?.physicsBody?.affectedByGravity = true
          }
      }
    
    // MARK: Open-sky borders (no top edge)
    private func rebuildWorldEdges() {
           let w = size.width, h = size.height
           guard w > 1, h > 1, w.isFinite, h.isFinite else { return }

           let path = CGMutablePath()
           path.move(to: CGPoint(x: 0, y: h))
           path.addLine(to: CGPoint(x: 0, y: 0))
           path.addLine(to: CGPoint(x: w, y: 0))
           path.addLine(to: CGPoint(x: w, y: h))
           physicsBody = SKPhysicsBody(edgeChainFrom: path)
           physicsBody?.isDynamic = false
           physicsBody?.categoryBitMask = Category.world
           physicsBody?.collisionBitMask = Category.grenade | Category.player
           physicsBody?.contactTestBitMask = 0
       }
    
    // MARK: Level
    private func startLevel(withEnemies count: Int) {
            enemiesTotal = max(1, count)
            enemiesLeft  = enemiesTotal
            ammoTotal    = enemiesTotal * 5
            ammoLeft     = ammoTotal
            didPostWin = false
            didPostLose = false

            buildPlatformsAndEnemies()
            postHUD()
        }
    
    private func startLevelRandom() {
        enemiesTotal = Int.random(in: enemyRange)
        enemiesLeft  = enemiesTotal
        ammoTotal    = enemiesTotal * 3
        ammoLeft     = ammoTotal
        didPostWin = false
        didPostLose = false

        // Нормализованный X игрока (на случай если он не точно 0.2 ширины)
        let playerXNorm = (player?.position.x ?? size.width * 0.2) / max(size.width, 1)

        buildRandomPlatformsAndEnemies(rightOfPlayerXNorm: playerXNorm)
        postHUD()
    }
    
    private func buildPlatformsAndEnemies() {
        let w = size.width, h = size.height
              guard w > 1, h > 1 else { return }
        
        // Платформы (3 слоя)
        let tex = SKTexture(imageNamed: "platform_texture")
        tex.filteringMode = .nearest
        
        func addPlatform(center: CGPoint, width: CGFloat, height: CGFloat = 24) {
            let p = SKSpriteNode(texture: tex, color: .clear, size: CGSize(width: width, height: height))
            p.zPosition = 2
            p.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            p.position = center
            p.physicsBody = SKPhysicsBody(rectangleOf: p.size)
            p.physicsBody?.isDynamic = false
            p.physicsBody?.categoryBitMask = Category.platform
            p.physicsBody?.collisionBitMask = Category.grenade | Category.player
            addChild(p)
            platforms.append(p)
        }
        
        addPlatform(center: CGPoint(x: w * 0.55, y: h * 0.28), width: w * 0.22)
        addPlatform(center: CGPoint(x: w * 0.75, y: h * 0.46), width: w * 0.20)
        addPlatform(center: CGPoint(x: w * 0.60, y: h * 0.65), width: w * 0.18)
        
        layoutPlatformsAndEnemies()
    }
    
    private func layoutPlatformsAndEnemies() {
        guard size.width > 1, size.height > 1 else { return }

        // Платформы — по сохранённым нормам
        if platforms.count != platformNorms.count {
            // Если что-то пошло не так, пересоздадим текущую раскладку по нормам
            for p in platforms { p.removeFromParent() }
            platforms.removeAll()

            let tex = SKTexture(imageNamed: "platform_texture")
            tex.filteringMode = .nearest
            for norm in platformNorms {
                let w = size.width * norm.wRatio
                let center = CGPoint(x: size.width * norm.cx, y: size.height * norm.cy)
                let p = SKSpriteNode(texture: tex, color: .clear, size: CGSize(width: w, height: platformHeight))
                p.zPosition = 2
                p.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                p.position = center
                p.physicsBody = SKPhysicsBody(rectangleOf: p.size)
                p.physicsBody?.isDynamic = false
                p.physicsBody?.categoryBitMask = Category.platform
                p.physicsBody?.collisionBitMask = Category.grenade | Category.player
                addChild(p)
                platforms.append(p)
            }
        } else {
            for (i, p) in platforms.enumerated() {
                let norm = platformNorms[i]
                p.size = CGSize(width: size.width * norm.wRatio, height: platformHeight)
                p.position = CGPoint(x: size.width * norm.cx, y: size.height * norm.cy)
                p.physicsBody = SKPhysicsBody(rectangleOf: p.size)
                p.physicsBody?.isDynamic = false
                p.physicsBody?.categoryBitMask = Category.platform
                p.physicsBody?.collisionBitMask = Category.grenade | Category.player
            }
        }

        // Враги — по сохранённым нормам
        // Удалим текущие и пересоздадим (их мало)
        for e in enemies { e.removeFromParent() }
        spawnEnemiesFromNorms()
    }
    
    // MARK: Touches (aim arrow)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ammoLeft > 0 else { return }
        guard let t = touches.first, let player = player else { return }
        let loc = t.location(in: self)
        if loc.distance(to: player.position) <= 360 {
            aimStart = loc
            showAimArrow(from: player.position, to: loc)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ammoLeft > 0 else { return }
        guard let t = touches.first, let player = player, aimStart != nil else { return }
        let loc = t.location(in: self)
        showAimArrow(from: player.position, to: loc)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ammoLeft > 0 else { aimCleanup(); return }
        guard let t = touches.first, let player = player, aimStart != nil else { aimCleanup(); return }
        let end = t.location(in: self)
        aimCleanup()
        aimStart = nil
        
        var pull = player.position - end
        var length = pull.length
        if length < minPull { return }
        if length > maxPull { pull = pull.normalized * maxPull; length = maxPull }
        
        let impulse = CGVector(dx: pull.x * powerScale, dy: pull.y * powerScale)
        spawnGrenade(at: player.position + playerThrowOffset, impulse: impulse)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        aimCleanup()
        aimStart = nil
    }
    
    // MARK: Grenade
    private func spawnGrenade(at pos: CGPoint, impulse: CGVector) {
        ammoLeft = max(0, ammoLeft - 1)
               postHUD()
        
        let tex = SKTexture(imageNamed: "grenade")
        let sizeEdge: CGFloat = 28
        let node = SKSpriteNode(texture: tex, color: .clear, size: CGSize(width: sizeEdge, height: sizeEdge))
        node.name = "grenade"
        node.zPosition = 6
        node.position = pos
        
        let body = SKPhysicsBody(circleOfRadius: sizeEdge * 0.45)
        body.mass = 0.15
        body.restitution = 0.35
        body.friction = 0.4
        body.linearDamping = 0.05
        body.angularDamping = 0.05
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = Category.grenade
        body.collisionBitMask = Category.ground | Category.world | Category.platform
        body.contactTestBitMask = Category.ground | Category.platform
        node.physicsBody = body
        
        addChild(node)
        body.applyImpulse(impulse)
        
        // обнулим счётчик offscreen для этой гранаты
        offscreenStart[ObjectIdentifier(node)] = nil
    }
    
    // MARK: Contact
    func didBegin(_ contact: SKPhysicsContact) {
            let a = contact.bodyA, b = contact.bodyB
            let isGrenadeA = a.categoryBitMask & Category.grenade != 0
            let isGrenadeB = b.categoryBitMask & Category.grenade != 0

            let otherMaskA = b.categoryBitMask
            let otherMaskB = a.categoryBitMask
            let explodeHitA = isGrenadeA && (otherMaskA & (Category.ground | Category.platform) != 0)
            let explodeHitB = isGrenadeB && (otherMaskB & (Category.ground | Category.platform) != 0)

            if explodeHitA || explodeHitB {
                guard let grenadeNode = (isGrenadeA ? a.node : b.node) else { return }
                let id = ObjectIdentifier(grenadeNode)
                // защита: если уже в процессе взрыва — игнор
                guard !exploding.contains(id) else { return }
                exploding.insert(id)

                explode(at: contact.contactPoint, from: grenadeNode)
            }
        }
    
    private func explode(at point: CGPoint, from grenade: SKNode) {
        // эффект
        let blastRadius: CGFloat = 140
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.name = "explosion"
        ring.position = point
        ring.zPosition = 20
        ring.lineWidth = 6
        ring.strokeColor = .white
        ring.alpha = 0.9
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: blastRadius/10, duration: 0.18),
                    .fadeOut(withDuration: 0.22)]),
            .removeFromParent()
        ]))
        
        // отталкивание динамических тел (если появятся)
        let blast = CGFloat(22_000)
        enumerateChildNodes(withName: "//") { node, _ in
            guard let pb = node.physicsBody, pb.isDynamic else { return }
            let d = node.position.distance(to: point)
            guard d > 0, d <= blastRadius else { return }
            let dir = (node.position - point).normalized
            pb.applyImpulse(CGVector(dx: dir.x * (1 - d/blastRadius) * blast,
                                     dy: dir.y * (1 - d/blastRadius) * blast))
        }
        
        // убиваем РОВНО одного ближайшего врага
        if let victim = nearestEnemy(inRadius: blastRadius, around: point) {
            victim.removeFromParent()
            if let idx = enemies.firstIndex(where: { $0 === victim }) {
                enemies.remove(at: idx)
            }
            enemiesLeft = max(0, enemiesLeft - 1)
            postHUD()
            if enemiesLeft == 0 {
                NotificationCenter.default.post(name: .levelWon, object: nil)
            }
        }
        
        grenade.run(.removeFromParent())
               offscreenStart.removeValue(forKey: ObjectIdentifier(grenade))
        
        if let victim = nearestEnemy(inRadius: 140, around: point) {
                   victim.run(.removeFromParent())
                   if let idx = enemies.firstIndex(where: { $0 === victim }) { enemies.remove(at: idx) }
                   enemiesLeft = max(0, enemiesLeft - 1)
                   postHUD()
                   if enemiesLeft == 0 && !didPostWin {
                       didPostWin = true
                       DispatchQueue.main.async {
                           NotificationCenter.default.post(name: .levelWon, object: nil)
                       }
                   }
               }

               grenade.run(.removeFromParent())
               offscreenStart.removeValue(forKey: ObjectIdentifier(grenade))

               // снимаем флаг «взрыва» (через небольшой delay, чтобы избежать race)
               let id = ObjectIdentifier(grenade)
               run(.wait(forDuration: 0.0)) { [weak self] in self?.exploding.remove(id) }
        
    }
    
    private func nearestEnemy(inRadius r: CGFloat, around point: CGPoint) -> SKSpriteNode? {
        var bestNode: SKSpriteNode?
        var bestDist = CGFloat.greatestFiniteMagnitude
        for e in enemies {
            let d = e.position.distance(to: point)
            if d <= r, d < bestDist { bestDist = d; bestNode = e }
        }
        return bestNode
    }
    
    // MARK: Update (loss if off-screen > 1s)
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let insideRect = frame.insetBy(dx: -40, dy: -40)
        enumerateChildNodes(withName: "grenade") { [weak self] node, _ in
            guard let self = self else { return }
            let id = ObjectIdentifier(node)
            if insideRect.contains(node.position) {
                self.offscreenStart[id] = nil
            } else {
                if self.offscreenStart[id] == nil {
                    self.offscreenStart[id] = currentTime
                } else if let t0 = self.offscreenStart[id],
                          currentTime - t0 >= 1.0 {
                    node.run(.removeFromParent())
                    self.offscreenStart.removeValue(forKey: id)
                }
            }
        }
        
        if ammoLeft == 0 && enemiesLeft > 0 && !didPostLose {
                    didPostLose = true
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .levelLost, object: nil)
                    }
                }
    }
    
    // MARK: Aim arrow
    private func showAimArrow(from origin: CGPoint, to current: CGPoint) {
        var v = origin - current
        let len = v.length
        let clamped = min(maxPull, len)
        v = (len > 0) ? v.normalized * clamped : .zero
        let end = origin + v
        
        let shaftWidth: CGFloat = 6
        let headLength: CGFloat = 18
        let headWidth: CGFloat = 16
        
        let path = CGMutablePath()
        let shaftEnd = end - ((v.length > 0) ? v.normalized * headLength : .zero)
        path.move(to: origin)
        path.addLine(to: shaftEnd)
        
        let ortho = CGPoint(x: -v.y, y: v.x).normalized
        let p1 = end, p2 = shaftEnd + ortho * (headWidth/2), p3 = shaftEnd - ortho * (headWidth/2)
        path.move(to: p1); path.addLine(to: p2); path.addLine(to: p3); path.addLine(to: p1)
        
        if aimArrow == nil {
            let node = SKShapeNode(path: path)
            node.strokeColor = .white
            node.fillColor = .white
            node.lineWidth = shaftWidth
            node.lineCap = .round
            node.alpha = 0.95
            node.zPosition = 50
            addChild(node)
            aimArrow = node
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.fontSize = 18
            label.fontColor = .white
            label.zPosition = 51
            addChild(label)
            aimPowerLabel = label
        } else {
            aimArrow?.path = path
        }
        
        let percent = Int((clamped / maxPull * 100).rounded())
        aimPowerLabel?.text = "\(percent)%"
        aimPowerLabel?.position = end + ((v.length > 0 ? v.normalized : .zero) * 16)
    }
    
    private func aimCleanup() {
        aimArrow?.removeFromParent()
        aimArrow = nil
        aimPowerLabel?.removeFromParent()
        aimPowerLabel = nil
    }
    
    // MARK: HUD
    private func postHUD() {
        let payload: [String: Any] = [
            "ammoLeft": ammoLeft, "ammoTotal": ammoTotal,
            "enemiesLeft": enemiesLeft, "enemiesTotal": enemiesTotal
        ]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .hudUpdate, object: nil, userInfo: payload)
        }
    }
}

// MARK: - CGPoint helpers
private extension CGPoint {
    static func + (l: CGPoint, r: CGPoint) -> CGPoint { .init(x: l.x + r.x, y: l.y + r.y) }
    static func - (l: CGPoint, r: CGPoint) -> CGPoint { .init(x: l.x - r.x, y: l.y - r.y) }
    static func * (l: CGPoint, r: CGFloat) -> CGPoint { .init(x: l.x * r, y: l.y * r) }
    
    var length: CGFloat { sqrt(x*x + y*y) }
    var normalized: CGPoint {
        let L = max(0.0001, length)
        return .init(x: x/L, y: y/L)
    }
    func distance(to p: CGPoint) -> CGFloat { (self - p).length }
}
