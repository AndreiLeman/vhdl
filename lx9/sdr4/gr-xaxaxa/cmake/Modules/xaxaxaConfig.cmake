INCLUDE(FindPkgConfig)
PKG_CHECK_MODULES(PC_XAXAXA xaxaxa)

FIND_PATH(
    XAXAXA_INCLUDE_DIRS
    NAMES xaxaxa/api.h
    HINTS $ENV{XAXAXA_DIR}/include
        ${PC_XAXAXA_INCLUDEDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/include
          /usr/local/include
          /usr/include
)

FIND_LIBRARY(
    XAXAXA_LIBRARIES
    NAMES gnuradio-xaxaxa
    HINTS $ENV{XAXAXA_DIR}/lib
        ${PC_XAXAXA_LIBDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
          /usr/local/lib
          /usr/local/lib64
          /usr/lib
          /usr/lib64
)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(XAXAXA DEFAULT_MSG XAXAXA_LIBRARIES XAXAXA_INCLUDE_DIRS)
MARK_AS_ADVANCED(XAXAXA_LIBRARIES XAXAXA_INCLUDE_DIRS)

