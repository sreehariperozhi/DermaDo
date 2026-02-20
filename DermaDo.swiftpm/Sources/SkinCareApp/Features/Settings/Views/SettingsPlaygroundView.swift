import SwiftUI

/// Developer playground for testing Settings features (like Voice Guidance toggle).
public struct SettingsPlaygroundView: View {
    @EnvironmentObject private var voiceManager: VoiceManager
    
    public init() {}
    
    public var body: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: DesignSpacing.heroic) {
                Text("Settings Playground")
                    .font(DesignTypography.titleUI)
                    .foregroundColor(DesignColors.luminousPearl)
                
                // Voice Guidance Toggle Card
                VStack(alignment: .leading, spacing: DesignSpacing.standard) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Voice Guidance")
                                .font(DesignTypography.bodyUI)
                                .foregroundColor(DesignColors.luminousPearl)
                            
                            Text("Your avatar will gently speak routine steps and reminders.")
                                .font(DesignTypography.captionUI)
                                .foregroundColor(DesignColors.liquidSilver)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $voiceManager.isVoiceEnabled)
                            .labelsHidden()
                            .tint(DesignColors.roseGold)
                    }
                    .padding(DesignSpacing.large)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                }
                
                Spacer()
            }
            .padding(DesignSpacing.heroic)
        }
        .colorScheme(.dark)
    }
}
