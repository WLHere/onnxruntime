
TARGET_SYSTEM=""

show_help()
{
    echo "USAGE: ./build.sh -option [args]"
    echo "       -s [Linux|macOS|Android|iOS]"
    echo "          setting target system"
    echo "       -h "
    echo "          with no args show help"
}

while getopts s:h opt;do
    case $opt in
        h)
        show_help
        exit 1;
        ;;
        s)TARGET_SYSTEM=$OPTARG
        ;;
        \?)
        show_help
        exit 1
    esac
done

if [ "$TARGET_SYSTEM" = "" ]; then
    show_help
    exit 1
fi


CUR_PWD=`pwd`
OUTPUT_LIBS_DIR=${CUR_PWD}/output_onnxruntime_libs
if [ ! -d "$OUTPUT_LIBS_DIR" ]; then
	mkdir output_onnxruntime_libs
	mkdir output_onnxruntime_libs/include
	mkdir output_onnxruntime_libs/lib
fi


# 编译移动端库以及版本
if [ "$TARGET_SYSTEM" = "Android" -o "$TARGET_SYSTEM" = "android" ]; then

	cd ${CUR_PWD}
	OUTPUT_BUILD_CONFIGS=(
		# "arm64-v8a,30,Release,full"
		#"arm64-v8a,21,Release,minimal"
		"armeabi-v7a,30,Release,full"
		#"armeabi-v7a,19,Release,minimal"
	)


	for CONFIG_ROW in "${OUTPUT_BUILD_CONFIGS[@]}"; do
		IFS=',' read ANDROID_ABI_NAME ANDROID_API_LEVEL BUILD_TYPE BUILD_MODE <<< "${CONFIG_ROW}"
		cd ${CUR_PWD}
		# 准备编译参数
		BUILD_DIR="build_for_android"
		FULL_BUILD_DIR=${CUR_PWD}/${BUILD_DIR}/${BUILD_TYPE}

		if [ -d "$FULL_BUILD_DIR" ]; then
			rm -fr "$FULL_BUILD_DIR"
		fi

		MODE_OPTIONS=""
		MODE_SUFFIX=""
		if [ "$BUILD_MODE" = "minimal" ]; then
			MODE_OPTIONS="--minimal_build"
			MODE_SUFFIX="-minimal"
	    fi
	    INSTALL_PREFIX="sharedlib"
	    INSTALL_DIR=${FULL_BUILD_DIR}/${INSTALL_PREFIX}
	    OUTPUT_INCLUDE_DIR=$OUTPUT_LIBS_DIR/include/onnxruntime
	    if [ ! -d "$OUTPUT_INCLUDE_DIR" ]; then
			mkdir -p $OUTPUT_INCLUDE_DIR
		fi
	    OUTPUT_LIB_DIR=$OUTPUT_LIBS_DIR/lib/android/${ANDROID_ABI_NAME}
	    if [ ! -d "$OUTPUT_LIB_DIR" ]; then
			mkdir -p $OUTPUT_LIB_DIR
		fi
	    # 编译
		sh build.sh \
			--build_dir ${BUILD_DIR} \
			--config ${BUILD_TYPE} \
			--build_shared_lib ${MODE_OPTIONS} \
			--parallel 12 \
			--android \
			--android_abi ${ANDROID_ABI_NAME} \
			--android_api ${ANDROID_API_LEVEL} \
			--android_sdk_path ${ANDROID_HOME} \
			--android_ndk_path ${ANDROID_NDK_ROOT} \
			--android_cpp_shared \
			--disable_rtti \
			--disable_ml_ops \
			--disable_exceptions \
			--skip_submodule_sync \
			--skip_tests \
			--skip_onnx_tests \
			--use_nnapi \
			--use_armnn \
			--armnn_home /home/bytedance/armnn-devenv/armnn \
			--armnn_libs /home/bytedance/armnn-devenv/armnn/build  \
			--acl_home /home/bytedance/armnn-devenv/ComputeLibrary \
			--acl_libs /home/bytedance/armnn-devenv/ComputeLibrary/build \
			--armnn_relu \
			--armnn_bn \
			--build_java \
			--use_preinstalled_eigen \
			--eigen_path /usr/local/include/eigen3 \
			--cmake_extra_defines CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
		cd ${FULL_BUILD_DIR}
		make install
		cd ${CUR_PWD}
		# 开始拷贝文件
		cp -fr ${INSTALL_DIR}/include/onnxruntime/* ${OUTPUT_INCLUDE_DIR}
		cp -f ${INSTALL_DIR}/lib/libonnxruntime.so ${OUTPUT_LIB_DIR}/libonnxruntime${MODE_SUFFIX}.so
	done

fi

# 编译MacOS版本
if [ "$TARGET_SYSTEM" = "macOS" -o "$TARGET_SYSTEM" = "macos" ]; then
	cd ${CUR_PWD}
	# 准备编译参数
	BUILD_DIR="build_for_macos"
	BUILD_TYPE="Release"
	FULL_BUILD_DIR=${CUR_PWD}/${BUILD_DIR}/${BUILD_TYPE}

	if [ -d "$FULL_BUILD_DIR" ]; then
		rm -fr "$FULL_BUILD_DIR"
	fi

	INSTALL_PREFIX="sharedlib"
	INSTALL_DIR=${FULL_BUILD_DIR}/${INSTALL_PREFIX}
	OUTPUT_INCLUDE_DIR=$OUTPUT_LIBS_DIR/include/onnxruntime
	if [ ! -d "$OUTPUT_INCLUDE_DIR" ]; then
		mkdir -p $OUTPUT_INCLUDE_DIR
	fi
	OUTPUT_LIB_DIR=$OUTPUT_LIBS_DIR/lib/macos
	if [ ! -d "$OUTPUT_LIB_DIR" ]; then
		mkdir -p $OUTPUT_LIB_DIR
	fi

	sh build.sh \
		--build_dir ${BUILD_DIR} \
		--config ${BUILD_TYPE} \
		--build_shared_lib \
		--osx_arch x86_64 \
		--apple_deploy_target 10.15 \
		--skip_tests \
		--skip_onnx_tests \
		--parallel 12 \
		--compile_no_warning_as_error \
		--skip_submodule_sync \
		--cmake_extra_defines CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}

	cd ${FULL_BUILD_DIR}
	make install
	cd ${CUR_PWD}
	# 开始拷贝文件
	cp -fr ${INSTALL_DIR}/include/onnxruntime/* ${OUTPUT_INCLUDE_DIR}
	cp -af ${INSTALL_DIR}/lib/*.dylib ${OUTPUT_LIB_DIR}
fi

# 编译Linux版本
if [ "$TARGET_SYSTEM" = "Linux" -o "$TARGET_SYSTEM" = "linux" ]; then
	cd ${CUR_PWD}
	# 准备编译参数
	BUILD_DIR="build_for_linux"
	BUILD_TYPE="Release"
	FULL_BUILD_DIR=${CUR_PWD}/${BUILD_DIR}/${BUILD_TYPE}

	if [ -d "$FULL_BUILD_DIR" ]; then
		rm -fr "$FULL_BUILD_DIR"
	fi

	INSTALL_PREFIX="sharedlib"
	INSTALL_DIR=${FULL_BUILD_DIR}/${INSTALL_PREFIX}
	OUTPUT_INCLUDE_DIR=$OUTPUT_LIBS_DIR/include/onnxruntime
	if [ ! -d "$OUTPUT_INCLUDE_DIR" ]; then
		mkdir -p $OUTPUT_INCLUDE_DIR
	fi
	OUTPUT_LIB_DIR=$OUTPUT_LIBS_DIR/lib/linux
	if [ ! -d "$OUTPUT_LIB_DIR" ]; then
		mkdir -p $OUTPUT_LIB_DIR
	fi

	sh build.sh \
		--build_dir ${BUILD_DIR} \
		--config ${BUILD_TYPE} \
		--build_shared_lib \
		--skip_tests \
		--skip_onnx_tests \
		--parallel 12 \
		--compile_no_warning_as_error \
		--skip_submodule_sync \
		--cmake_extra_defines CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}

	cd ${FULL_BUILD_DIR}
	make install
	cd ${CUR_PWD}
	# 开始拷贝文件
	cp -fr ${INSTALL_DIR}/include/onnxruntime/* ${OUTPUT_INCLUDE_DIR}
	cp -af ${INSTALL_DIR}/lib/*.dylib ${OUTPUT_LIB_DIR}
fi



