# calculator_app.py
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.scrollview import ScrollView
from kivy.uix.widget import Widget
from kivy.graphics import Color, Rectangle
from kivy.core.window import Window
from kivy.metrics import dp
import math

# 设置窗口大小模拟手机屏幕
Window.size = (360, 640)  # 标准手机分辨率


class CalculatorButton(Button):
    """自定义计算器按钮"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.font_size = dp(24)
        self.background_color = (0.2, 0.2, 0.2, 1)
        self.background_normal = ''
        self.color = (1, 1, 1, 1)

    def on_size(self, *args):
        """设置圆角按钮"""
        self.canvas.before.clear()
        with self.canvas.before:
            Color(*self.background_color)
            Rectangle(pos=self.pos, size=self.size, radius=[dp(15)])


class CalculatorApp(App):
    def build(self):
        self.title = "Python手机计算器"
        self.history = []  # 计算历史
        self.current_input = ""
        self.result_displayed = False
        self.last_operator = None

        # 主布局
        main_layout = BoxLayout(orientation='vertical', spacing=dp(10), padding=dp(10))

        # 设置背景色
        with main_layout.canvas.before:
            Color(0.1, 0.1, 0.1, 1)
            self.rect = Rectangle(size=Window.size, pos=main_layout.pos)

        # 历史记录显示区域
        history_scroll = ScrollView(size_hint=(1, 0.2))
        self.history_label = Label(
            text="",
            font_size=dp(16),
            color=(0.7, 0.7, 0.7, 1),
            size_hint_y=None,
            halign='right',
            valign='top'
        )
        self.history_label.bind(size=self.history_label.setter('text_size'))
        self.history_label.height = dp(100)
        history_scroll.add_widget(self.history_label)

        # 当前输入显示
        self.display = TextInput(
            text="0",
            font_size=dp(48),
            readonly=True,
            halign='right',
            background_color=(0.15, 0.15, 0.15, 1),
            foreground_color=(1, 1, 1, 1),
            size_hint=(1, 0.3),
            padding=[dp(20), dp(20)],
            cursor_color=(1, 1, 1, 1)
        )

        # 按钮布局
        buttons_layout = GridLayout(cols=4, rows=5, spacing=dp(10), size_hint=(1, 0.6))

        # 按钮定义
        buttons = [
            ('C', '±', '%', '÷'),
            ('7', '8', '9', '×'),
            ('4', '5', '6', '-'),
            ('1', '2', '3', '+'),
            ('0', '.', '⌫', '=')
        ]

        # 创建按钮
        for row in buttons:
            for text in row:
                btn = CalculatorButton(text=text)

                # 设置不同按钮的颜色
                if text in ['C', '±', '%', '⌫']:
                    btn.background_color = (0.3, 0.3, 0.3, 1)  # 灰色功能键
                elif text in ['÷', '×', '-', '+', '=']:
                    btn.background_color = (1, 0.6, 0, 1)  # 橙色运算符
                else:
                    btn.background_color = (0.4, 0.4, 0.4, 1)  # 灰色数字键

                # 数字0特殊处理（占两列）
                if text == '0':
                    btn.size_hint_x = 2
                    btn.text_size = (btn.width, None)
                    btn.halign = 'left'
                    btn.padding = [dp(40), 0]
                else:
                    btn.size_hint_x = 1

                btn.bind(on_press=self.on_button_press)
                buttons_layout.add_widget(btn)

        # 添加所有部件
        main_layout.add_widget(history_scroll)
        main_layout.add_widget(self.display)
        main_layout.add_widget(buttons_layout)

        return main_layout

    def on_button_press(self, instance):
        """处理按钮点击"""
        text = instance.text

        if text == 'C':
            self.clear_all()
        elif text == '⌫':
            self.backspace()
        elif text == '±':
            self.toggle_sign()
        elif text == '%':
            self.percentage()
        elif text == '=':
            self.calculate()
        elif text in ['+', '-', '×', '÷']:
            self.add_operator(text)
        elif text == '.':
            self.add_decimal()
        else:  # 数字
            self.add_number(text)

    def clear_all(self):
        """清除所有"""
        self.display.text = "0"
        self.current_input = ""
        self.result_displayed = False
        self.update_history("清空")

    def backspace(self):
        """删除最后一个字符"""
        if self.display.text != "0":
            if len(self.display.text) > 1:
                self.display.text = self.display.text[:-1]
            else:
                self.display.text = "0"

    def toggle_sign(self):
        """切换正负号"""
        if self.display.text != "0":
            if self.display.text.startswith('-'):
                self.display.text = self.display.text[1:]
            else:
                self.display.text = '-' + self.display.text

    def percentage(self):
        """百分比计算"""
        try:
            value = float(self.display.text)
            result = value / 100
            self.display.text = self.format_number(result)
            self.update_history(f"{value}% = {result}")
        except:
            self.display.text = "错误"

    def add_operator(self, operator):
        """添加运算符"""
        if self.result_displayed:
            self.current_input = self.display.text
            self.result_displayed = False

        if self.current_input:
            # 如果有未完成的计算，先计算
            self.calculate()

        self.current_input = self.display.text
        self.last_operator = operator
        self.display.text = "0"

    def add_decimal(self):
        """添加小数点"""
        if '.' not in self.display.text:
            self.display.text += '.'
            self.result_displayed = False

    def add_number(self, number):
        """添加数字"""
        if self.result_displayed or self.display.text == "0":
            self.display.text = number
            self.result_displayed = False
        else:
            self.display.text += number

    def calculate(self):
        """执行计算"""
        try:
            current = float(self.display.text)

            if self.current_input and self.last_operator:
                previous = float(self.current_input)
                operator_symbol = self.last_operator

                # 执行计算
                if operator_symbol == '+':
                    result = previous + current
                elif operator_symbol == '-':
                    result = previous - current
                elif operator_symbol == '×':
                    result = previous * current
                elif operator_symbol == '÷':
                    if current == 0:
                        raise ZeroDivisionError
                    result = previous / current

                # 显示结果
                formatted_result = self.format_number(result)
                self.display.text = formatted_result

                # 更新历史
                history_entry = f"{previous} {operator_symbol} {current} = {formatted_result}"
                self.update_history(history_entry)

                # 重置状态
                self.current_input = ""
                self.last_operator = None
                self.result_displayed = True
        except ZeroDivisionError:
            self.display.text = "除零错误"
            self.current_input = ""
            self.last_operator = None
        except:
            self.display.text = "错误"

    def format_number(self, number):
        """格式化数字显示"""
        if number.is_integer():
            return str(int(number))
        else:
            # 限制小数位数
            return f"{number:.10f}".rstrip('0').rstrip('.')

    def update_history(self, entry):
        """更新历史记录"""
        self.history.insert(0, entry)
        if len(self.history) > 10:  # 只保留最近10条
            self.history.pop()

        # 更新显示
        history_text = "\n".join(self.history)
        self.history_label.text = history_text

    def on_start(self):
        """应用启动时调用"""
        self.icon = 'calculator_icon.png'  # 需要图标文件

    def on_pause(self):
        """应用暂停时（Android/iOS）"""
        return True

    def on_resume(self):
        """应用恢复时（Android/iOS）"""
        pass


if __name__ == '__main__':
    CalculatorApp().run()