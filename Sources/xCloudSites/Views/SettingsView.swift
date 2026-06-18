import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    let onClose: () -> Void
    @State private var draftToken: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("xCloud API Token")
                    .font(.headline)
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Create a token in your xCloud account settings (read scope lists sites; write scope is required for Magic Login).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("Paste token…", text: $draftToken)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))

            Link("How to access the xCloud API",
                 destination: URL(string: "https://xcloud.host/docs/how-to-access-the-xcloud-api/")!)
                .font(.caption2)

            HStack {
                if state.hasToken {
                    Button("Remove", role: .destructive) {
                        state.clearToken()
                        draftToken = ""
                        onClose()
                    }
                    .controlSize(.small)
                }
                Spacer()
                Button("Cancel") { onClose() }
                    .controlSize(.small)
                Button("Save") {
                    state.saveToken(draftToken)
                    onClose()
                    Task { await state.loadSites() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.defaultAction)
                .disabled(draftToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Quit xCloud Sites") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { draftToken = state.token }
    }
}
