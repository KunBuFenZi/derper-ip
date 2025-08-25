###############################
# Builder Stage
###############################
FROM golang:1.22-alpine AS builder

WORKDIR /src

# 可选：使用中国代理加速（需要时取消注释）
# RUN go env -w GOPROXY=https://goproxy.cn,direct

# 安装构建依赖
RUN apk add --no-cache git build-base

# 拉取并安装 derper 源码（会进入 module 缓存）
RUN go install tailscale.com/cmd/derper@latest

# 去除域名验证（删除 cert.go 中相关行：原脚本是 131~133，若上游改动需调整）
RUN find /go/pkg/mod/tailscale.com@*/cmd/derper/cert.go -type f -exec sed -i '131,133d' {} +

# 构建二进制
RUN derper_dir=$(find /go/pkg/mod/tailscale.com@*/cmd/derper -type d | head -n1) \
    && cd "$derper_dir" \
    && CGO_ENABLED=0 go build -o /out/derper

###############################
# Final Runtime Stage
###############################
FROM alpine:3.20

WORKDIR /app

# 时区 & 基础依赖
RUN apk add --no-cache ca-certificates tzdata openssl bash && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

# 针对 amd64 创建兼容软链 (ARM 会跳过)
RUN if [ "$(uname -m)" = "x86_64" ]; then mkdir -p /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2; fi

ENV LANG=C.UTF-8 \
    DERP_HOST=derp.example.com \
    DERP_PORT=36666 \
    CERTDIR=/ssl

COPY --from=builder /out/derper ./derper
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /ssl

EXPOSE 36666/tcp 36666/udp

ENTRYPOINT ["/entrypoint.sh"]###############################
# Builder Stage
###############################
FROM golang:1.22-alpine AS builder

WORKDIR /src

# 可选：使用中国代理加速（需要时取消注释）
# RUN go env -w GOPROXY=https://goproxy.cn,direct

# 安装构建依赖
RUN apk add --no-cache git build-base

# 拉取并安装 derper 源码（会进入 module 缓存）
RUN go install tailscale.com/cmd/derper@latest

# 去除域名验证（删除 cert.go 中相关行：原脚本是 131~133，若上游改动需调整）
RUN find /go/pkg/mod/tailscale.com@*/cmd/derper/cert.go -type f -exec sed -i '131,133d' {} +

# 构建二进制
RUN derper_dir=$(find /go/pkg/mod/tailscale.com@*/cmd/derper -type d | head -n1) \
    && cd "$derper_dir" \
    && CGO_ENABLED=0 go build -o /out/derper

###############################
# Final Runtime Stage
###############################
FROM alpine:3.20

WORKDIR /app

# 时区 & 基础依赖
RUN apk add --no-cache ca-certificates tzdata openssl bash && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

# 针对 amd64 创建兼容软链 (ARM 会跳过)
RUN if [ "$(uname -m)" = "x86_64" ]; then mkdir -p /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2; fi

ENV LANG=C.UTF-8 \
    DERP_HOST=derp.example.com \
    DERP_PORT=36666 \
    CERTDIR=/ssl

COPY --from=builder /out/derper ./derper
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /ssl

EXPOSE 36666/tcp 36666/udp

ENTRYPOINT ["/entrypoint.sh"]