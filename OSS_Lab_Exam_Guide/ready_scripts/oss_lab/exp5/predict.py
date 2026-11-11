#!/usr/bin/env python3
# Predictive maintenance: asks the AI if resources will run out soon
import os, json, urllib.request

CSV = "exp5/metrics.csv"
MODELS = ["gemini-3.1-flash-lite", "gemini-3.5-flash-lite", "gemini-2.5-flash"]

# 1. Read the last 10 readings
lines = open(CSV).read().strip().split("\n")
header, rows = lines[0], lines[1:][-10:]
last = rows[-1].split(",")
disk, mem = float(last[1]), float(last[2])

# 2. Build the prompt
prompt = ("You are a Linux predictive maintenance assistant. Thresholds: disk 80%, memory 90%.\n"
          "Look at the trend in these readings and predict if resources will run out soon.\n"
          "Reply in exactly this format:\n"
          "RISK: low or medium or high\n"
          "SUMMARY: one or two sentences\n"
          "ACTIONS: two short fixes\n\n" + header + "\n" + "\n".join(rows))

# 3. Ask Gemini (try each model in turn)
key = os.environ.get("GEMINI_API_KEY", "")
answer = None
for model in MODELS:
    if key == "":
        break
    try:
        url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent"
        body = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode()
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "x-goog-api-key": key})
        result = json.loads(urllib.request.urlopen(req, timeout=60).read())
        answer = result["candidates"][0]["content"]["parts"][0]["text"]
        print("Prediction by", model)
        break
    except Exception as e:
        print(model, "failed:", e)

# 4. Fallback rule if the AI is not reachable
if answer is None:
    if disk >= 95 or mem >= 90:
        risk = "high"
    elif disk >= 80:
        risk = "medium"
    else:
        risk = "low"
    answer = ("RISK: " + risk + "\nSUMMARY: Rule-based check (AI not reachable). Disk " + str(disk) +
              "%, memory " + str(mem) + "%.\nACTIONS: Clean large files (du -sh * | sort -h); stop heavy processes (top).")

# 5. Pick out the risk level and save the files
text = answer.lower().replace("*", "")
risk = "low"
if "risk: high" in text:
    risk = "high"
elif "risk: medium" in text:
    risk = "medium"
if disk >= 95 or mem >= 90:
    risk = "high"   # safety rule: a critical reading is always high risk
open("exp5/risk.txt", "w").write(risk)
open("exp5/prediction.md", "w").write("# Predictive Maintenance Report\n\n" + answer + "\n")
print(answer)
print("Risk level:", risk)
