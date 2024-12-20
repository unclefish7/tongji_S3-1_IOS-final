//
//  RegionalGradientView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

enum HorizontalPosition: String, CaseIterable, Identifiable {
    case left, right
    var id: String { self.rawValue }
}

enum VerticalPosition: String, CaseIterable, Identifiable {
    case top, bottom
    var id: String { self.rawValue }
}

enum RadialPosition: String, CaseIterable, Identifiable {
    case center, edge
    var id: String { self.rawValue }
}

struct RegionalGradientView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    @State private var horizontalGradient = false
    @State private var verticalGradient = false
    @State private var radialGradient = false
    @State private var leftHorizontalGradient: Float = 0.0
    @State private var rightHorizontalGradient: Float = 1.0
    @State private var topVerticalGradient: Float = 0.0
    @State private var bottomVerticalGradient: Float = 1.0
    @State private var centerRadialGradient: Float = 0.0
    @State private var edgeRadialGradient: Float = 1.0
    @State private var selectedTab = 0  // 添加选项卡状态
    @State private var activePopover: (String, Binding<Float>)? // 添加此状态来追踪当前活动的气泡
    @State private var popoverPosition: CGPoint = .zero // 添加此状态来存储气泡位置
    @State private var screenSize: CGSize = .zero // 添加屏幕尺寸状态

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // 顶部的图片展示区域
                TabView(selection: $selectedTab) {
                    // 原始融合图片
                    if let image = viewModel.blendedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(0)
                    }
                    
                    // 渐变效果图片
                    if let gradientImage = viewModel.gradientImage {
                        Image(uiImage: gradientImage)
                            .resizable()
                            .scaledToFit()
                            .tag(1)
                    } else {
                        Color.gray.opacity(0.2)
                            .overlay(Text("应用渐变后的效果将显示在这里"))
                            .tag(1)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: UIScreen.main.bounds.height * 0.4)  // 固定高度为屏幕高度的40%
                
                // 分段控制器用于切换图片
                Picker("显示模式", selection: $selectedTab) {
                    Text("原始图片").tag(0)
                    Text("渐变效果").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // 新的渐变控制面板布局
                VStack(spacing: 12) {
                    GradientControlRow(
                        title: "横向渐变",
                        isEnabled: $horizontalGradient,
                        controls: [
                            ("左边界", $leftHorizontalGradient),
                            ("右边界", $rightHorizontalGradient)
                        ],
                        activePopover: $activePopover,
                        popoverPosition: $popoverPosition
                    )
                    
                    GradientControlRow(
                        title: "纵向渐变",
                        isEnabled: $verticalGradient,
                        controls: [
                            ("上边界", $topVerticalGradient),
                            ("下边界", $bottomVerticalGradient)
                        ],
                        activePopover: $activePopover,
                        popoverPosition: $popoverPosition
                    )
                    
                    GradientControlRow(
                        title: "径向渐变",
                        isEnabled: $radialGradient,
                        controls: [
                            ("中心", $centerRadialGradient),
                            ("边缘", $edgeRadialGradient)
                        ],
                        activePopover: $activePopover,
                        popoverPosition: $popoverPosition
                    )
                }
                .padding()
                
                Spacer()
                
                // 底部按钮组
                VStack(spacing: 10) {
                    Button("应用渐变") {
                        if let image = viewModel.blendedImage {
                            viewModel.gradientImage = viewModel.applyGradient(
                                to: image,
                                horizontal: horizontalGradient,
                                vertical: verticalGradient,
                                radial: radialGradient,
                                leftHorizontal: leftHorizontalGradient,
                                rightHorizontal: rightHorizontalGradient,
                                topVertical: topVerticalGradient,
                                bottomVertical: bottomVerticalGradient,
                                centerRadial: centerRadialGradient,
                                edgeRadial: edgeRadialGradient
                            )
                            selectedTab = 1
                        }
                    }
                    .buttonStyle(GradientButtonStyle())
                    
                    Button("完成") {
                        if let gradientImage = viewModel.gradientImage {
                            viewModel.finalImage = viewModel.resizeImage(
                                image: gradientImage,
                                targetSize: viewModel.originalImageSize ?? gradientImage.size
                            )
                            path.append(.final)
                        }
                    }
                    .buttonStyle(CompletionButtonStyle())
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            // 在最上层显示气泡
            if let (title, value) = activePopover {
                let popoverHeight: CGFloat = 30 // 减小气泡高度
                let popoverWidth: CGFloat = 200
                let verticalOffset: CGFloat = -70 // 改为负值，让气泡向上偏移
                
                // 计算安全的显示位置
                let safeX = min(max(popoverWidth/2, popoverPosition.x), screenSize.width - popoverWidth/2)
                let safeY = popoverPosition.y + verticalOffset
                
                SliderPopover(value: value, isShowing: Binding(
                    get: { activePopover != nil },
                    set: { if !$0 { activePopover = nil } }
                ))
                .position(x: safeX, y: safeY)
                .transition(.scale)
                .animation(.easeInOut(duration: 0.2), value: activePopover != nil)
                .zIndex(999)
            }
        }
        .coordinateSpace(name: "mainView")
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    screenSize = geometry.size
                }
            }
        )
        .navigationTitle("区域渐变")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.blendedImage == nil {
                viewModel.blendedImage = viewModel.originalContentImage
            }
        }
    }
}

// 新的渐变控制行视图
struct GradientControlRow: View {
    let title: String
    @Binding var isEnabled: Bool
    let controls: [(String, Binding<Float>)]
    @Binding var activePopover: (String, Binding<Float>)?
    @Binding var popoverPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 左侧标题和开关
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)  // 确保文本不会被截断
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()  // 隐藏开关的标签
                
                Spacer()
                
                // 右侧控制按钮
                if isEnabled {
                    HStack(spacing: 8) {
                        ForEach(controls, id: \.0) { control in
                            GradientValueButton(
                                title: control.0,
                                value: control.1,
                                onTap: { position in
                                    popoverPosition = position
                                    activePopover = control
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// 修改渐变值调节按钮
struct GradientValueButton: View {
    let title: String
    @Binding var value: Float
    let onTap: (CGPoint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                let frame = geometry.frame(in: .global)
                onTap(CGPoint(x: frame.midX, y: frame.maxY))
            }) {
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Text("\(Int(value * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .frame(width: 80, height: 35) // 减小高度
    }
}

// 修改滑动条气泡视图
struct SliderPopover: View {
    @Binding var value: Float
    @Binding var isShowing: Bool
    
    private let popoverBackgroundColor = Color(.systemGray6)  // 使用系统灰色背景
    
    var body: some View {
        VStack(spacing: 0) {
            // 小三角形
            Triangle()
                .fill(popoverBackgroundColor)
                .frame(width: 10, height: 5)
                .offset(y: -3)
            
            // 主要内容
            HStack(spacing: 8) {
                Slider(value: $value, in: 0...1)
                    .frame(width: 120)
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(popoverBackgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .onTapGesture {} // 防止点击穿透
        .onAppear {
            setupOutsideTapHandler()
        }
    }
    
    private func setupOutsideTapHandler() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let tap = UITapGestureRecognizer(target: Dispatcher.shared, action: #selector(Dispatcher.shared.handleTap))
            tap.cancelsTouchesInView = false
            UIApplication.shared.windows.first?.addGestureRecognizer(tap)
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DismissPopover"),
                object: nil,
                queue: .main
            ) { _ in
                isShowing = false
            }
        }
    }
}

// 用于绘制小三角形的形状
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// 用于处理外部点击的辅助类
class Dispatcher: NSObject {
    static let shared = Dispatcher()
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        NotificationCenter.default.post(name: NSNotification.Name("DismissPopover"), object: nil)
    }
}

extension View {
    func dismissOnTapOutside(_ isPresented: Binding<Bool>) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissPopover"))) { _ in
            isPresented.wrappedValue = false
        }
    }
}

// 添加渐变按钮样式
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// 添加完成按钮样式
struct CompletionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

