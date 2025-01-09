import SwiftUI
 



/// A reusable slider control for floating point values
/// Used throughout TombolaView to control physics parameters
struct SliderControl: View {
    /// Title displayed above the slider
    let title: String
    /// Binding to the controlled value (allows two-way updates)
    let value: Binding<CGFloat>
    /// Valid range for the value
    let range: ClosedRange<CGFloat>
    /// Step size for value changes
    let step: CGFloat
    /// String format for displaying the value (e.g., "%.2f")
    let format: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
            }
            .font(.system(size: 14, weight: .medium))
            Slider(value: value, in: range, step: step)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// A reusable slider control for integer values
/// Similar to SliderControl but specifically for whole numbers
struct IntSliderControl: View {
    /// Title displayed above the slider
    let title: String
    /// Binding to the controlled integer value
    let value: Binding<Int>
    /// Valid range for the value
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .monospacedDigit()
            }
            .font(.system(size: 14, weight: .medium))
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
