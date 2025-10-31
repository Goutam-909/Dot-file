import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image. It currently generates to the right place at the right size, but does not handle metadata/maintenance on modification.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: Images.thumbnailSizeNameForDimensions(sourceSize.width, sourceSize.height)
    property string thumbnailPath: {
        if (sourcePath.length == 0) return;
        const resolvedUrlWithoutFileProtocol = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(sourcePath)}`);
        const encodedUrlWithoutFileProtocol = resolvedUrlWithoutFileProtocol.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encodedUrlWithoutFileProtocol}`);
        return `${Directories.genericCache}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }
    source: thumbnailPath

    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onSourceSizeChanged: {
        if (!root.generateThumbnail) return;
        thumbnailGeneration.running = false;
        thumbnailGeneration.running = true;
    }

    function isVideoFile(path: string): bool {
        const videoExts = ["mp4", "webm", "mkv", "avi", "mov", "flv", "m4v", "wmv"];
        return videoExts.some(ext => path.toLowerCase().endsWith(`.${ext}`));
    }

    Process {
        id: thumbnailGeneration
        command: {
            const maxSize = Images.thumbnailSizes[root.thumbnailSizeName];
            const thumbPath = FileUtils.trimFileProtocol(root.thumbnailPath);
            const srcPath = root.sourcePath;

            // Check if it's a video file
            if (root.isVideoFile(srcPath)) {
                return ["bash", "-c",
                `[ -f '${thumbPath}' ] && exit 0 || { ffmpegthumbnailer -i '${srcPath}' -o '${thumbPath}' -s ${maxSize} -t 10% -q 8 2>/dev/null && exit 1; }`
                ]
            } else if (srcPath.toLowerCase().endsWith('.gif')) {
                // For GIFs, take first frame
                return ["bash", "-c",
                `[ -f '${thumbPath}' ] && exit 0 || { magick '${srcPath}[0]' -resize ${maxSize}x${maxSize} '${thumbPath}' && exit 1; }`
                ]
            } else {
                // Regular images
                return ["bash", "-c",
                `[ -f '${thumbPath}' ] && exit 0 || { magick '${srcPath}' -resize ${maxSize}x${maxSize} '${thumbPath}' && exit 1; }`
                ]
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Force reload if thumbnail had to be generated
                root.source = "";
                root.source = root.thumbnailPath; // Force reload
            }
        }
    }
}
