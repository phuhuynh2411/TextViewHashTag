//
//  ViewController.swift
//  TextViewHashTag
//
//  Created by Huynh Tan Phu on 15/09/2021.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class HashtagTextView: UITextView {
    
    var hashtagRegex = "#[-_0-9A-Za-z]+"
    private var cachedFrames: [CGRect] = []
    private var backgrounds: [UIView] = []
    var hashTagBackgroundColor: UIColor = .lightGray
    var hashTagCornerRardius: CGFloat = 5.0
    private let offsetHeight: CGFloat = 4
    var onlyStartWithTag: Bool = true
    var hashTags: [String] = []
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Redraw highlighted parts if frame is changed
        textUpdated()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func textUpdated() {
        // You can provide whatever ranges needed to be highlighted
        let ranges = resolveHighlightedRanges()
        let swiftRanges = ranges.compactMap { Range($0, in: text) }
        hashTags = swiftRanges.map { String(text[$0]) }
        
        let frames = ranges.compactMap { frame(ofRange: $0) }.reduce([], +)
        
        if cachedFrames != frames {
            cachedFrames = frames
            
            backgrounds.forEach { $0.removeFromSuperview() }
            backgrounds = cachedFrames.map { frame in
                let background = UIView()
                background.backgroundColor = hashTagBackgroundColor
                let newFrame = CGRect(
                    x: frame.minX,
                    y: frame.minY,
                    width: frame.width,
                    height: frame.height - offsetHeight
                )
                background.frame = newFrame
                background.layer.cornerRadius = hashTagCornerRardius
                
                insertSubview(background, at: 0)
                return background
            }
        }
        print(hashTags)
    }
    
    /// General setup
    private func configureView() {
        NotificationCenter.default.addObserver(self, selector: #selector(textUpdated), name: UITextView.textDidChangeNotification, object: self)
        delegate = self
    }
    
    /// Looks for locations of the string to be highlighted.
    /// The current case - ranges of hashtags.
    private func resolveHighlightedRanges() -> [NSRange] {
        guard text != nil, let regex = try? NSRegularExpression(pattern: hashtagRegex, options: []) else { return [] }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
        let ranges = matches.map { $0.range }
        return ranges
    }
}

extension UITextView {
    func convertRange(_ range: NSRange) -> UITextRange? {
        let beginning = beginningOfDocument
        if let start = position(from: beginning, offset: range.location), let end = position(from: start, offset: range.length) {
            let resultRange = textRange(from: start, to: end)
            return resultRange
        } else {
            return nil
        }
    }
    
    func frame(ofRange range: NSRange) -> [CGRect]? {
        if let textRange = convertRange(range) {
            let rects = selectionRects(for: textRange)
            return rects.map { $0.rect }
        } else {
            return nil
        }
    }
}

extension HashtagTextView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard onlyStartWithTag else { return true }
        
        // Detects backspaces
        if text.isEmpty { return true }
        
        // The first tag
        if textView.text.isEmpty {
            if text == "#" {
                return true
            } else {
                return false
            }
        }
        
        // Type in a new line
        if textView.text.last == "#", text == "\n" {
            return false
        }
        
        // Type double #
        if textView.text.last == "#", text == "#" {
            return false
        }
        
        // The other tags
        if textView.text.last == " ", text != "#" {
            return false
        } else {
            return true
        }
    }
}
