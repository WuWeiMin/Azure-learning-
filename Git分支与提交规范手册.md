这是 Semantic Versioning + Conventional Commits + CI/CD 最有价值的地方。

实际上，CI/CD 并不是看 major.minor.patch 去决定升级，而是根据 Commit Message 自动计算应该升级 Major、Minor 还是 Patch，然后生成新的版本号。

开发提交代码
      │
      ▼
git commit
      │
      ▼
Commit Message
feat(user): add profile page
fix(api): null exception
feat!: remove old endpoint
      │
      ▼
CI/CD (GitHub Actions / Azure DevOps / GitLab CI)
      │
      ▼
解析 Commit Message
      │
      ├── feat → Minor
      ├── fix → Patch
      ├── feat! → Major
      └── BREAKING CHANGE → Major
      │
      ▼
计算新版本
      │
      ▼
生成 Tag
v1.5.0
      │
      ▼
Build
      │
      ▼
Deploy

举个完整例子

假设目前线上版本：

v2.3.5


    git commit -m "fix(login): fix timeout issue"

CI/CD 读取 Commit：

fix(login): ...

识别：fix

2.3.5
   │
Patch +1
   ▼
2.3.6

然后

Tag:
v2.3.6

Build

Deploy


第二天有人提交：

git commit -m "feat(order): support batch import"
CI/CD：

feat
升级

2.3.6
   │
Minor +1
   ▼
2.4.0

注意：

Minor 增加以后

Patch 自动归零。

第三天：

git commit -m "feat(api)!: remove v1 endpoint"


feat(api): remove v1 endpoint

BREAKING CHANGE:
Old API removed.


CI/CD：

发现BREAKING CHANGE


2.4.0
   │
Major +1
   ▼
3.0.0


Minor 和 Patch 全部归零。

CI/CD 怎么知道？

CI/CD 不会自己理解 Commit。

它一般使用专门工具。


工具

GitHub

Azure DevOps

GitLab

semantic-release

⭐⭐⭐⭐⭐

⭐⭐⭐⭐⭐

⭐⭐⭐⭐⭐

release-please

⭐⭐⭐⭐⭐

⭐⭐⭐

⭐⭐⭐

standard-version

⭐⭐⭐⭐

⭐⭐⭐⭐

⭐⭐⭐⭐

GitVersion

⭐⭐⭐

⭐⭐⭐⭐⭐(.NET 最常见)


有没有 Breaking Change？
      │
      ├─有 → Major
      │
      └─没有
             │
             有没有 feat？
                  │
                  ├─有 → Minor
                  │
                  └─没有
                         │
                         有没有 fix？
                              │
                              ├─有 → Patch
                              └─没有 → 不发布















