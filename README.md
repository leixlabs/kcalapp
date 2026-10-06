# 食刻 / Calory

本地 AI 食物热量记录 App。拍下餐食，App 将图片与用户配置的多模态 LLM 服务交互，生成可编辑的食材、估算重量、热量和三大营养素；用户确认后，记录汇入当日饮食与长期趋势。


<img width="590" height="1278" alt="IMG_5804" src="https://github.com/user-attachments/assets/5e9fae9a-141f-4e71-9064-58f6917e83fd" />
<img width="590" height="1278" alt="IMG_5805" src="https://github.com/user-attachments/assets/52312f96-15cc-469b-bfea-f88f65d280c5" />
<img width="1083" height="3143" alt="IMG_5803" src="https://github.com/user-attachments/assets/f403dc89-4567-45d6-af71-5724b436e4aa" />
<img width="590" height="1278" alt="IMG_5806" src="https://github.com/user-attachments/assets/868b458a-401c-4cc9-9cde-f73f19f3793a" />


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
- 局域网只读 API 需手动启动并使用随机令牌认证，停止服务后令牌失效

## 局域网只读 API

入口：首页右上角「设置」→「局域网只读 API」。

在首页打开「数据导出」→「局域网只读 API」。启动服务后，复制的局域网地址已自动包含临时令牌；在浏览器中打开该地址即可查看 API 文档和可点击的接口示例，适合直接交给 LLM 使用。

所有 API 请求均可通过 URL 参数传递令牌：

```text
http://<局域网地址>:8765/api/v1/meals?token=<令牌>&from=2026-09-01T00%3A00%3A00Z&to=2026-10-01T00%3A00%3A00Z
```

也兼容 Bearer 请求头：

```http
Authorization: Bearer <令牌>
```

- `GET /api/v1/health`：服务状态
- `GET /api/v1/meals`：餐食、营养和食材明细；可选 `from`、`to` 查询参数按 ISO 8601 时间筛选。`from` 包含、`to` 不包含；省略任一参数则不限制该侧时间。
- `GET /api/v1/goals`：每日营养目标

服务只在 API 页面打开期间运行；离开页面或手动停止后会关闭。接口为只读，不提供图片文件、图片路径、LLM 配置或 API Key。饮食数据属于个人健康数据；HTTP 未加密，令牌会在局域网中明文传输，请只在可信网络使用并妥善保管访问令牌。

## AI 估算免责声明

所有食材、营养和建议内容源自 AI 的区域均标注"AI 估算"。产品呈现为"估算"，不做医疗、营养诊断或减肥效果承诺。
