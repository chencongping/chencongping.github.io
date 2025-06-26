### **MkDocs 自动化部署操作文档**
（适用于 **源码在 `src/`，构建到 `docs/`，部署到 GitHub Pages**）

---

## **📜 使用说明**
### **1. 本地开发流程**
#### **1.1 编辑 Markdown 文档**
- 所有文档源码存放在 `src/` 目录下，按需修改 `.md` 文件。
- 本地实时预览：
  ```bash
  mkdocs serve
  ```
  访问 `http://127.0.0.1:8000` 查看效果。

#### **1.2 构建静态网站**
```bash
mkdocs build
```
- 生成的静态文件会自动输出到 `docs/` 目录（由 `mkdocs.yml` 中的 `site_dir` 配置决定）。

---

### **2. 手动部署到 GitHub Pages**
#### **2.1 提交代码到 Git**
```bash
git add src mkdocs.yml  # 提交源码和配置
git commit -m "更新文档内容"
git push origin main     # 推送源码到 main 分支
```

#### **2.2 提交构建后的文件**
```bash
git add docs            # 添加构建生成的静态文件
git commit -m "更新构建文档"
git push origin main    # 推送 docs/ 到 main 分支
```

#### **2.3 启用 GitHub Pages**
1. 进入 GitHub 仓库 → **Settings** → **Pages**
2. **Source** 选择 `main` 分支下的 `/docs` 文件夹
3. 点击 **Save**
4. 访问地址：`https://<你的用户名>.github.io/<仓库名>`

---

## **⚙️ 自动化部署（推荐）**
通过 **GitHub Actions** 实现提交代码后自动构建和部署，无需手动操作。

### **1. 配置 GitHub Actions**
在项目根目录创建 `.github/workflows/deploy.yml`：
```yaml
name: Deploy Docs
on:
  push:
    branches: [ main ]  # 监听 main 分支的推送
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4  # 拉取代码

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.x"

      - name: Install MkDocs
        run: pip install mkdocs

      - name: Build Docs
        run: mkdocs build  # 构建到 docs/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs  # 推送 docs/ 目录到 gh-pages 分支
          keep_files: false    # 清理旧文件
```

### **2. 启用 GitHub Pages**
1. 进入仓库 → **Settings** → **Pages**
2. **Source** 选择 `GitHub Actions`（无需手动指定分支）
3. 后续每次 `git push` 后，Actions 会自动构建并更新页面。

---

## **🔧 注意事项**
1. **`.nojekyll` 文件**  
   确保 `docs/` 目录下存在空文件 `.nojekyll`，避免 GitHub 误解析：
   ```bash
   touch docs/.nojekyll
   ```

2. **自定义域名**  
   如需绑定独立域名（如 `example.com`）：
    - 在 `docs/` 目录下创建 `CNAME` 文件，内容为域名：
      ```bash
      echo "example.com" > docs/CNAME
      ```
    - 在 DNS 服务商添加 CNAME 记录指向 `<用户名>.github.io`。

3. **本地与远程同步**
    - 如果使用自动化部署，无需手动提交 `docs/` 文件。
    - 如果手动部署，需确保 `docs/` 和 `src/` 同步更新。

---

## **📌 总结**
| **操作**               | 命令/配置                                                                 |
|------------------------|--------------------------------------------------------------------------|
| 本地编辑               | 修改 `src/` 下的 `.md` 文件                                              |
| 本地预览               | `mkdocs serve`                                                          |
| 手动构建               | `mkdocs build` → 生成 `docs/`                                           |
| 手动部署               | 提交 `docs/` 并启用 GitHub Pages                                        |
| 自动化部署（推荐）     | 配置 `.github/workflows/deploy.yml`，推送代码后自动构建和发布             |

通过此流程，你可以高效管理文档源码和部署，无需重复手动操作！