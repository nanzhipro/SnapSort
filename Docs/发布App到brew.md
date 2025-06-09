# 将macOS应用发布到Homebrew - 快速指南

## 前置要求

- DMG格式的应用包（已代码签名）
- 基本的命令行和Git知识
- GitHub账户（用于托管Tap仓库和发布）

## 核心步骤

### 1. 准备DMG文件

- 确保应用已打包为DMG文件，包含`.app`或`.pkg`文件
- 对于简单应用，可使用磁盘工具创建：文件 > 新建映像 > 空白映像

### 2. 发布DMG文件

- 将DMG上传到GitHub Releases获得稳定的下载链接
- 确保是直接下载链接，不需要登录或重定向

### 3. 创建Cask文件

- 计算DMG的SHA256校验和：`shasum -a 256 /path/to/App.dmg`
- 创建名为`app.rb`的文件（替换"app"为你的应用名，全小写）：

```ruby
cask "app" do
  version "1.0.0"
  sha256 "your_checksum_here"
  url "https://github.com/yourusername/yourrepo/releases/download/v1.0.0/App.dmg"
  name "App"
  desc "简短描述"
  homepage "https://yourappwebsite.com"
  app "App.app"  # DMG中的应用路径，如在子目录则为 "Subdir/App.app"
end
```

> 对于pkg安装，使用`pkg "App.pkg"`代替`app`行，并添加卸载信息：
> `uninstall pkgutil: "com.example.app"`

### 4. 测试Cask

```bash
# 安装测试
brew install --cask /path/to/app.rb

# 验证应用是否正确安装到/Applications并能正常运行

# 卸载测试
brew uninstall --cask app
```

### 5. 创建Homebrew Tap

```bash
# 在GitHub创建名为 homebrew-myapps 的仓库
git clone https://github.com/yourusername/homebrew-myapps.git
cd homebrew-myapps
mkdir Casks
cp /path/to/app.rb Casks/
git add Casks/app.rb
git commit -m "Add app cask v1.0.0"
git push origin main
```

### 6. 用户安装指南

添加到README.md文件：

```
## 安装方法

添加Tap:
brew tap yourusername/myapps

安装应用:
brew install --cask app

更新应用:
brew update
brew upgrade --cask app
```

## 版本更新流程

1. 发布新版本DMG到GitHub Releases
2. 更新cask文件中的`version`、`sha256`和`url`
3. 提交并推送更改到Tap仓库
4. 用户运行`brew update`和`brew upgrade --cask app`获取更新

## 注意事项

- **命名冲突**：如果与现有cask名称冲突，考虑使用`yourusername-app`格式
- **路径准确性**：确保DMG中的应用路径与cask文件中的`app`字段匹配
- **依赖关系**：如需指定macOS版本要求，添加：`depends_on macos: ">= :mojave"`
- **复杂安装**：对于需要用户交互的DMG，参考[Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)中的`installer`字段

## 参考资源

- [Homebrew文档：创建和维护Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Homebrew文档：Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
