import SwiftUI

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // MARK: - Background Layer
            DesignColors.voidObsidian.ignoresSafeArea()
            
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -150, y: -250)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignSpacing.large) {
                    
                    // MARK: - Navigation Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignColors.liquidSilver)
                        }
                        .padding(.trailing, DesignSpacing.small)
                        
                        Text("Privacy")
                            .font(DesignTypography.titleUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Spacer()
                    }
                    .padding(.bottom, DesignSpacing.standard)
                    
                    // MARK: - Content
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        Text("DATA & PRIVACY")
                            .font(DesignTypography.microUI)
                            .captionTracking()
                            .foregroundColor(DesignColors.liquidSilver)
                            .padding(.leading, 4)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Your data remains entirely on your device.")
                                .font(DesignTypography.bodyStrongUI)
                                .foregroundColor(DesignColors.luminousPearl)
                                .padding(.bottom, DesignSpacing.small)
                            
                            Text("DermaDo respects your privacy. We do not collect, transmit, or share any personal health or profile information without your explicit consent.")
                                .font(DesignTypography.bodyUI)
                                .foregroundColor(DesignColors.liquidSilver)
                                .lineSpacing(4)
                        }
                        .padding(DesignSpacing.medium)
                        .glassCard()
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, DesignSpacing.large)
                .padding(.top, DesignSpacing.standard)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
