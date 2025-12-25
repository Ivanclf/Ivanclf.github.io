---
title: deepseek 调参
date: 2025-12-09 22:29:30
tags: [碎片知识]
---

在 Ollama 下，deepseek 常用参数有以下几项

|参数名|描述|推荐值范围|适用场景|
|-|-|-|-|
|`temperature`|控制输出的随机性与创造力，值越高随机性越高|0.3~0.7|代码任务控制在 0.1~0.3<br>写作任务控制在 0.6~0.8|
|`top-p`|核采样，控制候选词的范围，值越高词汇越多样|0.85~0.95|与 `temperature` 搭配，平衡生成质量|
|`num_ctx`|上下文窗口大小，单位为 token，ai能看到的会话历史量|2048~8192|长文档分析则需要调高|
|`repeat_penalty`|重复惩罚，值越高模型越倾向于不重复生成内容|1.1~1.3|1.0 时不惩罚<br>大于 1.5 时可能会把常用词也一起干掉|

还有一些其他参数

|参数名|描述|推荐值范围|适用场景|
|-|-|-|-|
|`top_k`|固定保留概率最高的 k 个词，再重新归一化采样|1~100|现在用 `top_p` 多一点|
|`num_predict`|本次生成最多输出的 token 数|200~2048|摘要为 200~300<br>写文章时为 1024~2048<br>写代码时为 512~1500|
|`stop`|数组，碰到任意一个字符串就立刻刹车|`["\n", "User:", "问题：", "```"]`|放置模型“自问自答”或者把提示模板也写出来|

要创建自定义模型，需要西安创建一个文本文件（如 ModelFile 或 ModelFile.deepseek），然后写入相关参数

```text
# 基于官方模型
FROM deepseek-r1:8b

# 设置系统提示词，定义模型角色
SYSTEM """你是一个有帮助且严谨的AI助手。回答应准确、简洁。"""

# 设置参数
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
PARAMETER repeat_penalty 1.2
```

然后构建并运行该自定义模型

{% note info %}
浓浓的 [Docker](https://ivanclf.github.io/2024/11/16/order-set/#Docker) 味。
{% endnote %}

```bash
ollama create my-deepseek-8b -f ./Modelfile
ollama run my-deepseek-8b
```
