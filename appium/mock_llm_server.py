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
    "meal_name": "测试早餐组合",
    "items": [
        {"name": "饺子", "weight_g": 200, "kcal": 350, "carbs_g": 43, "protein_g": 12, "fat_g": 14, "confidence": "high"},
        {"name": "鸡蛋", "weight_g": 50, "kcal": 70, "carbs_g": 0.5, "protein_g": 6, "fat_g": 5, "confidence": "high"},
        {"name": "橘子", "weight_g": 80, "kcal": 42, "carbs_g": 10, "protein_g": 1, "fat_g": 0.2, "confidence": "medium"},
    ],
    "overall_confidence": "high",
    "notes": "来自 mock 服务器的测试数据",
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
            try:
                payload = json.loads(raw.decode("utf-8"))
                summary["model"] = payload.get("model")
                # 记录是否带图片（识别请求）还是纯文本（连通性验证）
                content = payload["messages"][0]["content"]
                summary["has_image"] = isinstance(content, list)
            except Exception:
                pass
            with LOCK:
                RECEIVED.append(summary)
            print(f"[mock] POST {self.path} bytes={length} has_image={summary.get('has_image')}", flush=True)
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
