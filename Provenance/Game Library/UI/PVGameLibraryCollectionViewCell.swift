//  PVGameLibraryCollectionViewCell.swift
//  Provenance
//
//  Created by James Addyman on 07/04/2013.
//  Copyright (c) 2013 JamSoft. All rights reserved.
//

private let LabelHeight: CGFloat = 44.0

extension UIImage {
    class func image(withSize size: CGSize, color: UIColor, text: NSAttributedString) -> UIImage? {
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.setFillColor(color.cgColor)
        context.setStrokeColor(UIColor(white: 0.7, alpha: 0.6).cgColor)
        context.setLineWidth(0.5)
        context.fill(rect)
        var boundingRect: CGRect = text.boundingRect(with: rect.size, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
        boundingRect.origin = CGPoint(x: rect.midX - (boundingRect.width / 2), y: rect.midY - (boundingRect.height / 2))
        text.draw(in: boundingRect)
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

class PVGameLibraryCollectionViewCell: UICollectionViewCell {
    private(set) var imageView: UIImageView!
    private(set) var titleLabel: UILabel!
    var operation: BlockOperation?

    class func cellSize(forImageSize imageSize: CGSize) -> CGSize {
        return CGSize(width: imageSize.width, height: imageSize.height + LabelHeight)
    }
    
    func setup(with game: PVGame) {
        let artworkURL: String = game.customArtworkURL
        let originalArtworkURL: String = game.originalArtworkURL
        if PVSettingsModel.sharedInstance().showGameTitles {
            titleLabel.text = game.title
        }
        
            // TODO: May be renabled later
        let placeholderImageText: String = PVEmulatorConfiguration.sharedInstance().shortName(forSystemIdentifier: game.systemIdentifier) ?? "No System"
        if artworkURL.isEmpty && originalArtworkURL.isEmpty {
            var artworkText: String
            if PVSettingsModel.sharedInstance().showGameTitles {
                artworkText = placeholderImageText
            }
            else {
                artworkText = game.title
            }
            imageView.image = image(withText: artworkText)
        }
        else {
            var maybeKey: String? = !artworkURL.isEmpty ? artworkURL : nil
            if maybeKey == nil {
                maybeKey = !originalArtworkURL.isEmpty ? originalArtworkURL : nil
            }
            if let key = maybeKey {
                operation = PVMediaCache.shareInstance().image(forKey: key, completion: {(_ image: UIImage?) -> Void in
                    var artworkText: String
                    if PVSettingsModel.sharedInstance().showGameTitles {
                        artworkText = placeholderImageText
                    }
                    else {
                        artworkText = game.title
                    }
                    let artwork: UIImage? = image ?? self.image(withText: artworkText)
                    self.imageView.image = artwork
#if os(tvOS)
                    let width: CGFloat = self.frame.width
                    let boxartSize = CGSize(width: width, height: width / game.boxartAspectRatio)
                    self.imageView.frame = CGRect(x: 0, y: 0, width: width, height: boxartSize.height)
#else
                    var imageHeight: CGFloat = self.frame.size.height
                    if PVSettingsModel.sharedInstance().showGameTitles {
                        imageHeight -= 44
                    }
                    self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: imageHeight)
#endif
                    self.setNeedsLayout()
                })
            }
        }

        setNeedsLayout()
        if #available(iOS 9.0, *) {
            setNeedsFocusUpdate()
        }
        setNeedsLayout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var imageHeight: CGFloat = frame.size.height
        if PVSettingsModel.sharedInstance().showGameTitles {
            imageHeight -= 44
        }
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: imageHeight))
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: imageView.frame.size.height, width: frame.size.width, height: LabelHeight))
        titleLabel.lineBreakMode = .byTruncatingTail
#if os(tvOS)
        // The label's alpha will get set to 1 on focus
        titleLabel.alpha = 0
        imageView.adjustsImageWhenAncestorFocused = true
        titleLabel.textColor = UIColor.white
        titleLabel.layer.masksToBounds = false
        titleLabel.shadowColor = UIColor.black.withAlphaComponent(0.8)
        titleLabel.shadowOffset = CGSize(width: -1, height: 1)
#else
        titleLabel.numberOfLines = 0
#endif
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textAlignment = .center
#if os(iOS)
        titleLabel.font = titleLabel.font.withSize(12)
#endif
        if #available(iOS 9.0, *) {
            titleLabel.allowsDefaultTighteningForTruncation = true
        }
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85
        if PVSettingsModel.sharedInstance().showGameTitles {
            contentView.addSubview(titleLabel ?? UIView())
        }
        contentView.addSubview(imageView ?? UIView())
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func image(withText text: String) -> UIImage? {
        if text == "" {
            let backgroundColor: UIColor = UIColor(white: 0.9, alpha: 0.9)
            return UIImage.image(withSize: CGSize(width: CGFloat(PVThumbnailMaxResolution), height: CGFloat(PVThumbnailMaxResolution)), color: backgroundColor, text: NSAttributedString(string: ""))
        }
            // TODO: To be replaced with the correct system placeholder
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 30.0), NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.foregroundColor: UIColor.gray])
        let backgroundColor: UIColor = UIColor(white: 0.9, alpha: 0.9)
        let missingArtworkImage = UIImage.image(withSize: CGSize(width: CGFloat(PVThumbnailMaxResolution), height: CGFloat(PVThumbnailMaxResolution)), color: backgroundColor, text: attributedText)
        return missingArtworkImage
    }
    
    deinit {
        operation?.cancel()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
#if os(tvOS)
        let titleTransform: CGAffineTransform = titleLabel.transform
        if isFocused {
            titleLabel.transform = .identity
        }
        contentView.bringSubview(toFront: titleLabel ?? UIView())
        titleLabel.sizeToFit()
        titleLabel.setWidth(contentView.bounds.size.width)
        titleLabel.setOriginX(0)
        titleLabel.setOriginY(imageView.frame.maxY)
        titleLabel.transform = titleTransform
#else
        var imageHeight: CGFloat = frame.size.height
        if PVSettingsModel.sharedInstance().showGameTitles {
            imageHeight -= 44
        }
#endif
    }
    
#if os(tvOS)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({() -> Void in
            if self.isFocused {
                var transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                transform = transform.translatedBy(x: 0, y: 40)
                self.titleLabel.alpha = 1
                self.titleLabel.transform = transform
            }
            else {
                self.titleLabel.alpha = 0
                self.titleLabel.transform = .identity
            }
        }) {() -> Void in }
    }
#endif
}
