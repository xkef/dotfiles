# Reports whether each image has a linux/arm64 build, so it runs on Apple
# silicon without QEMU. Without arguments it checks the images of the
# compose project in the current directory.
#
#   imgarch postgres:17 mcr.microsoft.com/mssql/server
#   ✓ postgres:17
#   ✗ mcr.microsoft.com/mssql/server (amd64 only)
function imgarch --description 'Check images for a linux/arm64 build'
    set -l images $argv
    if test (count $images) -eq 0
        set images (docker-compose config --images)
        or return
    end

    set -l missing 0
    for image in $images
        # skopeo picks the arm64 entry from a multi-arch index and returns
        # the only build of a single-arch image, whatever its architecture.
        set -l arch (skopeo inspect --override-os linux --override-arch arm64 \
            --format '{{.Architecture}}' docker://$image 2>/dev/null)
        if test "$arch" = arm64
            echo "✓ $image"
            continue
        end

        set missing 1
        if test -z "$arch"
            echo "✗ $image (no arm64 build)"
        else
            echo "✗ $image ($arch only)"
        end
    end
    return $missing
end
