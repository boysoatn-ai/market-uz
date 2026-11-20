import json, os, urllib.request, pathlib
key = os.environ.get("XI", "")
out = pathlib.Path("tts/out"); out.mkdir(parents=True, exist_ok=True)
log = []
def call(url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body else None,
        headers={"xi-api-key": key, "Content-Type": "application/json"}, method="POST" if body else "GET")
    with urllib.request.urlopen(req, timeout=120) as r: return r.read()
if not key:
    (out / "log.txt").write_text("NO KEY"); raise SystemExit(0)
job = json.load(open("tts/job.json"))
if job.get("list_voices", True):
    vs = json.loads(call("https://api.elevenlabs.io/v1/voices"))["voices"]
    (out / "voices.json").write_text(json.dumps([{"id": v["voice_id"], "name": v["name"], "category": v.get("category"), "labels": v.get("labels"), "desc": v.get("description")} for v in vs], ensure_ascii=False, indent=1))
    sub = json.loads(call("https://api.elevenlabs.io/v1/user/subscription"))
    log.append(f"credits {sub.get('character_count')}/{sub.get('character_limit')}")
for it in job.get("items", []):
    body = {"text": it["text"], "model_id": it.get("model", "eleven_v3"), "voice_settings": it.get("settings", {"stability": 0.0, "similarity_boost": 0.8, "use_speaker_boost": True})}
    try:
        data = call(f"https://api.elevenlabs.io/v1/text-to-speech/{it['voice']}?output_format=mp3_44100_128", body)
        (out / (it["name"] + ".mp3")).write_bytes(data); log.append(f"ok {it['name']}")
    except urllib.error.HTTPError as e:
        log.append(f"ERR {it['name']} {e.code} {e.read()[:300]!r}")
(out / "log.txt").write_text("\n".join(log))
print("\n".join(log))
