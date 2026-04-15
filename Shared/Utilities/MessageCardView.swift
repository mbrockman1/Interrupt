import SwiftUI

struct MessageCardView: View {
    let message: InterruptMessage
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    
    // Split the text for better visual hierarchy
    var splitText: (quote: String, author: String?) {
        let parts = message.text.components(separatedBy: "\n— ")
        if parts.count > 1 {
            return (parts[0], "— " + parts[1])
        }
        return (message.text, nil)
    }
    
    var body: some View {
        ZStack {
//            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // ORGANIC BLOBS (Headspace vibe)
            GeometryReader { geo in
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.1)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                
                Spacer()
                
                // TEXT HIERARCHY
                VStack(spacing: 20) {
                    Text(splitText.quote)
                        .font(.system(size: 32, weight: .medium))
                        .multilineTextAlignment(.center)
                    
                    if let author = splitText.author {
                        Text(author)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.secondary) // Softer color, smaller text
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(30)
                .opacity(animateIn ? 1.0 : 0.0)
                .offset(y: animateIn ? 0 : 20)
                
                Text(message.typeRaw.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .opacity(animateIn ? 1.0 : 0.0)
                
                Spacer()
                
                Text("Take a deep breath...")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
}
