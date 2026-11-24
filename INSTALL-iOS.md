# 把 Money 装到 iPhone 上

先说清楚 iOS 的规则：**iPhone 不允许安装未签名的 App**。任何一个 `.ipa` 都必须用 Apple 的证书签名才能装。签名需要 Apple ID（免费也行）+ 一台能签名的电脑；这台 Windows 上没有 Xcode / iOS SDK / 证书，所以我没法直接产出一个「双击就能装」的 iPhone 安装包——这不是漏做了一步，是 iOS 的硬限制。

能走通的只有下面三条路，按省事程度排：

---

## 路线 A：装网页版（1 分钟，今天就能用）

不需要签名，不需要 Apple ID。

1. 电脑上双击 `start-money.bat`，窗口会显示类似 `http://192.168.10.12:8766` 的地址。
2. iPhone 连同一个 Wi-Fi，Safari 打开这个地址。
3. 分享 → **添加到主屏幕**。

桌面会出现 Money 图标，点开全屏，数据存本机。缺点：没有「轻点背面」。

---

## 路线 B：GitHub 出一条未签名 IPA，再用 Sideloadly 签名装上（免费，约 15 分钟）

这是没有 Mac 时，装**真正的原生 App**（含轻点背面）的通用做法。已经给你写好了自动构建：`.github/workflows/build-unsigned-ipa.yml`。

### B1. 让 GitHub 帮你编译出 IPA

1. 注册 / 登录 GitHub（免费）。
2. 新建一个仓库（Private 也可以），名字随意，例如 `money`。
3. 把这个 `Money` 文件夹里的内容传上去：
   - 网页上点 **Add file → Upload files**，把 `ios/`、`.github/`、`README.md` 一起拖进去，Commit。
   - 或者用 GitHub Desktop 上传。
4. 打开仓库的 **Actions** 标签 → 左边选 **Build unsigned IPA** → 右边 **Run workflow** → Run。
5. 等 3–5 分钟，构建完成后点进这次运行，页面底部 **Artifacts** 下载 `Money-unsigned-ipa.zip`，解压得到 **Money-unsigned.ipa**。

> 如果 Actions 提示需要开启 workflow，点绿色按钮启用即可。构建用的是 GitHub 免费的 macOS 机器，不需要你的任何证书。

### B2. 在 Windows 上签名并安装

1. 装 **Sideloadly**（sideloadly.io）和 **iTunes**（微软商店版即可，提供 Apple 驱动）。
2. iPhone 用数据线连电脑，解锁，点「信任」。
3. 打开 Sideloadly：IPA 选刚下载的 `Money-unsigned.ipa`，Apple 账号填你的 Apple ID，点 **Start**。
4. 输入 Apple ID 密码（如有双重认证，按提示在手机上确认）。
5. iPhone 上：`设置 → 通用 → VPN与设备管理` → 信任你的 Apple ID。
6. 桌面出现 **Money**，可以正常用，也可以去 `设置 → 辅助功能 → 触控 → 轻点背面` 配快捷指令了。

### 注意

- 免费 Apple ID 签名的 App **7 天过期**。到期后重新用 Sideloadly 点一次 Start 即可续上；到期前 App 会打不开，**先导出 CSV** 保险。
- 免费签名最多同时装 2–3 个自签 App。
- 想永久不过期：加入 Apple Developer Program（$99/年），用同一套工程签名，或者走 TestFlight / App Store。
- 如果 Sideloadly 报错，多半是 iTunes 驱动或 Apple ID 双重认证没走完，按提示重试即可。

---

## 路线 C：有 Mac 的话最省事

```bash
brew install xcodegen
cd ios
xcodegen generate
open TallyTap.xcodeproj
```

选 iPhone 真机，Team 选自己的 Apple ID，Run。和 Sideloadly 一样是 7 天免费签名。

---

## 如果你用的是安卓

告诉我一声，我直接在这台电脑上打一个 **APK** 给你（内置离线页面，装上即用，不需要电脑开着）。

---

## 常见问题

**能直接把 `.ipa` 发我吗？**
可以，但必须是**你**的证书签过的 IPA，或者用你的 Apple ID 在 Sideloadly 里现场签。别人的签名 IPA 装不上你的手机。

**App Store 能搜到吗？**
没有上架。上架需要开发者账号（$99/年）和审核，角色插画也有版权问题，只能个人自用。

**数据会丢吗？**
7 天重签有概率丢 App 内数据。重要数据请在「我的 → 导出 CSV」备份。网页版的数据在 Safari 里，重装网页不影响。
