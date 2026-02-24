import SwiftUI

/// Represents the visual configuration and ephemeral state of the 2.0 Avatar.
public struct AvatarState: Equatable {
    
    // MARK: - Persistent Configuration (The "Look")
    
    /// The base tint applied to the `.colorMultiply` layer of the avatar.
    public var skinTone: Color
    
    /// The name of the SVG asset representing the hair layer.
    public var hairStyle: String
    
    /// The name of the SVG asset representing the outfit layer.
    public var outfit: String
    
    // MARK: - Ephemeral State (The "Reaction")
    
    /// The expression asset (e.g., "eyes_open", "eyes_closed", "eyes_winking")
    public var expression: String
    
    /// Any situational overlay (e.g., "effect_cleanser", "effect_mask")
    public var activeOverlay: String?
    
    /// The intensity level (0.0 to 1.0) of the background radiant aura.
    public var glowIntensity: Double
    
    /// The brightness boost (0.0 to 1.0) applied to the avatar's skin from progress.
    public var skinBrightness: Double
    
    /// Whether the voice-reactive aura should be pulsing.
    public var isVoiceListening: Bool
    
    public init(
        skinTone: Color = DesignColors.sandalwoodMedium,
        hairStyle: String = "avatar_hair_default",
        outfit: String = "avatar_outfit_robe",
        expression: String = "avatar_eyes_open",
        activeOverlay: String? = nil,
        glowIntensity: Double = 0.0,
        skinBrightness: Double = 0.0,
        isVoiceListening: Bool = false
    ) {
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.outfit = outfit
        self.expression = expression
        self.activeOverlay = activeOverlay
        self.glowIntensity = glowIntensity
        self.skinBrightness = skinBrightness
        self.isVoiceListening = isVoiceListening
    }
}
