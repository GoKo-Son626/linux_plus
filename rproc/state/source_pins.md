# Source pins

核验时间：2026-08-28（Asia/Shanghai）。以下值来自官方远端 `git ls-remote`，不是 AI 文档自报。

| 对象 | 固定值 | 用途 |
|---|---|---|
| Linux release | `v7.2` -> `8d3ae59288f1e7d58d76558a6ee96d533bc5019f` | Week 1 可复现学习/构建基线 |
| Linux stable | `v7.2.1` -> `458fbaaefba2fc5450c325a6834453dc4f4e52ae` | 稳定分支参考，不替换学习基线 |
| Linux master snapshot | `1b78070aaef63512688aebfbc82365ef9d6660f1` | 当前 API 与 RPMI 主线实现审计 |
| RPMI | tag `v1.0` -> `27db4b4a405af971f84999adad4806d291f1338e` | Ratified 规范基线 |

核验命令：

```bash
git ls-remote https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git \
  refs/heads/master refs/tags/v7.2 'refs/tags/v7.2^{}'

git ls-remote https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
  refs/tags/v7.2.1 'refs/tags/v7.2.1^{}'

git ls-remote https://github.com/riscv-non-isa/riscv-rpmi.git \
  refs/tags/v1.0 'refs/tags/v1.0^{}'
```

master 会漂移；教程中的“当前 master”必须始终写固定 commit。
