import Combine
import UIKit
import SwiftUI

class LoaderView: UIView {
    // FIX: Added didSet so the timer actually starts.
    // Before: animated was set to true AFTER init, but startTimer() was only called
    // inside init (where animated was still false). The loader never animated.
    // Now: whenever animated is set to true, didSet triggers and starts the timer.
    var animated: Bool = false {
        didSet {
            if animated {
                startTimer()
            }
        }
    }

    private(set) var progressSubject = CurrentValueSubject<Float, Never>(0.0)

    private var timer: Timer?
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        if animated {
            startTimer()
        }
    }

    // FIX: Invalidate the timer when the view is deallocated.
    // Without this, the RunLoop keeps a reference to the timer, the timer keeps firing,
    // and its closure tries to access a deallocated view -> crash or leak.
    deinit {
        timer?.invalidate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let lineWidth: CGFloat = 8.0
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.blue.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineWidth: CGFloat = 8.0
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    private func startTimer() {
        // FIX: [unowned self] -> [weak self]
        // unowned crashes if self is deallocated while the timer is still on the RunLoop.
        // weak safely becomes nil, and the guard exits early instead of crashing.
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.progressSubject.value += 0.1
            if self.progressSubject.value > 1.0 {
                self.progressSubject.value = 0.0
            }
            self.progressLayer.strokeEnd = CGFloat(self.progressSubject.value)
        }
    }
}

struct Loader: UIViewRepresentable {
    @Binding var progress: Float
    var animated: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress)
    }

    func makeUIView(context: Context) -> LoaderView {
        let view = LoaderView(frame: .zero)
        view.progressSubject
            .sink { context.coordinator.updateProgress($0) }
            .store(in: &context.coordinator.subscriptons)
        view.animated = animated
        return view
    }

    func updateUIView(_ uiView: LoaderView, context: Context) {
        uiView.animated = animated
    }

    class Coordinator: NSObject {
        var progress: Binding<Float>
        var subscriptons = Set<AnyCancellable>()

        init(progress: Binding<Float>) {
            self.progress = progress
        }

        func updateProgress(_ newProgress: Float) {
            self.progress.wrappedValue = newProgress
        }
    }
}
