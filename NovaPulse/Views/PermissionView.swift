import SwiftUI

struct PermissionView: View {
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo / Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient.heartGradient)
                        .frame(width: 120, height: 120)
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }
                .shadow(color: .npRedFallback.opacity(0.5), radius: 30)

                VStack(spacing: 12) {
                    Text("NovaPulse")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .npBlueFallback],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Biometric Intelligence Dashboard")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 18) {
                    permissionRow(icon: "heart.fill",      color: .npRedFallback,   text: "Heart Rate & HRV")
                    permissionRow(icon: "figure.walk",     color: .npGreenFallback, text: "Steps & Activity")
                    permissionRow(icon: "moon.zzz.fill",   color: .npBlueFallback,  text: "Sleep Analysis")
                    permissionRow(icon: "lungs.fill",      color: .npBlueFallback,  text: "Blood Oxygen")
                    permissionRow(icon: "flame.fill",      color: .npOrangeFallback, text: "Calories Burned")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    healthKitService.requestAuthorization()
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                        Text("Connect Apple Health")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.heartGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .npRedFallback.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func permissionRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(.white.opacity(0.85))
                .font(.body)
        }
    }
}
