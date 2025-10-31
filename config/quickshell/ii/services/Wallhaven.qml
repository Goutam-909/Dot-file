pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var wallpapers: []
    property bool loading: false
    property string errorMessage: ""

    signal wallpapersLoaded()
    signal errorOccurred(string message)

    // Basic input sanitization
    function sanitizeQuery(query) {
        if (typeof query !== 'string') return ""
            // Remove potentially dangerous characters
            return query.replace(/[^\w\s\-.,!?]/g, '').trim().substring(0, 200)
    }

    // Fetch wallpapers from Wallhaven API (using curl - it's safe for API calls)
    function fetchWallpapers(category, query = "", page = 1) {
        root.loading = true
        root.errorMessage = ""

        // Validate inputs
        const validCategories = ["toplist", "latest", "random", "search"]
        if (!validCategories.includes(category)) {
            category = "toplist"
        }

        page = Math.max(1, Math.min(parseInt(page) || 1, 1000))

        let url = "https://wallhaven.cc/api/v1/search?"

        switch(category) {
            case "toplist":
                url += "sorting=toplist&page=" + page
                break
            case "latest":
                url += "sorting=date_added&order=desc&page=" + page
                break
            case "random":
                url += "sorting=random&page=1"
                break
            case "search":
                if (query !== "") {
                    const sanitized = sanitizeQuery(query)
                    url += "q=" + encodeURIComponent(sanitized) + "&sorting=relevance&page=" + page
                } else {
                    url += "sorting=relevance&page=" + page
                }
                break
            default:
                url += "sorting=toplist&page=" + page
        }

        // Add default parameters
        url += "&categories=111&purity=100&atleast=1920x1080"

        console.log("Fetching from:", url)

        const proc = fetchProcess.createObject(root, {
            "url": url,
            "command": ["curl", "-s", url]
        })
        proc.start()
    }

    // Validate that data looks safe before accepting it
    function validateWallpaperItem(item) {
        if (!item || typeof item !== 'object') {
            console.log("Invalid item object")
            return false
        }

        // Must have required fields
        if (!item.id || !item.url || !item.path) {
            console.log("Missing required fields:", item.id, item.url, item.path)
            return false
        }

        // URLs must be from wallhaven or wallhaven CDN domains
        const validDomains = [
            /^https?:\/\/(www\.)?wallhaven\.cc/,
            /^https?:\/\/w\.wallhaven\.cc/,
            /^https?:\/\/th\.wallhaven\.cc/,  // Thumbnails
            /^https?:\/\/wallhaven\.tv/
        ]

        function isValidUrl(url) {
            if (!url) return true  // Optional URLs are ok
                return validDomains.some(pattern => pattern.test(url))
        }

        if (!isValidUrl(item.url)) {
            console.log("Invalid URL domain:", item.url)
            return false
        }
        if (!isValidUrl(item.path)) {
            console.log("Invalid path domain:", item.path)
            return false
        }
        if (!isValidUrl(item.thumbs?.large)) {
            console.log("Invalid large thumb domain:", item.thumbs?.large)
            return false
        }
        if (!isValidUrl(item.thumbs?.small)) {
            console.log("Invalid small thumb domain:", item.thumbs?.small)
            return false
        }
        if (!isValidUrl(item.thumbs?.original)) {
            console.log("Invalid original thumb domain:", item.thumbs?.original)
            return false
        }

        return true
    }

    Component {
        id: fetchProcess

        Process {
            property string url: ""
            running: false

            function start() {
                running = true
            }

            stdout: StdioCollector {
                id: collector
                onStreamFinished: {
                    try {
                        const response = JSON.parse(collector.text)

                        if (response.error) {
                            root.errorMessage = String(response.error).substring(0, 200)
                            root.errorOccurred(root.errorMessage)
                            root.loading = false
                            return
                        }

                        if (!Array.isArray(response.data)) {
                            root.errorMessage = "Invalid response format"
                            root.errorOccurred(root.errorMessage)
                            root.loading = false
                            return
                        }

                        // Validate and sanitize all wallpaper data
                        const validWallpapers = response.data
                        .filter(item => validateWallpaperItem(item))
                        .map(item => ({
                            id: String(item.id),
                                      url: item.url,
                                      shortUrl: item.short_url || "",
                                      views: Math.max(0, parseInt(item.views) || 0),
                                      favorites: Math.max(0, parseInt(item.favorites) || 0),
                                      resolution: String(item.resolution || ""),
                                      colors: Array.isArray(item.colors) ? item.colors.slice(0, 10) : [],
                                      tags: Array.isArray(item.tags) ? item.tags.slice(0, 20) : [],
                                      thumbs: {
                                          large: item.thumbs?.large || "",
                                          original: item.thumbs?.original || "",
                                          small: item.thumbs?.small || ""
                                      },
                                      path: item.path
                        }))

                        if (validWallpapers.length === 0) {
                            root.errorMessage = "No valid wallpapers found in response"
                            root.errorOccurred(root.errorMessage)
                            root.loading = false
                            return
                        }

                        root.wallpapers = validWallpapers
                        root.wallpapersLoaded()

                        console.log("Loaded", validWallpapers.length, "wallpapers")
                    } catch (e) {
                        root.errorMessage = "Failed to parse response: " + e.toString()
                        root.errorOccurred(root.errorMessage)
                        console.error("Parse error:", e.toString())
                        console.error("Response text:", collector.text.substring(0, 500))
                    }

                    root.loading = false
                }
            }

            onExited: (code, status) => {
                if (code !== 0) {
                    root.errorMessage = "Network request failed (curl exit code: " + code + ")"
                    root.errorOccurred(root.errorMessage)
                    root.loading = false
                    console.error("curl failed with code:", code)
                }
            }
        }
    }
}
