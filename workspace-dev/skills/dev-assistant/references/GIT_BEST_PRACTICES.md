# Git 最佳实践指南

## 提交规范 (Conventional Commits)

### 提交类型
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构（不新增功能，不修复bug）
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

### 提交格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### 示例
```
feat(api): 添加用户注册接口

- 新增用户注册API
- 添加参数验证
- 完善错误处理

Closes #123
```

## 分支策略

### 主要分支
- `main`: 生产环境代码，稳定版本
- `develop`: 开发分支，集成所有功能

### 辅助分支
- `feature/*`: 功能开发分支
- `release/*`: 发布准备分支
- `hotfix/*`: 紧急修复分支

### 分支命名规范
```
feature/user-authentication
release/v1.2.0
hotfix/login-error
```

## 工作流程

### 功能开发
```bash
# 1. 从develop创建功能分支
git checkout develop
git pull origin develop
git checkout -b feature/your-feature

# 2. 开发并提交
git add .
git commit -m "feat: 功能描述"

# 3. 推送到远程
git push origin feature/your-feature

# 4. 创建Pull Request
# 在GitHub/GitLab创建PR，请求合并到develop
```

### 代码审查
1. **自检**：提交前运行测试，检查代码规范
2. **审查**：至少1人审查，重点关注：
   - 代码逻辑是否正确
   - 是否有潜在bug
   - 是否符合编码规范
   - 测试是否充分
3. **修改**：根据审查意见修改代码
4. **合并**：审查通过后合并到develop

### 发布流程
```bash
# 1. 创建发布分支
git checkout develop
git checkout -b release/v1.0.0

# 2. 版本号更新
# 更新package.json、CHANGELOG.md等

# 3. 测试验证
# 运行完整测试套件

# 4. 合并到main和develop
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0"

git checkout develop
git merge --no-ff release/v1.0.0

# 5. 删除发布分支
git branch -d release/v1.0.0
```

## 常用命令

### 基础操作
```bash
# 查看状态
git status
git log --oneline --graph

# 暂存与提交
git add .
git commit -m "message"
git commit --amend  # 修改最近一次提交

# 分支操作
git branch -a
git checkout -b new-branch
git merge branch-name
git branch -d branch-name
```

### 高级操作
```bash
# 撤销操作
git reset --soft HEAD~1  # 撤销提交，保留更改
git reset --hard HEAD~1  # 撤销提交，丢弃更改
git checkout -- file     # 撤销文件修改

# 暂存区操作
git stash               # 暂存当前更改
git stash pop           # 恢复暂存更改
git stash list          # 查看暂存列表

# 远程操作
git remote -v
git fetch origin
git pull origin branch
git push origin branch
```

### 冲突解决
```bash
# 1. 拉取最新代码
git pull origin develop

# 2. 解决冲突
# 编辑冲突文件，保留需要的代码

# 3. 标记冲突已解决
git add resolved-file

# 4. 继续合并
git commit -m "Merge branch 'develop'"
```

## 配置优化

### Git 全局配置
```bash
# 用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 别名配置
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"

# 其他配置
git config --global core.autocrlf input  # Mac/Linux
git config --global core.autocrlf true   # Windows
git config --global core.editor "vim"
```

### .gitignore 配置
```gitignore
# 依赖目录
node_modules/
vendor/
dist/
build/

# 环境变量
.env
.env.local
.env.production

# 日志文件
*.log
logs/

# 编辑器文件
.vscode/
.idea/
*.swp
*.swo

# 系统文件
.DS_Store
Thumbs.db
```

## 常见问题处理

### 提交了错误文件
```bash
# 1. 撤销最近一次提交
git reset --soft HEAD~1

# 2. 移除错误文件
git rm --cached wrong-file

# 3. 重新提交
git commit -m "fix: 移除错误文件"
```

### 分支混乱
```bash
# 查看分支图
git log --oneline --graph --all

# 清理已合并分支
git branch --merged | grep -v "\*" | xargs -n 1 git branch -d

# 强制清理远程分支
git fetch --prune
```

### 找回丢失的提交
```bash
# 查看所有操作记录
git reflog

# 恢复特定提交
git checkout <commit-hash>
git checkout -b recovered-branch
```

## 最佳实践总结

1. **小步提交**：每次提交只做一件事，便于回滚和审查
2. **清晰描述**：提交信息要清晰说明做了什么，为什么做
3. **定期同步**：每天至少拉取一次远程最新代码
4. **及时合并**：功能完成后及时合并，避免长期分支
5. **保持整洁**：定期清理无用分支，保持仓库整洁
6. **备份重要**：重要更改前先备份，避免数据丢失

---

**规范使用 Git，提升开发效率！** 🔧