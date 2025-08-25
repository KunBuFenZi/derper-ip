# 编译
FROM golang:alpine AS builder

# 切换模块源为全球Go代理服务器加速下载
RUN go env -w GOPROXY=https://proxy.golang.org,direct

# 设置Go编译优化
RUN go env -w CGO_ENABLED=0

# 拉取代码
RUN go install tailscale.com/cmd/derper@latest

# 去除域名验证（删除特定的域名验证代码行）
RUN find /go/pkg/mod/tailscale.com@*/cmd/derper/cert.go -type f -exec sed -i '/if hi\.ServerName != m\.hostname && !m\.noHostname {/,/}/d' {} +

# 编译
RUN derper_dir=$(find /go/pkg/mod/tailscale.com@*/cmd/derper -type d) && \
	cd $derper_dir && \
    go build -o /etc/derp/derper

# 生成最终镜像
FROM alpine:latest

WORKDIR /apps

COPY --from=builder /etc/derp/derper .

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

ENV LANG C.UTF-8

# 创建软链接 解决二进制无法执行问题 Amd架构必须执行，Arm不需要执行
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

# 添加源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

# 安装openssl
RUN apk add openssl && mkdir /ssl

# 生成自签10年证书
RUN openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /ssl/derp.javaow.com.key -out /ssl/derp.javaow.com.crt -subj "/CN=derp.javaow.com" -addext "subjectAltName=DNS:derp.javaow.com"


CMD ./derper -hostname derp.javaow.com -a :36666 -certmode manual -certdir /ssl