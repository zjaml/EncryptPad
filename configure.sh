#!/bin/bash

USAGE="USAGE:\n\
configure.sh <command> [option]\n\n\
COMMANDS:\n\
-a, --all\tbuild everything required to run the application including Botan\n\
-c, --clean\tclean the application build files\n\
-r, --run\trun the application\n\
-b, --botan\tbuild Botan\n\
-o, --clean-botan\tclean Botan\n\
-e, --back-end\tbuild the back end with CLI\n\
-u, --tests\tbuild the unit tests\n\
-t, --run-tests\trun the unit tests\n\
-n, --clean-tests\tclean the unit tests\n\
-h, --help\thelp\n\n\
OPTIONS:\n\
--debug\tdebug configuration. If not specified, the release configuration is used. The unit tests\n\
are always built with the debug configuration.\n\
--use-system-libs\tuse botan, zlib and other shared libraries installed on the system."

TARGET=EncryptPad
TEST_TARGET=encrypt_pad_tests

if [[ $# > 3 ]] || [[ $# < 1 ]]
then
    echo Invalid parameters >&2
    echo -e $USAGE
    exit -1
fi



UNAME=`uname`
MAKE=make
if [[ $UNAME == *MINGW* ]]
then
    MAKE=mingw32-make
fi

pushd ./build >/dev/null
SUBDIR=`./get_subdir.sh`

RELEASE=on
QT_BIN_SUB=release

while [[ $# > 0 ]]
do
    case $1 in
        -d|--debug)
            RELEASE=
            QT_BIN_SUB=debug
            ;;
        --use-system-libs)
            USE_SYSTEM_LIBS=on
            ;;
        *)
            COMMAND=$1
            ;;
    esac
    shift
done

case $COMMAND in
-a|--all)
    if [[ ! "$USE_SYSTEM_LIBS" == "on" ]]
    then
        $MAKE -f Makefile.botan
    fi
    $MAKE -f Makefile RELEASE=$RELEASE USE_SYSTEM_LIBS=$USE_SYSTEM_LIBS
    if [[ $SUBDIR == *MACOS* ]]
    then
        cd ../macos_deployment && ./prepare_bundle.sh ../build/qt_build/${QT_BIN_SUB}/${TARGET}.app
    fi
    ;;
-c|--clean) 
    $MAKE -f Makefile.qt_ui clean RELEASE=$RELEASE 
    $MAKE -f Makefile clean RELEASE=$RELEASE 

    if [[ $SUBDIR == *MACOS* ]]
    then
        rm -Rf ./qt_build/${QT_BIN_SUB}/${TARGET}.app
    elif [[ $UNAME == *MINGW* ]]
    then
        rm -f ./qt_build/${QT_BIN_SUB}/${TARGET}.exe
    else
        rm -f ./qt_build/${QT_BIN_SUB}/${TARGET}
    fi
    ;;
-r|--run) 
    if [[ $SUBDIR == *MACOS* ]]
    then
        ./qt_build/${QT_BIN_SUB}/${TARGET}.app/Contents/MacOS/${TARGET} &
    else
        ./qt_build/${QT_BIN_SUB}/${TARGET} &
    fi
    ;;
-b|--botan) $MAKE -f Makefile.botan ;;
-o|--clean-botan) $MAKE -f Makefile.botan clean ;;
-e|--back-end)
    $MAKE -f Makefile.back_end RELEASE=$RELEASE USE_SYSTEM_LIBS=$USE_SYSTEM_LIBS
    $MAKE -f Makefile.cli RELEASE=$RELEASE USE_SYSTEM_LIBS=$USE_SYSTEM_LIBS
    ;;
-u|--tests) $MAKE -f Makefile.unit_tests USE_SYSTEM_LIBS=$USE_SYSTEM_LIBS;;
-n|--clean-tests) $MAKE -f Makefile.unit_tests clean ;;
-t|--run-tests)
    # Unit tests should run from tests directory because they need files the directory contains
    pushd ../tests >/dev/null
    ./${SUBDIR}/${TEST_TARGET}
    RESULT=$?
    popd >/dev/null

    if [[ $RESULT != 0 ]] 
    then 
        popd >/dev/null
        exit $RESULT
    fi

    # Functional tests
    # pushd ../func_tests >/dev/null
    # ./decryption_test.sh ../cli/${SUBDIR}/encrypt_cli gpg_encrypted
    # RESULT=$?
    # popd >/dev/null

    popd >/dev/null
    exit $RESULT
    ;;
-h|--help) echo -e $USAGE ;;
*)  echo -e "$COMMAND is invalid parameter" >&2
    echo -e $USAGE
    popd >/dev/null
    exit -1
    ;;
esac

RESULT=$?
popd >/dev/null
exit $RESULT
