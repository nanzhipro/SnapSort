# SnapSort 项目

## HTML转PNG工具

本项目包含用于将HTML页面转换为PNG图片的实用工具。使用这些工具，您可以将HTML页面渲染为高质量的PNG图片，以便分享或存档。

### 工具位置

所有工具脚本都位于 `Python/` 目录下。请参阅该目录中的 [README.md](Python/README.md) 文件，了解详细的使用说明。

### 快速开始

要将HTML文件转换为PNG图片：

```bash
cd Python
python3 html_to_png_enhanced.py
```

生成的PNG图片将保存在 `HTML/imgs/` 目录中。

### 查看生成的图片

可以使用内置的图片查看器查看生成的PNG图片：

```bash
cd Python
python3 view_png_images.py
```

### 依赖项

使用工具前，请确保已安装所需的Python依赖：

```bash
pip3 install selenium pillow webdriver-manager
```

此外，您需要安装Chrome浏览器，因为工具使用Chrome WebDriver进行页面渲染。
