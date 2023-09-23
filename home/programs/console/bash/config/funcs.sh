function installed_packages() {
    local count="${1:-10}"
    ls -tl /var/lib/dpkg/info/*.list \
        | head -n $count \
        | awk '{print $11}' \
        | xargs -n1 basename \
        | sed -e "s/.list$//"
}