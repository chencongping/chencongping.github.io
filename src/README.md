**MkDocs 完整搭建指南**，涵盖安装、配置、部署全流程，结合最佳实践和常见问题解决：

---

### 📦 **1. 环境准备**
#### **系统要求**
- **Python 3.5+**（推荐 Python 3.8+）
- **pip 包管理工具**（Python 自带）
```bash
# 检查环境
python --version
pip --version
```
- **Windows/macOS/Linux** 均支持 [citation:6][citation:5]。

#### **安装 MkDocs**
```bash
# 全局安装（推荐）
pip install mkdocs

# 验证安装
mkdocs --version  # 应返回版本号（如 mkdocs 1.4+）
```
> 💡 **权限问题处理**：
> - Linux/macOS 若报错，尝试 `pip install --user mkdocs`
> - 或用虚拟环境隔离：
    >   ```bash
>   python -m venv mkdocs-env
>   source mkdocs-env/bin/activate
>   pip install mkdocs
>   ```

---

### 🛠️ **2. 创建项目与基础配置**
#### **初始化项目**
```bash
mkdocs new my-docs  # 创建项目目录
cd my-docs
```
生成结构：
```
my-docs/
├── docs/          # Markdown 文档目录
│   └── index.md   # 默认主页
└── mkdocs.yml     # 配置文件
```

#### **编辑配置文件 `mkdocs.yml`**
```yaml
site_name: "AI Agent 文档中心"  # 网站标题
nav:                          # 导航菜单
  - 首页: index.md
  - 开发指南:
      - 环境配置: development/env.md
      - API 规范: development/api.md
  - 部署手册: deployment.md

theme: 
  name: readthedocs          # 内置主题（可选 material）
  highlightjs: true          # 代码高亮

plugins:
  - search                    # 启用搜索功能
```
> ✅ **多级导航**：通过缩进实现层级 [citation:3][citation:8]。

---

### ✍️ **3. 编写文档**
#### **Markdown 规范**
- 所有文档放在 `docs/` 目录（支持子目录）
- 使用标准 Markdown 语法，支持扩展：
  ```markdown
  ## 代码示例
  ```python
  print("Hello MkDocs!")
  ```

  !!! tip "提示"
  使用 `admonition` 扩展添加提示块 [citation:8]。
  ```

#### **实时预览**
```bash
mkdocs serve  # 启动本地服务器
```
访问 `http://localhost:8000` 实时预览，修改内容自动刷新 [citation:1][citation:3]。

---

### 🎨 **4. 主题与插件扩展**
#### **安装 Material 主题（推荐）**
```bash
pip install mkdocs-material
```
配置 `mkdocs.yml`：
```yaml
theme:
  name: material
  features:
    - navigation.tabs     # 顶部标签导航
    - search.highlight    # 搜索关键词高亮
  palette:               # 配色方案
    primary: deep purple
    accent: yellow

markdown_extensions:
  - admonition           # 提示块
  - toc:                 # 目录锚点
      permalink: true
  - pymdownx.superfences # 高级代码块
```

#### **常用插件**
| 插件名称                | 作用                  | 安装命令                     |
|-------------------------|-----------------------|------------------------------|
| `mkdocs-minify-plugin`  | 压缩 HTML/CSS/JS     | `pip install mkdocs-minify-plugin` [citation:3] |
| `mkdocs-awesome-pages`  | 自动生成导航         | `pip install mkdocs-awesome-pages-plugin` [citation:4] |
| `mkdocs-pdf-export`     | 导出 PDF             | `pip install mkdocs-pdf-export-plugin` [citation:8] |

---

### 🚀 **5. 部署到线上**
#### **方案一：GitHub Pages（自动化）**
```bash
mkdocs gh-deploy --clean  # 一键部署到 gh-pages 分支
```
> **流程说明**：
> 1. 命令将 `site/` 目录推送到 GitHub 的 `gh-pages` 分支
> 2. 在仓库设置中启用 GitHub Pages，选择 `gh-pages` 分支 [citation:2][citation:7]
> 3. 访问地址：`https://<用户名>.github.io/<仓库名>/`

#### **方案二：自建服务器（Nginx）**
```bash
mkdocs build             # 生成静态文件到 site/
rsync -avz site/ user@server:/var/www/html/docs  # 上传到服务器
```
Nginx 配置示例：
```nginx
server {
  listen 80;
  server_name docs.your-domain.com;
  root /var/www/html/docs;
  index index.html;
}
```

#### **自动化部署（GitHub Actions）**
创建 `.github/workflows/deploy.yml`：
```yaml
name: Deploy to GitHub Pages
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install mkdocs && mkdocs build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site
```
> ✅ 每次 `git push` 后自动构建部署 [citation:7]。

---

### ⚠️ **6. 常见问题解决**
1. **中文搜索失效**
    - 安装分词插件：
      ```bash
      pip install jieba
      ```
    - 在 `mkdocs.yml` 中添加：
      ```yaml
      plugins:
        - search:
            lang: zh
      ```

2. **导航链接404**
    - 确保 `mkdocs.yml` 中 `nav` 配置的路径与文件实际路径一致
    - 避免文件名含空格（用连字符替代）[citation:9]

3. **代码块行号显示异常**  
   在配置中显式启用行号：
   ```yaml
   markdown_extensions:
     - codehilite:
         linenums: true
   ```

---

### 💎 **总结建议**
- **轻量级文档** → 用默认主题 + GitHub Pages 部署
- **企业级文档** → 用 Material 主题 + 自动化流水线
- **高级需求**（版本控制、多语言）→ 结合 [Docusaurus](https://docusaurus.io/) 或 [ReadTheDocs](https://readthedocs.org/)

部署成功后，你的文档将具备：
- 📱 响应式设计（适配手机/平板）
- 🔍 全文搜索
- 🛠️ Markdown + Git 无缝协作
- 🌐 全球 CDN 加速（GitHub Pages）

可进一步参考：[MkDocs 官方文档](https://www.mkdocs.org/)｜[Material 主题配置](https://squidfunk.github.io/mkdocs-material/)