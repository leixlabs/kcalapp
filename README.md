# 食刻 / Calory

本地 AI 食物热量记录 App。拍下餐食，App 将图片与用户配置的多模态 LLM 服务交互，生成可编辑的食材、估算重量、热量和三大营养素；用户确认后，记录汇入当日饮食与长期趋势。

## 核心特性

- 无用户账号，数据默认仅保存在设备本地
- 用户自行配置可识图的 LLM 服务（OpenAI Chat Completions 兼容）
- 拍照识别后 AI 输出永远可修改
- 支持 iOS、Android 和鸿蒙（鸿蒙需额外适配验证）

## 技术栈

- Flutter 3.47+ / Dart 3.13+
- Riverpod 状态管理
- GoRouter 声明式路由
- sqflite 本地数据库
- Dio HTTP 客户端
- flutter_secure_storage 安全凭据存储
- image_picker 相机/相册
- table_calendar 日历组件

## 项目结构

```
lib/
  app/                 # 启动、路由、主题、依赖注入
  core/                # 错误、日期、单位、格式化、通用 UI
  features/
    diary/             # 今日、餐次、日历、日汇总
      domain/          # 领域模型
      data/            # DAO 和 Repository
      application/     # Use Case 和 Provider
      presentation/    # 页面
    food_recognition/  # AI 识别结果确认
    goals/             # 热量和营养目标
    llm_settings/      # LLM 配置管理
    data_transfer/     # 导出、隐私与数据清除
  data/                # SQLite、图片处理、LLM 适配器
  platform/            # 平台网关接口（安全存储、相机、相册）
```

## 本地运行

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行应用
flutter run

# 分析代码
flutter analyze
```

## 隐私设计

- 不建立应用账户、无自有业务服务器
- API Key 仅写入系统安全存储（Keychain / Keystore）
- 饮食数据、图片保留在本地 SQLite 和应用沙盒
- 导出文件不含 API Key
- 图片上传前默认移除 EXIF 信息

## AI 估算免责声明

所有食材、营养和建议内容源自 AI 的区域均标注"AI 估算"。产品呈现为"估算"，不做医疗、营养诊断或减肥效果承诺。
