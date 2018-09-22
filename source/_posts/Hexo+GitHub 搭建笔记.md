---
title: Hexo+GitHub 搭建笔记
date: 2018-09-20 13:14:58
tags: 
  - hexo
categories:
- hexo
---

 
### Node 安装

下载对应版本的[Node](https://nodejs.org/en/download/),直接下一步安装就行，然后检查

``` bash
$ node -v
v10.10.0
$ npm -v
6.4.1
```

### Git 安装

下载对应版本的[Git](https://git-scm.com/downloads),直接下一步安装就行，然后检查

``` bash
$ git --version
git version 2.15.1.windows.2
```

### Hexo 安装

``` bash
$ mkdir hexo
$ cd hexo
$ npm install hexo -g
$ hexo -v
hexo: 3.7.1
hexo-cli: 1.1.0
os: Windows_NT 10.0.17134 win32 x64
http_parser: 2.8.0
node: 10.10.0
v8: 6.8.275.30-node.24
uv: 1.23.0
zlib: 1.2.11
ares: 1.14.0
modules: 64
nghttp2: 1.33.0
napi: 3
openssl: 1.1.0i
icu: 62.1
unicode: 11.0
cldr: 33.1
tz: 2018e

 
$ hexo s //启动，打开浏览器http://localhost:4000就能看到了
INFO  Start processing
INFO  Hexo is running at http://localhost:4000 . Press Ctrl+C to stop.
```

### Hexo 插件

```
部署到Git,订阅,统计,站内搜索等
$ npm install hexo-deployer-git --save
$ npm install hexo-generator-feed --save
$ npm install hexo-wordcount --save
$ npm install hexo-generator-search --save
$ npm install hexo-asset-image --save
$ npm install hexo-generator-index --save
$ npm install hexo-generator-archive --save
$ npm install hexo-generator-category --save
$ npm install hexo-generator-tag --save
$ npm install hexo-server --save
$ npm install hexo-generator-sitemap

著作权归作者所有。
商业转载请联系作者获得授权，非商业转载请注明出处。
作者：站长之家编辑 
链接：https://www.chinaz.com/web/2015/1016/458004.shtml 
来源：站长之家 

```
<!-- more -->


### Hexo 配置

这里只讲几个常用的，[更多配置官方](https://hexo.io/zh-cn/docs/configuration.html) || [主题next安装](https://github.com/iissnan/hexo-theme-next)

hexo/_config.yml如下这些做修改

``` bash
language: zh-Hans //修改为中文
post_asset_folder: true //图片文件夹

生成为XXX.MD >$ hexo n "XXX" 并在其中插入图片![](XXX/test.png)

theme: next //主题默认为landscape
deploy:
  type: git
  repo: ********/air-project.github.io.git
  branch: master
```

hexo/themes/next/_config.yml如下这些做修改

```
rss: /atom.xml
footer:
   icon: heart
   powered: true
   theme: 
    version: false
menu:
  home: / || home 
  tags: /tags/ || tags
  categories: /categories/ || th
  archives: /archives/ || archive
menu_icons:
  enable: true
  categories: th
  tags: tags
  archives: archive
post_wordcount:
  item_text: true
  wordcount: true
  min2read: true
  totalcount: true
  separated_meta: true
 
busuanzi_count:
  # count values only if the other configs are false
  enable: true
  # custom uv span for the whole site
  site_uv: true
  site_uv_header: <i class="fa fa-user"></i>
  site_uv_footer:
  # custom pv span for the whole site
  site_pv: true
  site_pv_header: <i class="fa fa-eye"></i>
  site_pv_footer:
  # custom pv span for one page only
  page_pv: true
  page_pv_header: <i class="fa fa-eye"></i>
  page_pv_footer:
 
local_search:
  enable: true
 
pace: true
plugins: hexo-generate-feed

```


###  GitHub配置

```
$ git config --global user.name "xxxx"
$ git config --global user.email "xxxx@qq.com"
$ cd ~/.ssh
$ ls
id_rsa  id_rsa.pub  known_hosts
$ ssh-keygen -t rsa -C "xxxx@qq.com" //三次直接回车，，生成密钥，最后得到了两个文件：id_rsa和id_rsa.pub（默认存储路径是：C:\Users\Administrator\.ssh）
$ eval "$(ssh-agent -s)" //添加密钥到ssh-agent
$ ssh-add ~/.ssh/id_rsa //添加生成的SSH key到ssh-agent
登录Github，点击头像下的settings，添加ssh
新建一个new ssh key，将id_rsa.pub文件里的内容复制上去,并验证
$ ssh -T git@github.com
Hi air-project! You've successfully authenticated, but GitHub does not provide shell access.

```



###  Hexo 简单命令

```
重启
$ hexo s

删除
$ hexo clean

重新生成静态页面，并推送到GitHub
$ hexo d -g
```
 

