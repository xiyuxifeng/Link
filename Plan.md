# Link - iOS/iPadOS 局域网群组发现与实时通讯 App 开发计划

## 需求概述

基于 go-libp2p + gomobile 构建 iOS/iPadOS 实时通讯 App，实现局域网内设备的群组发现、加入与实时通信。

### 核心能力
- 创建群组、发现群组、加入/离开群组
- 群组内实时发送/接收数据（文本/二进制）
- 显示群组成员（在线成员列表）
- V1 仅支持局域网；V2 增加跨网发现与通信

### 当前项目状态
- SwiftUI 工程已初始化（LinkApp.swift、ContentView.swift 为占位符）
- Go Bridge 模块尚未创建
- 无任何业务功能实现

---

## 总体架构

```
┌─────────────────────────────────────────┐
│           App 层 (Swift/SwiftUI)         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────────┐  │
│  │群组页│ │发现页│ │聊天页│ │成员/设置│  │
│  └──┬───┘ └──┬───┘ └──┬───┘ └───┬────┘  │
│     └────────┴────────┴─────────┘        │
│              状态管理层                    │
│     (NodeManager / GroupManager /         │
│      MessageManager / MemberManager)     │
└──────────────────┬──────────────────────┘
                   │ Swift ↔ Go 调用
┌──────────────────┴──────────────────────┐
│        P2PBridge (Go: go-libp2p)         │
│  ┌──────────┐ ┌───────┐ ┌────────────┐  │
│  │Host/Node │ │ mDNS  │ │  PubSub    │  │
│  │管理      │ │发现   │ │ GossipSub  │  │
│  └──────────┘ └───────┘ └────────────┘  │
│  ┌──────────┐ ┌───────────────────────┐  │
│  │Stream    │ │ 事件回调 (Listener)   │  │
│  │协议      │ │ Go → Swift            │  │
│  └──────────┘ └───────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## 风险评估

| 风险 | 严重度 | 对策 |
|------|--------|------|
| iOS 本地网络权限 / Bonjour 限制导致 mDNS 发现失败 | HIGH | 主动触发权限弹窗 + 引导页 + 诊断页手动添加 Peer |
| gomobile 与 Xcode 版本兼容性问题 | HIGH | 锁定 Go/Xcode 版本，CI 自动构建 |
| PubSub 资源消耗过高（低端设备发热/耗电） | MEDIUM | 连接上限 40、消息大小限制、频率限流、后台暂停 |
| iOS 后台模式限制导致连接中断 | MEDIUM | V1 不支持后台常驻，前台恢复后重连 |
| mDNS 在复杂网络（企业/酒店）下不稳定 | MEDIUM | 明确标注"仅局域网"+ 手动添加 Peer 应急入口 |
| PeerID 丢失/重置 | LOW | Keychain 存储私钥，显式"重置身份"入口 |

---

## V1 开发计划 — TODO List

### Milestone 0：工程与构建打通

**目标**：iOS 工程能集成 P2PBridge.xcframework 并成功运行。

- [ ] M0-1: 创建 Go module `p2pbridge`，定义空壳 API 接口与 Listener 协议
- [ ] M0-2: 实现 gomobile init + bind，产出 P2PBridge.framework
- [ ] M0-3: 打包 xcframework（真机 arm64 + 模拟器 arm64）
- [ ] M0-4: Xcode 工程集成 xcframework，完成最小调用验证（Start/Stop）
- [ ] M0-5: iOS Demo 页面：显示 PeerID、启动/停止按钮与状态反馈
- [ ] M0-6: (可选) CI 脚本：固定 Go/Xcode 版本，自动构建 xcframework

**交付物**：
- `P2PBridge.xcframework`
- iOS Demo：显示 PeerID、启动/停止成功

---

### Milestone 1：局域网发现与连接

**目标**：局域网内能自动发现 peer 并建立连接。

#### Go 侧
- [ ] M1-1: 实现 libp2p Host 创建（TCP + Noise/TLS 安全通道 + Yamux muxer）
- [ ] M1-2: 集成 mDNS discovery，发现 peers 并触发连接尝试
- [ ] M1-3: 实现连接管理（上限 40、退避重试、连接/断开事件回调）
- [ ] M1-4: 实现诊断信息导出（已连接 peers 数、监听地址、PeerID）
- [ ] M1-5: 实现 `OnPeerConnected` / `OnPeerDisconnected` 回调

#### iOS 侧
- [ ] M1-6: 配置 Info.plist 本地网络权限（NSLocalNetworkUsageDescription、NSBonjourServices）
- [ ] M1-7: 实现权限检测与引导提示 UI（未授权时引导用户前往系统设置）
- [ ] M1-8: 创建 `NodeManager`（Swift）：封装 Go Node 生命周期（Start/Stop/状态监听）
- [ ] M1-9: 实现诊断页 UI（PeerID、连接数、监听地址、已发现 peers 列表）

**验收标准**：两台真机同 Wi-Fi，能互相发现并显示"已连接"

---

### Milestone 2：群组发现 / 创建 / 加入

**目标**："群组"闭环跑通（创建 → 发现 → 加入 → 离开）。

#### Go 侧
- [ ] M2-1: 定义群组数据结构 `Group`（groupID, name, createdBy, requiresPasscode, memberCountEstimate, lastSeen）
- [ ] M2-2: 实现群组本地管理（创建/删除/列表维护）
- [ ] M2-3: 实现 Stream 协议 `/<appNS>/<env>/groups/1.0.0` handler（响应群组列表查询）
- [ ] M2-4: 实现 Stream 协议 client（向已发现 peer 拉取群组列表）
- [ ] M2-5: 实现发现页数据聚合与去重（从多个 peer 拉取 groups 并合并）
- [ ] M2-6: 实现 Join/Leave 群组逻辑（订阅/退订 PubSub topics）
- [ ] M2-7: 实现 `OnGroupDiscovered` / `OnGroupJoined` / `OnGroupLeft` 回调

#### iOS 侧
- [ ] M2-8: 创建 `GroupManager`（Swift）：封装群组操作与状态
- [ ] M2-9: 实现群组列表页 UI（已加入的群组列表）
- [ ] M2-10: 实现发现页 UI（显示可加入群组列表，刷新/搜索）
- [ ] M2-11: 实现创建群组 UI（名称、可选口令、公开/私有）
- [ ] M2-12: 实现加入群组 UI（含口令输入，V1 可不强制验证）
- [ ] M2-13: 实现 Tab 导航架构（群组列表 / 发现 / 设置）

**验收标准**：A 创建群组，B 在发现页 10 秒内看到并加入；离开后不再接收消息

---

### Milestone 3：群聊消息与成员在线列表

**目标**：群组内实时消息 + 成员列表可用。

#### Go 侧
- [ ] M3-1: 集成 GossipSub，实现 msg topic 的 publish/subscribe
- [ ] M3-2: 集成 presence topic 的 publish/subscribe（心跳间隔 5s）
- [ ] M3-3: 实现消息 envelope 封装（msgID, groupID, fromPeerID, fromName, ts, type, mime）
- [ ] M3-4: 实现 msgID 去重机制（防止重复消息）
- [ ] M3-5: 实现 presence 心跳与 TTL（15s）成员表维护
- [ ] M3-6: 实现限流（10 条/秒/群）与最大消息大小限制（64KB~256KB）
- [ ] M3-7: 实现 `OnGroupMessage` / `OnPresenceUpdate` 回调

#### iOS 侧
- [ ] M3-8: 创建 `MessageManager`（Swift）：消息收发与存储（内存）
- [ ] M3-9: 创建 `MemberManager`（Swift）：在线成员维护
- [ ] M3-10: 实现聊天页 UI（消息列表 + 输入框 + 发送按钮）
- [ ] M3-11: 实现成员页 UI（在线成员展示：昵称、PeerID、最后心跳时间）
- [ ] M3-12: 确保 Go 回调 → 主线程 UI 更新的线程安全

**验收标准**：两台设备加入同群，互发消息；成员列表在 10 秒内稳定一致

---

### Milestone 4：稳定性、体验与发布准备

**目标**：提升稳定性与可维护性，具备 TestFlight 发布质量。

- [ ] M4-1: 实现网络异常处理（Wi-Fi 断开/切换时的提示与重连策略）
- [ ] M4-2: 实现前后台切换逻辑（切后台停止 Host，回前台重连）
- [ ] M4-3: 实现日志系统（Go 侧 + Swift 侧统一日志）与日志导出功能
- [ ] M4-4: 实现参数可配置（presence interval/TTL/连接上限/消息大小限制）
- [ ] M4-5: UI 打磨 — 空状态页面（无群组/无成员/无消息）
- [ ] M4-6: UI 打磨 — 错误提示（连接失败/发送失败/权限缺失）
- [ ] M4-7: UI 打磨 — "仅支持局域网"说明与提示
- [ ] M4-8: 实现 PeerID/私钥 Keychain 持久化（kSecAttrAccessibleAfterFirstUnlock）
- [ ] M4-9: 实现昵称设置与持久化（设置页）
- [ ] M4-10: (可选) 基础自动化测试：协议序列化、去重逻辑、TTL 过期逻辑
- [ ] M4-11: (可选) 手动添加 Peer 应急入口（IP/端口）

**验收标准**：连续运行 30 分钟局域网群聊稳定；异常场景有明确提示不崩溃

---

## V1 最终验收标准

| 编号 | 验收项 | 预期结果 |
|------|--------|----------|
| 1 | 节点发现 | 通过 mDNS 互相发现对方 PeerID |
| 2 | 群组创建与发现 | A 创建群组，B 在发现页 10 秒内可见 |
| 3 | 群组加入 | B 成功加入群组，双方均收到加入通知 |
| 4 | 消息延迟 | 群组内互发文本消息，端到端延迟 < 300ms |
| 5 | 成员列表一致性 | 成员在线状态在 10 秒内收敛并保持一致 |
| 6 | 退群隔离 | 离开群组后，不再接收到该群的任何消息 |
| 7 | 身份持久化 | App 完全重启后，PeerID 保持不变 |
| 8 | 权限处理 | 未授权"本地网络"权限时，有明确弹窗提示与引导 |

---

## V2 计划概览（跨网，后续迭代）

### V2-1: Relay + Bootstrap
- 部署公网 Relay 节点（Circuit Relay v2）用于 NAT 兜底
- 部署 Bootstrap 节点用于跨网 peer 发现入口
- 客户端集成 Relay Client，实现 直连 → NAT 穿透 → Relay 中继 的自动回退

### V2-2: 跨网发现
- 优先实现 HTTPS 目录服务（群组注册/心跳 + 群组列表拉取）
- 后续视规模评估引入 libp2p DHT

### V2-3: 安全增强
- 入群鉴权：Challenge/Response 机制
- 群组级对称加密（AES-GCM / ChaCha20-Poly1305）
- 连接级与消息级限流、Peer 黑名单/禁言

---

## 文件结构规划（V1）

```
Link/
├── Link/
│   ├── LinkApp.swift                  # App 入口
│   ├── Models/
│   │   ├── Group.swift                # 群组模型
│   │   ├── Message.swift              # 消息模型
│   │   └── Member.swift               # 成员模型
│   ├── Managers/
│   │   ├── NodeManager.swift          # Go Node 生命周期管理
│   │   ├── GroupManager.swift         # 群组操作与状态
│   │   ├── MessageManager.swift       # 消息收发
│   │   └── MemberManager.swift        # 在线成员维护
│   ├── Bridge/
│   │   └── P2PBridgeListener.swift    # Go Listener 协议的 Swift 实现
│   ├── Views/
│   │   ├── MainTabView.swift          # Tab 导航
│   │   ├── Groups/
│   │   │   ├── GroupListView.swift    # 已加入群组列表
│   │   │   ├── CreateGroupView.swift  # 创建群组
│   │   │   └── GroupRowView.swift     # 群组行组件
│   │   ├── Discovery/
│   │   │   ├── DiscoveryView.swift    # 发现页
│   │   │   └── DiscoveryRowView.swift # 可加入群组行
│   │   ├── Chat/
│   │   │   ├── ChatView.swift         # 聊天页
│   │   │   ├── MessageBubble.swift    # 消息气泡
│   │   │   └── ChatInputView.swift    # 输入框
│   │   ├── Members/
│   │   │   └── MemberListView.swift   # 成员列表
│   │   └── Settings/
│   │       ├── SettingsView.swift     # 设置页
│   │       └── DiagnosticsView.swift  # 诊断页
│   └── Utils/
│       ├── KeychainHelper.swift       # Keychain 封装
│       └── PermissionHelper.swift     # 权限检测与引导
│
├── p2pbridge/                         # Go module
│   ├── go.mod
│   ├── node.go                        # Host 创建/启停
│   ├── discovery.go                   # mDNS 发现
│   ├── group.go                       # 群组管理
│   ├── pubsub.go                      # GossipSub 消息/Presence
│   ├── stream.go                      # Stream 协议
│   ├── listener.go                    # 回调接口定义
│   ├── types.go                       # 数据结构定义
│   └── build.sh                       # gomobile bind 脚本
│
└── P2PBridge.xcframework/             # 构建产物
```

---

## 协议命名规范

| 类型 | 格式 | 示例 |
|------|------|------|
| PubSub 群组消息 | `/<appNS>/<env>/group/<groupID>/msg` | `/link/prod/group/abc123/msg` |
| PubSub 群组 Presence | `/<appNS>/<env>/group/<groupID>/presence` | `/link/prod/group/abc123/presence` |
| Stream 群组列表查询 | `/<appNS>/<env>/groups/1.0.0` | `/link/prod/groups/1.0.0` |
| Stream 群组元数据 | `/<appNS>/<env>/groupmeta/1.0.0` | `/link/prod/groupmeta/1.0.0` |

**Presence 参数**：心跳间隔 5s（可配置），离线 TTL 15s（可配置）

---

## 关键配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 最大连接数 | 40 | 控制资源消耗 |
| 心跳间隔 | 5s | Presence 心跳频率 |
| 离线 TTL | 15s | 超时判定离线 |
| 最大消息大小 | 256KB | 单条消息上限 |
| 消息频率限制 | 10 条/秒/群 | 防刷限流 |
| Topic 数/群 | 2 | msg + presence |
