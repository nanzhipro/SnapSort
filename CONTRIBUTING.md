# 贡献指南 | Contributing Guide

[English](#english) | [中文](#中文)

---

## 中文

### 🎉 欢迎贡献

感谢您对 SnapSort 项目的关注！我们欢迎各种形式的贡献，包括但不限于：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复
- 🌟 分享使用体验

### 🚀 开发环境设置

#### 系统要求

- macOS 15+
- Xcode 16+
- Swift 6.0+

#### 克隆项目

```bash
git clone https://github.com/your-username/SnapSort.git
cd SnapSort
```

#### 打开项目

```bash
open SnapSort.xcodeproj
```

### 📋 开发规范

#### 代码风格

- 遵循 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- 使用 `swift-format` 进行代码格式化
- 保持代码简洁、可读性强

#### 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
feat: 添加新的截图分类功能
fix: 修复 OCR 识别准确率问题
docs: 更新 README 文档
style: 代码格式化调整
refactor: 重构 AI 分类算法
test: 添加单元测试
chore: 更新依赖包版本
```

#### 分支策略

- `main`: 主分支，保持稳定
- `develop`: 开发分支
- `feature/xxx`: 新功能分支
- `fix/xxx`: 修复分支

### 🔄 贡献流程

1. **Fork 项目**

   ```bash
   # 在 GitHub 上 Fork 项目
   git clone https://github.com/your-username/SnapSort.git
   ```

2. **创建功能分支**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **开发和测试**
   - 编写代码
   - 添加测试用例
   - 确保所有测试通过

4. **提交更改**

   ```bash
   git add .
   git commit -m "feat: 添加您的功能描述"
   ```

5. **推送分支**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**
   - 在 GitHub 上创建 PR
   - 填写详细的描述
   - 等待代码审查

### 🐛 报告问题

在提交 Issue 前，请：

1. 搜索现有 Issues，避免重复
2. 使用清晰的标题描述问题
3. 提供详细的重现步骤
4. 包含系统信息和错误日志

### 💡 功能建议

我们欢迎新功能建议！请：

1. 详细描述功能需求
2. 说明使用场景
3. 考虑实现的可行性
4. 讨论对现有功能的影响

### 📞 联系我们

- GitHub Issues: [项目 Issues](https://github.com/your-username/SnapSort/issues)
- 邮箱: <your-email@example.com>

---

## English

### 🎉 Welcome Contributors

Thank you for your interest in the SnapSort project! We welcome all forms of contributions, including but not limited to:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🔧 Code fixes
- 🌟 Sharing user experiences

### 🚀 Development Setup

#### System Requirements

- macOS 15+
- Xcode 16+
- Swift 6.0+

#### Clone the Project

```bash
git clone https://github.com/your-username/SnapSort.git
cd SnapSort
```

#### Open Project

```bash
open SnapSort.xcodeproj
```

### 📋 Development Standards

#### Code Style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use `swift-format` for code formatting
- Keep code clean and readable

#### Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
feat: add new screenshot classification feature
fix: improve OCR recognition accuracy
docs: update README documentation
style: code formatting adjustments
refactor: refactor AI classification algorithm
test: add unit tests
chore: update dependency versions
```

#### Branch Strategy

- `main`: Main branch, keep stable
- `develop`: Development branch
- `feature/xxx`: Feature branches
- `fix/xxx`: Bug fix branches

### 🔄 Contribution Process

1. **Fork the Project**

   ```bash
   # Fork the project on GitHub
   git clone https://github.com/your-username/SnapSort.git
   ```

2. **Create Feature Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Develop and Test**
   - Write code
   - Add test cases
   - Ensure all tests pass

4. **Commit Changes**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push Branch**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Create PR on GitHub
   - Fill in detailed description
   - Wait for code review

### 🐛 Reporting Issues

Before submitting an Issue, please:

1. Search existing Issues to avoid duplicates
2. Use clear title to describe the problem
3. Provide detailed reproduction steps
4. Include system information and error logs

### 💡 Feature Suggestions

We welcome new feature suggestions! Please:

1. Describe the feature requirements in detail
2. Explain use cases
3. Consider implementation feasibility
4. Discuss impact on existing features

### 📞 Contact Us

- GitHub Issues: [Project Issues](https://github.com/your-username/SnapSort/issues)
- Email: <your-email@example.com>
