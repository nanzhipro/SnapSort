# HTML转PNG工具

本目录包含将HTML文件转换为高质量PNG图片的Python工具。这些工具使用Selenium和Pillow库实现网页截图和图像处理。

## 环境要求

在使用这些工具前，请确保已安装以下Python依赖：

```bash
pip3 install selenium pillow webdriver-manager
```

此外，您需要安装Chrome浏览器，因为工具使用Chrome WebDriver进行页面渲染。

## 工具说明

本目录包含以下工具：

1. `html_to_png.py` - 基础HTML转PNG工具
2. `html_to_png_enhanced.py` - 增强版转换工具，生成更高质量的PNG图片
3. `view_png_images.py` - PNG图片预览工具

## 使用方法

### 1. 将HTML转换为PNG

运行以下命令将HTML目录下的所有HTML文件转换为PNG图片：

```bash
cd Python
python3 html_to_png.py
```

生成的PNG图片将保存在`HTML/imgs`目录中。

### 2. 生成高质量PNG图片

如果需要更高质量的PNG图片，可以运行增强版工具：

```bash
cd Python
python3 html_to_png_enhanced.py
```

增强版工具使用2倍DPI缩放和更低的压缩级别，生成分辨率更高、质量更好的PNG图片。

### 3. 查看生成的PNG图片

可以使用图片预览工具查看生成的PNG图片：

```bash
cd Python
python3 view_png_images.py
```

这将打开一个简单的图片查看器，您可以通过"上一张"和"下一张"按钮浏览所有PNG图片。

## 转换过程

1. 工具扫描指定目录中的所有HTML文件
2. 使用Chrome无头浏览器加载每个HTML文件
3. 调整浏览器窗口大小以适应页面内容
4. 捕获整个页面的截图
5. 处理截图并保存为高质量PNG格式
6. 输出转换结果到控制台

## 注意事项

- 确保HTML文件中的相对路径资源正确，以便正确渲染
- 根据需要调整脚本中的等待时间，以确保页面完全加载后再截图
- 如果遇到内存问题，可以适当调整脚本中的参数

## 故障排除

如果遇到问题：

1. 确认Chrome浏览器已正确安装
2. 检查是否已安装所有必要的Python依赖
3. 确保HTML文件格式正确且能在浏览器中正常显示
4. 如果截图不完整，尝试增加等待时间允许页面完全渲染
