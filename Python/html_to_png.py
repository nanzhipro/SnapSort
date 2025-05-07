#!/usr/bin/env python3
import os
import glob
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from PIL import Image
import io

# 配置
html_dir = '../HTML'
output_dir = '../HTML/imgs'
# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 获取所有HTML文件
html_files = glob.glob(f"{html_dir}/*.html")

print(f"找到 {len(html_files)} 个HTML文件")

# 设置Chrome选项
chrome_options = Options()
chrome_options.add_argument("--headless=new")  # 新的无头模式
chrome_options.add_argument("--window-size=1920,1080")  # 设置窗口大小，保证高清
chrome_options.add_argument("--hide-scrollbars")  # 隐藏滚动条
chrome_options.add_argument("--disable-extensions")  # 禁用扩展
chrome_options.add_argument("--disable-gpu")  # 禁用GPU加速

# 初始化WebDriver
service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=chrome_options)

try:
    # 遍历每个HTML文件并转换为PNG
    for html_file in html_files:
        filename = os.path.basename(html_file)
        name_without_ext = os.path.splitext(filename)[0]
        output_file = f"{output_dir}/{name_without_ext}.png"
        
        print(f"正在转换: {html_file} -> {output_file}")
        
        # 加载HTML文件
        html_path = os.path.abspath(html_file)
        driver.get(f"file://{html_path}")
        
        # 等待页面加载完成
        time.sleep(2)
        
        # 获取页面大小
        total_height = driver.execute_script("return document.body.scrollHeight")
        total_width = driver.execute_script("return document.body.scrollWidth")
        
        # 调整窗口大小以适应整个页面内容
        driver.set_window_size(total_width, total_height)
        
        # 再次等待确保页面完全渲染
        time.sleep(1)
        
        # 截取整个页面
        screenshot = driver.get_screenshot_as_png()
        
        # 保存图片为PNG
        with open(output_file, 'wb') as f:
            f.write(screenshot)
        
        print(f"成功转换: {output_file}")
except Exception as e:
    print(f"发生错误: {e}")
finally:
    # 关闭浏览器
    driver.quit()

print("所有转换任务完成") 