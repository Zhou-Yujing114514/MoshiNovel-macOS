# 摩柿小说下载站 · MoshiNovel

摩柿小说下载站（MoshiNovel）多平台 Flutter 客户端，支持 Windows / macOS / Linux / Android。

## 功能

- 账号登录 / 注册（Cookie 会话，安全存储）
- 搜索小说、提交提取任务（TXT / EPUB / PDF）
- 任务中心：查看进度、取消任务、下载文件
- 在线阅读器：章节切换、字号调节、日 / 夜间模式
- 个人中心：日夜间切换、站点信息
- 站长管理面板（站点设置、用户管理）

## 服务器

默认连接 `https://morax.kdns.fr`（仅 HTTPS / WSS，无明文）。

## 开发

```bash
flutter pub get
flutter run
```

各平台构建由 GitHub Actions 完成（见 `.github/workflows/build.yml`）。

## 版本

当前版本：**1.1.0+2**（摩柿小说统一 v1.x.x 系列）。

## 更新日志

### v1.1.0
- 服务端书源扩充，可检索 / 可下载的书籍来源进一步增多
- 杂源搜索优化，提升杂源结果的相关性与响应稳定性
- 修复在线阅读章节接口，解决章节内容偶发解析失败
- 客户端安全加固：会话 Cookie 改用系统安全存储，下载文件名经净化处理，封面图接入缓存

## License

MIT © 2026 Zhou-Yujing114514
