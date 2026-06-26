import tkinter as tk

# 创建主窗口
root = tk.Tk()
root.title("Python图形计算器")
root.geometry("300x400")

# 输入显示框
text = tk.StringVar()
entry = tk.Entry(root, textvariable=text, font=("Arial", 24), justify="right")
entry.pack(fill="both", padx=10, pady=10)

# 按钮点击事件
def btn_click(num):
    text.set(text.get() + str(num))

# 清空屏幕
def clear():
    text.set("")

# 等于计算
def equal():
    try:
        # eval自动解析四则运算表达式
        res = eval(text.get())
        text.set(res)
    except:
        text.set("计算错误")

# 布局按钮
btn_frame = tk.Frame(root)
btn_frame.pack()

# 按钮列表
buttons = [
    ("7", "8", "9", "/"),
    ("4", "5", "6", "*"),
    ("1", "2", "3", "-"),
    ("0", ".", "C", "+"),
    ("=", "", "", "")
]

# 循环生成按钮
for row_idx, row in enumerate(buttons):
    for col_idx, val in enumerate(row):
        if val == "":
            continue
        if val == "C":
            btn = tk.Button(btn_frame, text=val, width=5, height=2, command=clear, bg="gray")
        elif val == "=":
            btn = tk.Button(btn_frame, text=val, width=22, height=2, command=equal, bg="orange")
            btn.grid(row=row_idx, column=0, columnspan=4, pady=3)
            continue
        else:
            btn = tk.Button(btn_frame, text=val, width=5, height=2, command=lambda v=val: btn_click(v))
        btn.grid(row=row_idx, column=col_idx, padx=3, pady=3)

# 窗口循环
root.mainloop()