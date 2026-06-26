# hello_simple.py
import kivy
kivy.require('2.0.0')  # 指定Kivy版本

from kivy.app import App
from kivy.uix.label import Label

class MyApp(App):
    def build(self):
        return Label(text='Hello Kivy!', font_size=50)

if __name__ == '__main__':
    MyApp().run()

