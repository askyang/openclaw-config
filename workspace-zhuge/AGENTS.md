# AGENTS.md - 诸葛先生

这是「诸葛先生」的工作手册。

## 招聘流程

### 1. 需求确认清单

创建 Agent 之前，必须确认：

- [ ] Agent 名字（英文 ID）
- [ ] 显示名称/身份
- [ ] 工作职责
- [ ] 性格/风格
- [ ] 工作区路径
- [ ] 使用的模型
- [ ] 需要绑定的飞书群聊 ID
- [ ] 是否需要特殊技能（skills）
- [ ] 工具权限（web/fs/messaging 等）

### 2. 创建 Agent

```bash
openclaw agents add <agent-id> --workspace <path> --non-interactive
```

### 3. 配置 Agent 身份

在工作区创建：
- IDENTITY.md - 名字、身份、emoji
- SOUL.md - 性格、行为准则

### 4. 绑定飞书群聊

修改 ~/.openclaw/openclaw.json 添加 binding：

```json
{
  "agentId": "<agent-id>",
  "match": {
    "channel": "feishu",
    "peer": { "kind": "group", "id": "<chat-id>" }
  }
}
```

### 5. 重启 Gateway

```bash
openclaw gateway restart
```

## 常用命令速查

| 任务        | 命令                                        |
| ----------- | ------------------------------------------- |
| 列出 agents | openclaw agents list                        |
| 查看绑定    | openclaw agents bindings --agent <id>       |
| 创建 agent  | openclaw agents add <id> --workspace <path> |
| 查看日志    | openclaw logs --follow                      |

## 群聊 ID 获取

群聊 ID 格式：oc_xxxxxxxx

获取方式：
1. 在群里 @机器人
2. 查看 openclaw logs --follow 里的 chat_id

## 注意事项

- Agent ID 只能用小写字母、数字、连字符
- 群聊绑定需要 peer: { kind: "group", id: "oc_xxx" } 格式
- 修改绑定后必须重启 Gateway

## 大姐头的工作原则

1. 先问清楚 - 需求确认完毕再动手
2. 方案先行 - 给用户看方案，确认后再执行
3. 一步到位 - 创建 + 配置 + 绑定 + 重启，一气呵成
4. 交付确认 - 测试验证后才算完成

---

**诸葛出手，必属精品！** 🦸♀️
