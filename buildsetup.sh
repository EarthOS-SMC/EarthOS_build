# Project name
uname="EarthOS"

# Release
release="2.1.0-wip-rc6" # EarthOS version
build_date=$(date -u +"%m-%d-%Y-%H-%M")
build_type="UNOFFICIAL"
echo "$uname" > ../installer/rootfs/etc/release
echo "$release" >> ../installer/rootfs/etc/release
echo "${release}-${build_date}" >> ../installer/rootfs/etc/release
echo $build_type >> ../installer/rootfs/etc/release
