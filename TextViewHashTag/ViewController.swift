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
        // Do any additional setup after loading the view.
        textView.delegate = self
    }
    
    func resolveHashTags(text : String) -> NSAttributedString {
        var length : Int = 0
        let text:String = text
        let words:[String] = text.separate(withChar: " ")
        let hashtagWords = words.flatMap({$0.separate(withChar: "#")})
        let attrs = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17.0)]
        let attrString = NSMutableAttributedString(string: text, attributes:attrs)
        for word in hashtagWords {
            if word.hasPrefix("#") {
                let matchRange:NSRange = NSMakeRange(length, word.count)
                let stringifiedWord:String = word
                
                attrString.addAttribute(NSAttributedString.Key.link, value: "hash:\(stringifiedWord)", range: matchRange)
                
                attrString.addAttribute(NSAttributedString.Key.baselineOffset, value: -4 , range: matchRange)
                
                attrString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.lightGray , range: matchRange)
                
            }
            length += word.count
        }
        return attrString
    }
    
}

extension ViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textView.attributedText = resolveHashTags(text: textView.text)
        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.red]    }
}

extension String {
    public func separate(withChar char : String) -> [String]{
        var word : String = ""
        var words : [String] = [String]()
        for chararacter in self {
            if String(chararacter) == char && word != "" {
                words.append(word)
                word = char
            }else {
                word += String(chararacter)
            }
        }
        words.append(word)
        return words
    }
    
}


class HashtagTextView: UITextView {
    
    let hashtagRegex = "#[-_0-9A-Za-z]+"
    
    private var cachedFrames: [CGRect] = []
    
    private var backgrounds: [UIView] = []
    
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
        
        let frames = ranges.compactMap { frame(ofRange: $0) }.reduce([], +)
        
        if cachedFrames != frames {
            cachedFrames = frames
            
            backgrounds.forEach { $0.removeFromSuperview() }
            backgrounds = cachedFrames.map { frame in
                let background = UIView()
                background.backgroundColor = UIColor.gray
                let newFrame = CGRect(x: frame.minX, y: frame.minY + 10, width: frame.width, height: frame.height - 5)
                background.frame = frame
                background.layer.cornerRadius = 5
                //background.layer.borderWidth = 1.0
                //background.layer.borderColor = UIColor.red.cgColor
                //background.backgroundColor = .clear
                
                insertSubview(background, at: 0)
                return background
            }
        }
    }
    
    /// General setup
    private func configureView() {
        NotificationCenter.default.addObserver(self, selector: #selector(textUpdated), name: UITextView.textDidChangeNotification, object: self)
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
