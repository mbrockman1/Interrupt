import SwiftUI

struct WatchMessageCardView: View {
    let message: InterruptMessage
    @Environment(\.dismiss) private var dismiss
    
    var splitText: (quote: String, author: String?) {
        let parts = message.text.components(separatedBy: "\n— ")
        if parts.count > 1 { return (parts[0], "— " + parts[1]) }
        return (message.text, nil)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(splitText.quote)
                    .font(.system(size: 20, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 8)
                
                if let author = splitText.author {
                    Text(author)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            
//                Button(action: { dismiss() }) {
//                    Text("Done")
//                        .fontWeight(.bold)
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.accentColor)
//                .padding(.bottom, 24)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}
