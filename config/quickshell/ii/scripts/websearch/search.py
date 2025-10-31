#!/usr/bin/env python3
"""
Web Search Script for Quickshell
Supports Google Custom Search API with pagination
"""

import sys
import os
import json

try:
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print(json.dumps({"error": "google-api-python-client not installed. Run: pip install google-api-python-client"}))
    sys.exit(1)


def google_search(query, page=1):
    """
    Search using Google Custom Search JSON API

    Args:
        query: Search query string
        page: Page number (1-based)

    Returns:
        dict with 'results', 'totalResults', and 'currentPage'
    """
    api_key = os.getenv("GOOGLE_API_KEY")
    cx = os.getenv("GOOGLE_CX")

    if not api_key:
        return {
            "error": "GOOGLE_API_KEY not set. Export it in your shell:\nexport GOOGLE_API_KEY='your-key-here'",
            "results": [],
            "totalResults": 0,
            "currentPage": page
        }

    if not cx:
        return {
            "error": "GOOGLE_CX (Search Engine ID) not set. Export it in your shell:\nexport GOOGLE_CX='your-cx-here'",
            "results": [],
            "totalResults": 0,
            "currentPage": page
        }

    try:
        service = build("customsearch", "v1", developerKey=api_key)

        # Calculate start index (Google uses 1-based indexing)
        start_index = (page - 1) * 10 + 1

        # Execute search
        result = service.cse().list(
            q=query,
            cx=cx,
            num=10,  # Results per page
            start=start_index
        ).execute()

        # Extract results
        items = result.get("items", [])
        search_info = result.get("searchInformation", {})
        total_results = search_info.get("totalResults", "0")

        # Format results
        results = []
        for item in items:
            results.append({
                "title": item.get("title", "No title"),
                "url": item.get("link", ""),
                "description": item.get("snippet", "No description available")
            })

        return {
            "results": results,
            "totalResults": int(total_results),
            "currentPage": page
        }

    except HttpError as e:
        error_details = json.loads(e.content.decode('utf-8'))
        error_message = error_details.get('error', {}).get('message', str(e))

        return {
            "error": f"Google API Error: {error_message}",
            "results": [],
            "totalResults": 0,
            "currentPage": page
        }

    except Exception as e:
        return {
            "error": f"Unexpected error: {str(e)}",
            "results": [],
            "totalResults": 0,
            "currentPage": page
        }


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print(json.dumps({
            "error": "Usage: search.py <query> [page]",
            "results": [],
            "totalResults": 0,
            "currentPage": 1
        }))
        sys.exit(1)

    query = sys.argv[1]
    page = int(sys.argv[2]) if len(sys.argv) > 2 else 1

    # Validate page number
    if page < 1:
        page = 1

    # Perform search
    result = google_search(query, page)

    # Output JSON
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
