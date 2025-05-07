#!/usr/bin/env python3
import os
import glob
import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk

class ImageViewer:
    def __init__(self, root, image_files):
        self.root = root
        self.image_files = image_files
        self.current_index = 0
        
        self.root.title("HTML转PNG图片查看器")
        self.root.geometry("1200x800")
        
        # 创建主框架
        self.main_frame = ttk.Frame(self.root)
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # 图片标签
        self.image_label = ttk.Label(self.main_frame)
        self.image_label.pack(fill=tk.BOTH, expand=True)
        
        # 控制框架
        self.control_frame = ttk.Frame(self.root)
        self.control_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # 上一张按钮
        self.prev_button = ttk.Button(self.control_frame, text="上一张", command=self.show_prev_image)
        self.prev_button.pack(side=tk.LEFT, padx=5)
        
        # 文件名标签
        self.file_label = ttk.Label(self.control_frame, text="")
        self.file_label.pack(side=tk.LEFT, padx=20)
        
        # 下一张按钮
        self.next_button = ttk.Button(self.control_frame, text="下一张", command=self.show_next_image)
        self.next_button.pack(side=tk.RIGHT, padx=5)
        
        # 显示第一张图片
        self.show_current_image()
        
    def show_current_image(self):
        if not self.image_files:
            self.file_label.config(text="没有找到图片文件")
            return
            
        file_path = self.image_files[self.current_index]
        file_name = os.path.basename(file_path)
        
        # 加载图片
        img = Image.open(file_path)
        
        # 缩放图片以适应窗口
        width, height = img.size
        max_width = 1180
        max_height = 750
        
        if width > max_width or height > max_height:
            ratio = min(max_width / width, max_height / height)
            new_width = int(width * ratio)
            new_height = int(height * ratio)
            img = img.resize((new_width, new_height), Image.LANCZOS)
        
        # 转换为Tkinter可用的图片
        photo = ImageTk.PhotoImage(img)
        
        # 更新图片和标签
        self.image_label.config(image=photo)
        self.image_label.image = photo  # 防止被垃圾回收
        self.file_label.config(text=f"图片 {self.current_index + 1}/{len(self.image_files)}: {file_name}")
        
    def show_next_image(self):
        if self.current_index < len(self.image_files) - 1:
            self.current_index += 1
            self.show_current_image()
            
    def show_prev_image(self):
        if self.current_index > 0:
            self.current_index -= 1
            self.show_current_image()

def main():
    # 获取所有PNG图片文件
    image_dir = "../HTML/imgs"
    image_files = sorted(glob.glob(f"{image_dir}/*.png"))
    
    if not image_files:
        print("未找到PNG图片文件！")
        return
        
    print(f"找到 {len(image_files)} 个PNG图片文件:")
    for file in image_files:
        print(f"  - {os.path.basename(file)}")
    
    # 创建Tkinter窗口
    root = tk.Tk()
    app = ImageViewer(root, image_files)
    root.mainloop()

if __name__ == "__main__":
    main() 