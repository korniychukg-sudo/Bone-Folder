import SwiftUI

enum Plates {
    private static var cache: [String: UIImage] = [:]

    static func load(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        if cache.count > 40 { cache.removeAll() }
        cache[name] = image
        return image
    }

    static func exists(_ name: String) -> Bool {
        Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art") != nil
    }
}

struct PlateBox: View {
    let name: String
    var height: CGFloat
    var corner: CGFloat = 4
    var fit: Bool = false

    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let image = Plates.load(name) {
                        if fit {
                            Image(uiImage: image).resizable().scaledToFit()
                        } else {
                            Image(uiImage: image).resizable().scaledToFill()
                        }
                    } else {
                        Quire.pageDeep
                    }
                }
            )
            .frame(height: height)
            .clipped()
            .cornerRadius(corner)
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Quire.ink.opacity(0.16), lineWidth: 0.8)
            )
    }
}

struct PlateFill: View {
    let name: String
    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let image = Plates.load(name) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Quire.pageDeep
                    }
                }
            )
            .clipped()
    }
}

struct SheetCard<Content: View>: View {
    var padding: CGFloat = 15
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Quire.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Quire.ink.opacity(0.13), lineWidth: 0.9)
                    )
                    .shadow(color: Quire.ink.opacity(0.07), radius: 5, x: 0, y: 3)
            )
    }
}

struct HeadRule: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(text.uppercased())
                .font(Quire.title(11.5))
                .tracking(1.6)
                .foregroundColor(Quire.inkSoft)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(Quire.ink.opacity(0.17))
                .frame(height: 0.8)
            if let trailing = trailing {
                Text(trailing)
                    .font(Quire.body(11.5))
                    .foregroundColor(Quire.inkFaint)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

struct SealButton: View {
    let title: String
    var tone: Color = Quire.ink
    var filled: Bool = true
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: { if enabled { Knock.light(); action() } }) {
            Text(title)
                .font(Quire.title(15))
                .foregroundColor(filled ? Quire.card : tone)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(filled ? tone : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tone.opacity(filled ? 0 : 0.55), lineWidth: 1.1)
                        )
                )
                .opacity(enabled ? 1 : 0.42)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct MeterBar: View {
    var label: String
    var value: Double
    var tone: Color = Quire.brass
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                Spacer()
                Text("\(Int(min(1, max(0, value)) * 100))")
                    .font(Quire.title(12.5)).foregroundColor(Quire.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Quire.ink.opacity(0.10))
                    Capsule().fill(tone)
                        .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, value)))))
                }
            }
            .frame(height: 6)
            if let caption = caption {
                Text(caption).font(Quire.note(11)).foregroundColor(Quire.inkFaint)
            }
        }
    }
}

struct NoticeBar: View {
    var text: String
    var tone: Color = Quire.warn
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(spacing: 11) {
            Rectangle().fill(tone).frame(width: 3)
            Text(text)
                .font(Quire.body(12.5))
                .foregroundColor(Quire.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let action = action {
                Button(action: { Knock.light(); action.1() }) {
                    Text(action.0)
                        .font(Quire.title(11.5))
                        .foregroundColor(tone)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(tone.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).fill(tone.opacity(0.09)))
    }
}

struct SheetHead: View {
    var title: String
    var subtitle: String? = nil
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Quire.title(19)).foregroundColor(Quire.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = subtitle {
                    Text(subtitle).font(Quire.note(12.5)).foregroundColor(Quire.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 10)
            Button(action: { Knock.light(); onClose() }) {
                CrossGlyph(size: 16, color: Quire.inkSoft)
                    .padding(9)
                    .background(Circle().fill(Quire.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Quire.gutter)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

struct CountTile: View {
    var value: String
    var label: String
    var tone: Color = Quire.ink

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Quire.title(17))
                .foregroundColor(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(Quire.body(8.5))
                .tracking(1.0)
                .foregroundColor(Quire.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 6).fill(Quire.ink.opacity(0.045)))
    }
}

struct StampTag: View {
    var text: String
    var tone: Color
    var body: some View {
        Text(text.uppercased())
            .font(Quire.title(9.5))
            .tracking(1.3)
            .foregroundColor(tone)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(tone.opacity(0.7), lineWidth: 1))
    }
}

struct Column<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 15) { content() }
                .frame(maxWidth: Quire.isPad ? 720 : .infinity)
            Spacer(minLength: 0)
        }
    }
}

struct BandPicker: View {
    var titles: [String]
    @Binding var index: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(titles.enumerated()), id: \.offset) { i, title in
                Button(action: { Knock.light(); withAnimation(.easeOut(duration: 0.2)) { index = i } }) {
                    Text(title)
                        .font(Quire.title(11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .foregroundColor(index == i ? Quire.card : Quire.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 5)
                                        .fill(index == i ? Quire.ink : Quire.ink.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ChoiceRow<T: Hashable>: View {
    var items: [T]
    var label: (T) -> String
    @Binding var selection: T
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    let on = item == selection
                    Button(action: { Knock.light(); withAnimation(.easeOut(duration: 0.18)) { selection = item } }) {
                        Text(label(item))
                            .font(Quire.title(11.5))
                            .foregroundColor(on ? Quire.card : Quire.inkSoft)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 5).fill(on ? Quire.walnut : Quire.ink.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct Celebration: View {
    var title: String
    var line: String
    var word: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Quire.ink.opacity(0.55).ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack(spacing: 12) {
                Text(title.uppercased()).font(Quire.title(11)).tracking(2).foregroundColor(Quire.inkFaint)
                Text(word).font(Quire.title(26)).foregroundColor(Quire.ink)
                    .multilineTextAlignment(.center)
                Text(line).font(Quire.body(14)).foregroundColor(Quire.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                SealButton(title: "Shelve it", tone: Quire.walnut) { onClose() }
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(RoundedRectangle(cornerRadius: 10).fill(Quire.card))
            .padding(Quire.gutter)
        }
    }
}

struct BackChevron: View {
    var label: String = "Back"
    var action: () -> Void
    var body: some View {
        Button(action: { Knock.light(); action() }) {
            HStack(spacing: 4) {
                ChevGlyph(size: 15, color: Quire.inkSoft)
                Text(label).font(Quire.body(13.5)).foregroundColor(Quire.inkSoft)
            }
        }
        .buttonStyle(.plain)
    }
}
