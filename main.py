from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.core.window import Window
from kivy.utils import platform

# 适配手机比例：仅在桌面环境设置窗口大小，Android 上由设备决定
if platform != "android":
    Window.size = (360, 640)

class CalcBox(BoxLayout):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.orientation = "vertical"
        self.spacing = 12
        self.padding = 20

        # 显示屏幕
        self.screen = TextInput(
            readonly=True,
            font_size=44,
            halign="right",
            size_hint_y=0.18
        )
        self.add_widget(self.screen)

        # 按键布局
        key_list = [
            ["7", "8", "9", "/", "C"],
            ["4", "5", "6", "*", "←"],
            ["1", "2", "3", "-"],
            [".", "0", "=", "+"]
        ]
        for row in key_list:
            row_box = BoxLayout(spacing=10, size_hint_y=0.15)
            for text in row:
                btn = Button(text=text, font_size=24)
                btn.bind(on_press=self.click_btn)
                row_box.add_widget(btn)
            self.add_widget(row_box)

    def click_btn(self, btn):
        text = btn.text
        cur = self.screen.text
        if text == "C":
            self.screen.text = ""
        elif text == "←":
            self.screen.text = cur[:-1]
        elif text == "=":
            try:
                res = eval(cur)
                self.screen.text = str(res)
            except Exception:
                self.screen.text = "计算错误"
        else:
            self.screen.text += text

class CalculatorApp(App):
    def build(self):
        self.title = "手机计算器"
        return CalcBox()

if __name__ == "__main__":
    CalculatorApp().run()