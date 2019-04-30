#!/usr/bin/env bash
set -e

pkg_dir=$1

if [ -z $pkg_dir ] || [ ! -d $pkg_dir ]; then
	echo "Usage: ipkg-make-index <package_directory>" >&2
	exit 1
fi

empty=1

for pkg in `find -L $pkg_dir -name '*.ipk' | sort`; do
	empty=
	name="${pkg##*/}"
	name="${name%%_*}"

	[[ "$name" = "kernel" ]] && continue
	[[ "$name" = "libc" ]] && continue

	echo "Generating index for package $pkg" >&2
	file_size=$(stat -L -c%s $pkg)

	# sha256sum=$(mkhash sha256 $pkg)
	md5sum=$(md5sum $pkg | awk '{print $1}')

	# Take pains to make variable value sed-safe
	sed_safe_pkg=`echo $pkg | sed -e 's/^\.\///g' -e 's/\\//\\\\\\//g'`

	if tar -xzOf $pkg ./control.tar.gz >/dev/null 2>&1; then
		tar -xzOf $pkg ./control.tar.gz | tar xzOf - ./control | sed -e "s/^Description:/Filename: $sed_safe_pkg\\
Size: $file_size\\
MD5Sum: $md5sum\\
Description:/" |
sed -e "s/^Description:[ ]*/Description: /" |
sed -e '/^Compiler:/d; /^License:/d; /^LicenseFiles:/d; /^Source:/d; /^Maintainer:/d'
	else
		tar -xzOf $pkg control.tar.gz | tar xzOf - control | sed -e "s/^Description:/Filename: $sed_safe_pkg\\
Size: $file_size\\
MD5Sum: $md5sum\\
Description:/" |
sed -e "s/^Description:[ ]*/Description: /" |
sed -e '/^Compiler:/d; /^License:/d; /^LicenseFiles:/d; /^Source:/d; /^Maintainer:/d'
	fi

	echo ""
done

[ -n "$empty" ] && echo
exit 0
