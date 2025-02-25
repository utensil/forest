import time
import requests
from datetime import datetime
import os
import json

ENDPOINT_URL = os.getenv("OPENAI_API_BASE")
API_KEY = os.getenv("OPENAI_API_KEY")
MODEL = os.getenv("OPENAI_API_MODEL")

# PROMPT = "List 2 sights near but not in Paris."
PROMPT = "Give me only one pair of words that can be combined to form a new word. Finish your thinking in 50 words or less."

COUNT = 2

print(f"Endpoint URL: {ENDPOINT_URL}")
print(f"Model: {MODEL}")

# quit()


def benchmark_endpoint():
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"}

    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": PROMPT}],
        "stream": True,
        "max_tokens": 10000,
    }

    metrics = {"ttft": [], "tps": [], "total_tokens": [], "total_time": []}

    for i in range(COUNT):
        try:
            # 计时开始
            start_time = time.perf_counter()
            first_token_time = None
            token_count = 0

            print(f"请求 {i + 1}/{COUNT} 开始: {datetime.now().isoformat()}")

            # 发送请求
            response = requests.post(
                f"{ENDPOINT_URL}chat/completions",
                headers=headers,
                json=payload,
                stream=True,
                timeout=30,
            )

            # 处理流式响应
            for chunk in response.iter_lines():
                if chunk:
                    decoded = chunk.decode().lstrip("data: ").strip()
                    # print(decoded)

                    if decoded == "[DONE]":
                        break

                    # 解析JSON
                    try:
                        data = json.loads(decoded)
                        if "choices" in data:
                            # 记录首令牌时间
                            if not first_token_time:
                                first_token_time = time.perf_counter()
                                ttft = first_token_time - start_time
                                metrics["ttft"].append(ttft)

                            # 统计令牌
                            delta = data["choices"][0]["delta"].get("content", "")
                            token_count += len(delta.split())

                            # print the variable delta, just not to start a new line
                            print(delta, end="")
                    except Exception as e:
                        print(f"解析错误: {e}")
                        continue

            print("\n")

            # 计算TPS
            if first_token_time:
                total_time = time.perf_counter() - first_token_time
                tps = token_count / total_time if total_time > 0 else 0
                metrics["tps"].append(tps)
                metrics["total_tokens"].append(token_count)
                metrics["total_time"].append(total_time)

        except Exception as e:
            print(f"请求失败: {str(e)}")
            continue

    # 打印结果
    print(f"\n基准测试结果（{COUNT}次请求）:")
    print(f"平均耗时: {sum(metrics['total_time']) / len(metrics['total_time']):.3f}s")
    print(f"平均TTFT: {sum(metrics['ttft']) / len(metrics['ttft']):.3f}s")
    print(f"平均TPS: {sum(metrics['tps']) / len(metrics['tps']):.1f} tokens/s")
    print(f"总处理token数: {sum(metrics['total_tokens'])} tokens")


if __name__ == "__main__":
    benchmark_endpoint()
