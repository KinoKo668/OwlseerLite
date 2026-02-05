# OwlSeer Lite - App Store 提交指南

> 最后更新: 2025年2月

---

## 📋 提交准备清单

### 技术准备

- [ ✅ ] Apple Developer 账号已激活 ($99/年)
- [ ] 在 Xcode 中配置 Signing & Capabilities（Team、证书、描述文件）
- [ ] Xcode Archive 打包成功
- [ ] 上传至 App Store Connect

### App Store Connect 配置

- [ ] 创建 App 记录
- [ ] 填写 App 名称和副标题
- [ ] 填写关键词
- [ ] 填写 App 描述（英文 + 中文）
- [ ] 上传截图（6.7" 和 6.5" iPhone）
- [ ] 填写隐私政策 URL
- [ ] 填写支持 URL
- [ ] 完成年龄分级问卷
- [ ] 设置定价（免费）
- [ ] 填写版权信息
- [ ] 填写联系信息

### 审核前检查

- [ ] App 在真机上运行正常
- [ ] 免费模式可以正常使用
- [ ] 自定义 Key 模式可以正常使用
- [ ] 隐私政策和服务条款可在 App 内查看
- [ ] 帮助与支持链接可正常跳转

---

## 📱 App 基本信息

| 项目 | 值 |
|------|-----|
| **Bundle ID** | `com.owlseer.OwlSeerLite` |
| **版本号** | 1.0 |
| **构建号** | 1 |
| **App 显示名称** | OwlSeer |
| **最低 iOS 版本** | iOS 17.0 |
| **支持设备** | iPhone, iPad |

---

## 🔗 重要链接

| 用途 | URL |
|------|-----|
| **隐私政策** | `https://kinoko668.github.io/OwlseerLite/privacy.html` |
| **服务条款** | `https://kinoko668.github.io/OwlseerLite/terms.html` |
| **支持页面** | `https://kinoko668.github.io/OwlseerLite/support.html` |
| **营销页面** | `https://kinoko668.github.io/OwlseerLite/` |
| **联系邮箱** | `tech@owlseer.com` |

---

## 📝 App Store 文案

### App 名称选项

| 选项 | 名称 |
|------|------|
| 方案 A | `OwlSeer Lite` |
| 方案 B | `OwlSeer - TikTok AI Assistant` |
| 方案 C | `OwlSeer: AI Content Creator` |

### 副标题（30字符以内）

**英文：**
```
AI Content Creation Assistant
```

**中文：**
```
AI 内容创作助手
```

### 关键词（100字符以内，逗号分隔）

**英文：**
```
TikTok,AI,content,creator,script,hook,viral,video,assistant,writing,social media,ChatGPT
```

**中文：**
```
TikTok,AI,内容创作,视频脚本,爆款文案,创作助手,人工智能,短视频,文案生成,社交媒体
```

---

### App 描述 - 英文版

```
OwlSeer Lite is your AI-powered TikTok content creation assistant. Generate engaging hooks, viral scripts, and creative ideas in seconds.

KEY FEATURES:

🎯 Smart Content Creation
• Generate attention-grabbing hooks for your videos
• Create structured video scripts with AI assistance
• Get creative ideas tailored to your niche

🔍 Trend Insights
• Stay updated with trending topics
• Web search capability for real-time information

🌐 Multi-Language Support
• English and Chinese interface
• Create content in multiple languages

🔒 Privacy First
• All chat history stored locally on your device
• Secure API key storage in iOS Keychain
• No data collection on our servers

💡 Flexible AI Options
• Free daily messages to get started
• Bring your own API key for unlimited usage
• Support for OpenAI, Anthropic, Google Gemini, DeepSeek, and Kimi

Perfect for TikTok creators, content marketers, and social media managers who want to level up their content game.

Note: AI-generated content is for reference only. Please review and adapt suggestions before publishing.
```

---

### App 描述 - 中文版

```
OwlSeer Lite 是你的 AI 驱动 TikTok 内容创作助手。几秒钟内生成吸睛的开场白、爆款脚本和创意点子。

核心功能：

🎯 智能内容创作
• 为你的视频生成抓人眼球的 Hook 开场
• AI 辅助创建结构化的视频脚本
• 获取针对你领域定制的创意灵感

🔍 趋势洞察
• 实时了解热门话题趋势
• 联网搜索获取最新信息

🌐 多语言支持
• 中英文双语界面
• 支持多语言内容创作

🔒 隐私优先
• 聊天记录仅存储在本地设备
• API 密钥安全存储于 iOS 钥匙串
• 不在服务器收集任何用户数据

💡 灵活的 AI 选项
• 每日免费消息额度，轻松上手
• 支持使用自己的 API 密钥，无限制使用
• 支持 OpenAI、Anthropic、Google Gemini、DeepSeek、Kimi

专为 TikTok 创作者、内容营销人员和社交媒体运营打造，助你提升内容创作效率。

注意：AI 生成的内容仅供参考，请在发布前自行审核和调整。
```

---

## 📸 截图要求

### 必需尺寸

| 设备 | 尺寸 (像素) | 模拟器型号 |
|------|------------|-----------|
| iPhone 6.7" | 1290 × 2796 | iPhone 15 Pro Max |
| iPhone 6.5" | 1284 × 2778 | iPhone 14 Plus |

### 建议截图内容（5-10张）

1. **欢迎界面** - 展示 AI 头像和欢迎语
2. **对话界面** - 展示与 AI 的对话
3. **Hook 生成** - 展示生成的爆款开场白
4. **脚本创作** - 展示生成的视频脚本
5. **设置页面** - 展示功能配置选项
6. **多语言** - 展示中英文切换
7. **隐私设置** - 展示隐私保护相关功能

### 截图技巧

1. 在 Xcode 中运行 App，选择对应的模拟器
2. 使用 `Cmd + S` 截图，保存到桌面
3. 建议关闭模拟器状态栏时间显示或统一时间为 9:41
4. 可以使用 [App Screenshot Generator](https://www.appscreens.com/) 添加设备边框和文案

---

## 🔞 年龄分级问卷参考

在 App Store Connect 的年龄分级问卷中，建议选择：

| 问题 | 建议回答 |
|------|---------|
| 卡通或幻想暴力 | 无 |
| 现实暴力 | 无 |
| 色情或裸露内容 | 无 |
| 成人主题 | 无 |
| 亵渎或粗俗幽默 | 无 |
| 药物使用或引用 | 无 |
| 酒精、烟草或毒品使用 | 无 |
| 模拟赌博 | 无 |
| 恐怖/惊吓主题 | 无 |
| 医疗/治疗信息 | 无 |
| 用户生成内容 | **是**（AI 生成内容） |
| 无限制网络访问 | **是**（调用 AI API） |

**预计分级结果：4+ 或 12+**

> 注意：由于 App 包含 AI 生成内容和网络访问，Apple 可能会将其分级为 12+。

---

## ⚠️ 审核注意事项

### 可能被拒绝的原因及应对

| 风险点 | 应对措施 |
|--------|---------|
| AI 生成内容可能不当 | ✅ 已添加免责声明和举报功能 |
| 需要 API Key 才能使用 | ✅ 已提供免费模式，无需配置即可体验 |
| 隐私政策缺失 | ✅ 已提供在线和 App 内隐私政策 |
| 无法测试功能 | 审核备注中说明免费模式可直接使用 |

### 审核备注建议（App Review Notes）

```
Demo Instructions:

1. Launch the app - it works out of the box with Free Trial mode
2. No account or API key required for basic testing
3. Send any message to test AI response (10 free messages per day)
4. Settings > AI Engine shows Free Trial / Custom Key options

Free mode uses built-in API quota. Custom Key mode allows users to use their own OpenAI/Anthropic/Gemini API keys.

Contact: tech@owlseer.com
```

---

## 📄 版权信息

```
© 2025 OwlSeer. All rights reserved.
```

---

## 🚀 提交流程

### 1. Xcode 打包

```bash
# 在 Xcode 中
1. 选择 Any iOS Device (arm64)
2. Product > Archive
3. 等待 Archive 完成
4. 在 Organizer 中选择 Distribute App
5. 选择 App Store Connect > Upload
```

### 2. App Store Connect 配置

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)
2. 我的 App > 创建新 App
3. 填写基本信息（名称、Bundle ID、SKU）
4. 在"App 信息"中填写所有必填项
5. 上传截图和预览
6. 在"构建版本"中选择上传的版本
7. 提交审核

### 3. 等待审核

- 首次提交通常需要 24-48 小时
- 保持邮箱畅通，及时回复审核问题
- 如被拒绝，根据反馈修改后重新提交

---

## 📞 联系信息

| 项目 | 值 |
|------|-----|
| 开发者邮箱 | tech@owlseer.com |
| 支持网站 | https://kinoko668.github.io/OwlseerLite/support.html |
| GitHub 仓库 | https://github.com/KinoKo668/OwlseerLite |

---

祝提交顺利！🎉
