import Foundation
import UIKit
import AsyncDisplayKit
import ContextUI
import TelegramPresentationData
import Display

final class PeerInfoHeaderActionButtonNode: HighlightableButtonNode {
    let key: PeerInfoHeaderButtonKey
    private let action: (PeerInfoHeaderActionButtonNode, ContextGesture?) -> Void
    let referenceNode: ContextReferenceContentNode
    let containerNode: ContextControllerSourceNode
    private let backgroundNode: ASDisplayNode
    private var pearlGradient: CAGradientLayer?
    private let textNode: ImmediateTextNode
    
    private var theme: PresentationTheme?
    
    init(key: PeerInfoHeaderButtonKey, action: @escaping (PeerInfoHeaderActionButtonNode, ContextGesture?) -> Void) {
        self.key = key
        self.action = action
        
        self.referenceNode = ContextReferenceContentNode()
        self.containerNode = ContextControllerSourceNode()
        self.containerNode.animateScale = false
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.cornerRadius = 11.0
                
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false
        self.textNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.accessibilityTraits = .button
        
        self.containerNode.addSubnode(self.referenceNode)
        self.referenceNode.addSubnode(self.backgroundNode)
        self.addSubnode(self.containerNode)
        self.addSubnode(self.textNode)
        
        self.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.layer.removeAnimation(forKey: "opacity")
                    strongSelf.alpha = 0.4
                } else {
                    strongSelf.alpha = 1.0
                    strongSelf.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                }
            }
        }
        
        self.containerNode.activated = { [weak self] gesture, _ in
            if let strongSelf = self {
                strongSelf.action(strongSelf, gesture)
            }
        }
        
        self.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
    }
    
    @objc private func buttonPressed() {
        self.action(self, nil)
    }
    
    func update(size: CGSize, text: String, presentationData: PresentationData, transition: ContainedViewLayoutTransition) {
        let themeUpdated = self.theme != presentationData.theme
        if themeUpdated {
            self.theme = presentationData.theme
            
            self.containerNode.isGestureEnabled = false
                                                            
            self.backgroundNode.backgroundColor = presentationData.theme.list.itemAccentColor
            transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        }
        
        let pearl = ["Pearl Mist", "Arctic Pearl", "Midnight Pearl"].contains(presentationData.theme.name.string)
        if pearl {
            let gradient: CAGradientLayer
            if let current = self.pearlGradient {
                gradient = current
            } else {
                gradient = CAGradientLayer()
                self.pearlGradient = gradient
                self.backgroundNode.layer.addSublayer(gradient)
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gradient.frame = CGRect(origin: CGPoint(), size: size)
            gradient.cornerRadius = min(22.0, size.height * 0.5)
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
            let accent = presentationData.theme.list.itemAccentColor
            let reflection = presentationData.theme.overallDarkAppearance ? UIColor.white : UIColor.black
            gradient.colors = [accent.mixedWith(reflection, alpha: 0.12).cgColor, accent.cgColor]
            gradient.borderWidth = 1.0 / UIScreen.main.scale
            gradient.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
            self.backgroundNode.cornerRadius = gradient.cornerRadius
            CATransaction.commit()
        } else {
            self.pearlGradient?.removeFromSuperlayer()
            self.pearlGradient = nil
            self.backgroundNode.cornerRadius = 11.0
        }

        self.textNode.attributedText = NSAttributedString(string: text, font: Font.semibold(16.0), textColor: presentationData.theme.list.itemCheckColors.foregroundColor)
        self.accessibilityLabel = text
        let titleSize = self.textNode.updateLayout(CGSize(width: 120.0, height: .greatestFiniteMagnitude))
        
        transition.updateFrame(node: self.containerNode, frame: CGRect(origin: CGPoint(), size: size))
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        transition.updateFrameAdditiveToCenter(node: self.textNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - titleSize.width) / 2.0), y: floorToScreenPixels((size.height - titleSize.height) / 2.0)), size: titleSize))
        
        self.referenceNode.frame = self.containerNode.bounds
    }
}
