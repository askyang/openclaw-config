# dalin-writing Skill 使用说明

## 📁 Skill 结构

```
dalin-writing/
├── SKILL.md                              # 核心配置和9步创作流程
├── README.md                             # 本文件
├── references/                           # 参考资料（可按需加载）
│   ├── 降AI味指南.md                     # AI味检测和改写方法
│   ├── 写作技巧-金字塔原理.md            # 金字塔原理和SCQA框架
│   └── 用户人设-快速参考.md              # dalin风格快速查询
├── scripts/                              # 自动化脚本
│   ├── 创建项目结构.sh                   # 初始化新项目目录
│   └── 保存文章.sh                       # 保存写好的文章
└── templates/                            # 模板文件
    ├── brief-template.md                 # 项目brief模板
    └── article-template.md               # 文章结构模板
```

## 🎯 核心功能

### 1. 完整的9步创作流程
- Step 1: 理解需求 & 保存 Brief
- Step 2: 信息搜索与知识管理
- Step 3: 选题讨论（必做！）
- Step 4: 创建协作文档
- Step 5: 学习 DaLin 的风格
- Step 6: 创作初稿
- Step 7: 三遍审校（降AI味）
- Step 8: 生成配图建议
- Step 9: 保存成品 & 存档

### 2. 自动化脚本

#### 创建项目结构
```bash
~/.claude/skills/dalin-writing/scripts/创建项目结构.sh "项目名称"
```

**功能**：
- 自动创建项目目录
- 创建子目录（协作文档、知识库、配图）
- 生成 brief 文件
- 创建项目说明和进度跟踪

**示例**：
```bash
~/.claude/skills/dalin-writing/scripts/创建项目结构.sh "Claude Code测评"
```

#### 保存文章
```bash
~/.claude/skills/dalin-writing/scripts/保存文章.sh "文章标题"
```

**功能**：
- 保存文章到标准位置
- 自动统计字数
- 检测文件重复

**使用方式**：
1. 执行脚本
2. 粘贴文章内容
3. 按 Ctrl+D 结束输入

### 3. 参考资料速查

#### 降AI味指南
- AI套话清单
- 改写对照表
- 实战案例
- 快速自检清单

#### 金字塔原理
- 结论先行方法
- SCQA故事框架
- 爆款标题公式
- 节奏控制技巧

#### 用户人设快速参考
- DaLin 的风格特征
- 典型句式
- 质量标准
- 快速自检三问

## 🚀 快速开始

### 创建新项目

1. **初始化项目结构**
   ```bash
   ~/.claude/skills/dalin-writing/scripts/创建项目结构.sh "你的项目名"
   ```

2. **填写 Brief**
   - 打开生成的 brief 文件
   - 按照模板填写项目信息

3. **选题讨论**
   - 对 Claude 说："开始选题讨论"
   - Claude 会提供3-4个选题方向
   - 选择一个后继续

4. **创作流程**
   - Claude 会自动引导完成9步流程
   - 每步都会生成对应文件
   - 保存到指定位置

### 使用模板

#### Brief 模板
位置：`~/.claude/skills/dalin-writing/templates/brief-template.md`

手动复制到新项目使用。

#### 文章模板
位置：`~/.claude/skills/dalin-writing/templates/article-template.md`

提供标准的文章结构框架。

## 📚 参考资料位置

### 本地资源
- 风格参考：`~/Desktop/创作相关存档/vibe coding/写作agent/风格参考/`
- 写作技巧：`~/Desktop/创作相关存档/vibe coding/写作agent/写作技巧/`
- 规范指南：`~/Desktop/创作相关存档/vibe coding/写作agent/规范指南/`
- 用户人设：`~/Desktop/创作相关存档/vibe coding/写作agent/用户人设.md`

### Skill 内置资料
- 降AI味指南：自动加载到 context
- 金字塔原理：自动加载到 context
- 用户人设：自动加载到 context

## ⚙️ 触发场景

当你说以下内容时，dalin-writing skill 会自动激活：

- "写一篇文章..."、"帮我创作..."、"我想写..."
- "改一下这篇文章"、"修改..."
- "审校一下"、"降AI味"、"降重"
- "选题讨论"、"给我几个选题"
- "生成 brief"

## 🎯 核心原则

1. **永远不要直接写文章，先讨论选题** ⭐⭐⭐
2. **三遍审校是核心，尤其是降 AI 味** ⭐⭐⭐
3. **所有文件都要保存到指定路径**
4. **真实数据 > 虚构案例**
5. **保持 DaLin 的风格：洞察 + 口语化 + 干货 + 态度**

## 🔧 故障排查

### 脚本无法执行
```bash
chmod +x ~/.claude/skills/dalin-writing/scripts/*.sh
```

### 路径不存在
检查这些路径是否正确：
- `~/Desktop/创作相关存档/vibe coding/写作agent/我的项目/`

### Skill 未激活
确保 SKILL.md 中的 description 包含触发关键词。

## 📝 版本信息

- **创建日期**：2025.01.14
- **版本**：1.0
- **作者**：dalin
- **用途**：自媒体写作专用助手

---

有问题？直接问 Claude："dalin-writing 怎么用？"
