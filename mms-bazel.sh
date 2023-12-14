if [ -z "${CONTAINER_ID}" ]; then
  	exists=`distrobox list | rg mms-bazel`
	if [ -z "$exists" ]; then
	  	distrobox-create -n mms-bazel -ap "awscli2 gcc-c++ libxcrypt-compat"
	fi

	distrobox-enter  -n mms-bazel -- /usr/bin/bazel "$@"
else
	/usr/bin/bazel "$@"
fi
