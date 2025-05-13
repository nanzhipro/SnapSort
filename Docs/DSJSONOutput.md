[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/json_mode#__docusaurus_skipToContent_fallback)

本页总览

# JSON Output

在很多场景下，用户需要让模型严格按照 JSON 格式来输出，以实现输出的结构化，便于后续逻辑进行解析。

DeepSeek 提供了 JSON Output 功能，来确保模型输出合法的 JSON 字符串。

## 注意事项 [​](https://api-docs.deepseek.com/zh-cn/guides/json_mode\#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9 "注意事项的直接链接")

1. 设置 `response_format` 参数为 `{'type': 'json_object'}`。
2. 用户传入的 system 或 user prompt 中必须含有 `json` 字样，并给出希望模型输出的 JSON 格式的样例，以指导模型来输出合法 JSON。
3. 需要合理设置 `max_tokens` 参数，防止 JSON 字符串被中途截断。
4. **在使用 JSON Output 功能时，API 有概率会返回空的 content。我们正在积极优化该问题，您可以尝试修改 prompt 以缓解此类问题。**

## 样例代码 [​](https://api-docs.deepseek.com/zh-cn/guides/json_mode\#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81 "样例代码的直接链接")

这里展示了使用 JSON Output 功能的完整 Python 代码：

```codeBlockLines_UUn8
import json
from openai import OpenAI

client = OpenAI(
    api_key="<your api key>",
    base_url="https://api.deepseek.com",
)

system_prompt = """
The user will provide some exam text. Please parse the "question" and "answer" and output them in JSON format.

EXAMPLE INPUT:
Which is the highest mountain in the world? Mount Everest.

EXAMPLE JSON OUTPUT:
{
    "question": "Which is the highest mountain in the world?",
    "answer": "Mount Everest"
}
"""

user_prompt = "Which is the longest river in the world? The Nile River."

messages = [{"role": "system", "content": system_prompt},\
            {"role": "user", "content": user_prompt}]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages,
    response_format={
        'type': 'json_object'
    }
)

print(json.loads(response.choices[0].message.content))

```

模型将会输出：

```codeBlockLines_UUn8
{
    "question": "Which is the longest river in the world?",
    "answer": "The Nile River"
}

```

- [注意事项](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)
- [样例代码](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81)
