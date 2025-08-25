# derper-ip

基于 Tailscale `derper` 的自用镜像构建，自动化发布到 GitHub Container Registry (GHCR)。

## 镜像地址

```
ghcr.io/kunbufenzi/derper-ip:latest
```

推送后也会生成按提交 SHA 与 tag 的镜像，例如：

```
ghcr.io/kunbufenzi/derper-ip:sha-<git-sha>
ghcr.io/kunbufenzi/derper-ip:v1.0.0   # 当你打 v1.0.0 tag
```

## 运行示例

```bash
docker run -d --name derper \
  -e DERP_HOST=derp.example.com \
  -e DERP_PORT=36666 \
  -p 36666:36666 \
  ghcr.io/kunbufenzi/derper-ip:latest
```

首次启动若未挂载证书卷，会自动生成一个 10 年自签证书放置在容器内 `/ssl` 目录。

### 自定义证书

挂载你自己的证书目录，文件名需与域名一致：

```bash
docker run -d --name derper \
  -e DERP_HOST=derp.example.com \
  -v $(pwd)/mycerts:/ssl \
  -p 36666:36666 \
  ghcr.io/kunbufenzi/derper-ip:latest
```

需要的文件：

```
/ssl/derp.example.com.crt
/ssl/derp.example.com.key
```

### 环境变量

| 变量 | 说明 | 默认 |
|------|------|------|
| DERP_HOST | 对外域名 (用于证书与 derper -hostname) | derp.example.com |
| DERP_PORT | 监听端口 | 36666 |
| CERTDIR | 证书存放目录 | /ssl |

### 架构

通过 GitHub Actions 构建 multi-arch: `linux/amd64` 与 `linux/arm64`。

## 开发流程

1. 修改 `Dockerfile` 或脚本
2. `git add . && git commit -m "feat: update" && git push`
3. 等待 GitHub Actions 自动构建 & 推送镜像

在仓库 Actions 页面可查看 workflow 详情。

---
如需增加其它 tag、优化构建或添加私有 registry，请修改 `.github/workflows/docker.yml`。
