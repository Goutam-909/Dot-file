from googleapiclient.discovery import build

API_KEY = "AIzaSyAM1jBqOnRKrq89LSvUkf1_NSldOdNxdMs"
CX = "c5e79c02f29d84efa"

def google_search(query, api_key=API_KEY, cx=CX, num=5):
    service = build("customsearch", "v1", developerKey=api_key)
    res = service.cse().list(q=query, cx=cx, num=num).execute()
    results = res.get("items", [])
    for i, item in enumerate(results, start=1):
        print(f"{i}. {item['title']}\n{item['link']}\n{item.get('snippet','')}\n")

google_search("best opamp for signal conditioning")
