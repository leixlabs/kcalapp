#!/usr/bin/env python3
"""本地 Mock LLM 服务器（OpenAI 兼容 /chat/completions）。

用途：
- Appium 自循环测试时，让 App 的 LLM 配置指向 http://127.0.0.1:8611/v1
- 返回固定的食物识别 JSON，保证测试确定性
- 记录所有收到的请求，可通过 GET /requests 查询（用于断言"请求真的发出了"）

启动：python3 mock_llm_server.py [port]
"""
import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

RECEIVED = []  # 收到的请求摘要列表
LOCK = threading.Lock()

FIXED_RESULT = {
    "meal_name": "香煎鸡胸能量碗",
    "items": [
        {"name": "香煎鸡胸肉", "category_id": "meat_eggs_seafood", "weight_g": 100, "kcal": 165, "carbs_g": 0, "protein_g": 31, "fat_g": 3.6, "confidence": "high",
         "minerals": [11, 3, 0.9, 29, 220, 25, 8, 0, 12, 220, 30],
         "vitamins": [5, 0.07, 0.1, 0.5, 0, 0.12, 0.3, 8, 0, 0, 0.3, 0.2, 0]},
        {"name": "水煮蛋", "category_id": "meat_eggs_seafood", "weight_g": 50, "kcal": 72, "carbs_g": 0.6, "protein_g": 6.3, "fat_g": 4.8, "confidence": "high",
         "minerals": [25, 1.5, 0.9, 5, 62, 16, 6, 0, 25, 70, 5],
         "vitamins": [75, 0.02, 0.2, 0.04, 0.7, 0.06, 5, 25, 0.6, 0, 1.1, 0.5, 0.3]},
        {"name": "甜玉米粒", "category_id": "grains", "weight_g": 60, "kcal": 56, "carbs_g": 12.2, "protein_g": 2, "fat_g": 0.7, "confidence": "high",
         "minerals": [1, 0.3, 0.3, 0.6, 150, 30, 1, 0, 2, 77, 5],
         "vitamins": [3, 0.1, 0.05, 0.6, 0.2, 0.1, 0, 10, 0, 6, 0, 0.2, 0]},
        {"name": "毛豆", "category_id": "dairy_beans_nuts", "weight_g": 40, "kcal": 52, "carbs_g": 3.6, "protein_g": 4.4, "fat_g": 2.4, "confidence": "high",
         "minerals": [24, 3.5, 1.4, 64, 54, 36, 15, 0, 18, 135, 10],
         "vitamins": [15, 0.15, 0.1, 0.3, 0.2, 0.05, 0, 25, 0, 10, 0, 0.1, 0]},
        {"name": "圣女果", "category_id": "vegetables_fruits", "weight_g": 60, "kcal": 18, "carbs_g": 2.3, "protein_g": 0.9, "fat_g": 0.2, "confidence": "high",
         "minerals": [3, 0.3, 0.15, 0.5, 12, 26, 4, 0, 5, 25, 6],
         "vitamins": [42, 0.06, 0.03, 0.2, 0.2, 0.06, 0, 16, 0, 32, 0, 0.2, 0]},
        {"name": "紫甘蓝", "category_id": "vegetables_fruits", "weight_g": 40, "kcal": 12, "carbs_g": 2.9, "protein_g": 0.6, "fat_g": 0.1, "confidence": "high",
         "minerals": [18, 0.4, 0.3, 5, 60, 32, 4, 0, 3, 30, 8],
         "vitamins": [2, 0.04, 0.04, 0.4, 0.1, 0.1, 0, 25, 0, 40, 0, 0.2, 0]},
    ],
    "overall_confidence": "high",
    "notes": "鸡胸肉与鸡蛋提供优质蛋白，搭配玉米和时蔬，营养均衡，可适量补充主食。",
}


def _chat_completion(content_obj):
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion",
        "created": 0,
        "model": "mock-vision",
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": json.dumps(content_obj, ensure_ascii=False)},
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


def _chat_completion_text(text):
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion",
        "created": 0,
        "model": "mock-vision",
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": text},
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


WEEKLY_RESULT = {
    "happened": "这周的餐桌很有节奏：鸡胸肉和鸡蛋几乎天天报到，蔬菜水果也没落下，只是主食偏少，晚饭常常吃得太急。",
    "improvement": "下周给晚餐加一小碗糙米饭，主食别总缺席。",
}

REVIEW_TEXT = "整体搭配很均衡，优质蛋白和蔬菜都到位，若再补一小份主食会更耐饿。"


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length)
        if self.path.endswith("/chat/completions"):
            summary = {"path": self.path, "bytes": length}
            content = None
            try:
                payload = json.loads(raw.decode("utf-8"))
                summary["model"] = payload.get("model")
                # 记录是否带图片（识别请求）还是纯文本（连通性验证/评价/周回顾）
                content = payload["messages"][0]["content"]
                summary["has_image"] = isinstance(content, list)
            except Exception:
                pass
            with LOCK:
                RECEIVED.append(summary)
            print(f"[mock] POST {self.path} bytes={length} has_image={summary.get('has_image')}", flush=True)
            text = content if isinstance(content, str) else ""
            if "锐评" in text or '"happened"' in text:
                self._send_json(_chat_completion(WEEKLY_RESULT))
            elif "饮食评价" in text or "dietary review" in text:
                self._send_json(_chat_completion_text(REVIEW_TEXT))
            else:
                self._send_json(_chat_completion(FIXED_RESULT))
        else:
            self._send_json({"error": "not found"}, status=404)

    def do_GET(self):
        if self.path == "/requests":
            with LOCK:
                self._send_json(list(RECEIVED))
        elif self.path == "/reset":
            with LOCK:
                RECEIVED.clear()
            self._send_json({"ok": True})
        elif self.path == "/health":
            self._send_json({"ok": True})
        else:
            self._send_json({"error": "not found"}, status=404)

    def log_message(self, fmt, *args):  # 静音默认访问日志
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8611
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"[mock] listening on http://127.0.0.1:{port}", flush=True)
    server.serve_forever()
