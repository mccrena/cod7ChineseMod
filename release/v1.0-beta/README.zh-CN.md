# 使命召唤7：黑色行动 中文配音 Mod v1.0-beta

发布日期：2026-11-06。版本性质：测试版。

本版用于测试中文语音替换和收集问题。它包含当前试制配音，尚未通过完整战役实机验收。开场仍有英文，部分语句存在语速过快或可能截尾的问题；详情见 KNOWN-ISSUES.zh-CN.md。

## 包含什么

- 789 个游戏音频成员，合并了之前验收过的 19 条古巴语气修订覆盖层。
- 安装、卸载脚本，文件校验清单和音频索引。
- 测试步骤与问题反馈模板。

本包不包含游戏程序、原版资源包、TTS 模型或重建地图。默认保留原版古巴地图，不安装尚未实机验证的字幕地图修复候选。

## 适用安装

当前只支持本项目核对过的 PC 安装：保留 Japanese 语言槽的现有中文汉化，localization.txt 首行为 japanese。脚本会核对程序、语言配置和古巴地图摘要；不匹配时停止，不自动更换语言或改存档。其他发行版尚未验证。

如果此前装过造成古巴着色器报错的字幕地图补丁，应先恢复该补丁备份中的 zone/Common/cuba.ff 和 zone/Japanese/ja_cuba.ff。安装脚本发现这两个文件不匹配原版时会停止。本项目当前游戏目录已恢复这两个原版文件。

## 安装

1. 关闭游戏，将 ZIP 完整解压到任意普通文件夹。
2. 双击 INSTALL.cmd，按提示输入包含 BlackOps.exe 的游戏根目录，例如 E:\game\Call of Duty 7 Black Ops。不要填 main 子目录。
3. 等待出现 Installed v1.0-beta。脚本会显示备份位置。
4. 手动运行游戏根目录 BlackOps.exe。安装脚本不会启动游戏。

也可在 PowerShell 中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -GameRoot 'E:\game\Call of Duty 7 Black Ops'
```

本次启动参数只对这次脚本进程生效，不更改系统执行策略。无需安装 Python。

安装器将同一份合并音频写入 main 下的三个 Mod 覆盖包：zz_zh_campaign.iwd、localized_English_iw99_zh_campaign.iwd、localized_Japanese_iw99_zh_campaign.iwd。包内只保存一份音频，安装时复制到对应入口。旧的 zz_zh_cuba_v2_prosody.iwd 内容已合并；若检测到本项目已知版本，会先备份再停用，卸载时恢复。遇到同名但内容未知的覆盖层，脚本会停止。

备份保存在游戏目录的 zh-dub-mod-backups/v1.0-beta 下。不要在卸载前删除备份。脚本不更改玩家存档、画面设置、语言设置或原版 IWD/FF。

## 卸载

关闭游戏，双击 UNINSTALL.cmd，输入同一游戏目录。也可以运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Uninstall.ps1 -GameRoot 'E:\game\Call of Duty 7 Black Ops'
```

卸载会恢复安装前的覆盖包，并移除本版新建的覆盖包，保留备份。如果安装后手动更改过这些文件，卸载器会停止，避免覆盖你的修改。

## 测试与反馈

按 TESTING.zh-CN.md 测试。出现问题时记录关卡、检查点、说话角色、原文或中文字幕，以及听到的内容；使用 FEEDBACK.md 填写。

本版的封包与安装检查不等于声音质量或实机加载已通过。发现英文残留、急读、截词、翻译失真或崩溃，都应反馈。
