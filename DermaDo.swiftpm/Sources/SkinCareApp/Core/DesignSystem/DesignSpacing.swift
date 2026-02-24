import Foundation

/// Mathematical Base-8 Spacing System for DermaDo 2.0
public enum DesignSpacing {
    
    /// 4pt — Inside pills, between an icon and text
    public static let micro: CGFloat = 4.0
    
    /// 8pt — Small control spacing
    public static let small: CGFloat = 8.0
    
    /// 16pt — Padding inside standard cards
    public static let standard: CGFloat = 16.0
    
    /// 24pt — Margins between related standard elements
    public static let medium: CGFloat = 24.0
    
    /// 32pt — Significant separation between distinct blocks
    public static let large: CGFloat = 32.0
    
    /// 48pt — Editorial pacing: Margin between major sections
    public static let editorial: CGFloat = 48.0
    
    /// 64pt — Massive editorial pacing: For heroic space and void appreciation
    public static let heroic: CGFloat = 64.0
}

/// Border Radius System
public enum DesignRadius {
    /// 8pt — Small inputs, inner images
    public static let control: CGFloat = 8.0
    
    /// 16pt — Interactive elements, pills, pickers
    public static let element: CGFloat = 16.0
    
    /// 20pt — Standard cards, floating modules
    public static let container: CGFloat = 20.0
    
    /// 32pt — Massive bottom sheets or hero images
    public static let module: CGFloat = 32.0
}
