import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame

        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        // macOS 창 배경 투명화
        self.isOpaque = false
        self.backgroundColor = NSColor.clear

        // 창 그림자 유지
        self.hasShadow = true

        // Flutter 뷰의 레이어는 Flutter 엔진이 관리하도록 유지

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}