cmake_minimum_required(VERSION 3.1)

project(seqwish)
set(CMAKE_CXX_STANDARD 14)

enable_testing()

include(GNUInstallDirs)
include(FeatureSummary)

set(THREADS_PREFER_PTHREAD_FLAG ON)

set(CMAKE_CXX_STANDARD_REQUIRED ON)  # Falling back to different standard is not allowed.
set(CMAKE_CXX_EXTENSIONS OFF)  # Make sure no compiler-specific features are used.

if (STOP_ON_ERROR)
  add_definitions( -Wfatal-errors )
endif()

find_package(PkgConfig REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Threads REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(SDSLLITE sdsl-lite)
pkg_check_modules(atomicqueue atomicqueue)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING
          "Choose the type of build, options are: Release Debug Generic." FORCE)
endif()

# set(CMAKE_BUILD_TYPE Debug) -- don't uncomment this, instead run
#   cmake -DCMAKE_BUILD_TYPE=Debug ..

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")

if(NOT DEFINED EXTRA_FLAGS)
  set(EXTRA_FLAGS "-march=native" CACHE STRING
          "Extra compilation flags for C and CXX." FORCE)
endif()

if (${CMAKE_BUILD_TYPE} MATCHES Release)
  set(EXTRA_FLAGS "-Ofast ${EXTRA_FLAGS}")
  set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG") # reset CXX_FLAGS to replace -O3 with -Ofast
endif ()

if (${CMAKE_BUILD_TYPE} MATCHES Generic)
  set(EXTRA_FLAGS "-O3")
  set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG") # reset CXX_FLAGS to replace -O3 with -Ofast
endif ()

if (${CMAKE_BUILD_TYPE} MATCHES Debug)
  # Debug use the defaults
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O -g -fsanitize=address")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O -g -fsanitize=address")
else()
  # Use all standard-compliant optimizations - always add these:
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS} ${PIC_FLAG} ${EXTRA_FLAGS}")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} ${PIC_FLAG} ${EXTRA_FLAGS}")
endif ()

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin") # untested
  # assumes clang build
  # we can't reliably detect when we're using clang, so for the time being we assume
  # TODO: can't we though?
  # adapted from https://stackoverflow.com/questions/46414660/macos-cmake-and-openmp
  # find_package(OpenMP) does not work reliably on macOS, so we do its work ourselves
  set (OpenMP_C "${CMAKE_C_COMPILER}")
  set (OpenMP_C_FLAGS " -Xpreprocessor -fopenmp -I/opt/local/include/libomp -I/usr/local/include -L/opt/local/lib/libomp -L/usr/local/lib")
  set (OpenMP_C_LIB_NAMES "libomp" "libgomp" "libiomp5")
  set (OpenMP_CXX "${CMAKE_CXX_COMPILER}")
  set (OpenMP_CXX_FLAGS " -Xpreprocessor -fopenmp -I/opt/local/include/libomp -I/usr/local/include -L/opt/local/lib/libomp -L/usr/local/lib")
  set (OpenMP_CXX_LIB_NAMES "libomp" "libgomp" "libiomp5")
  set (OpenMP_libomp_LIBRARY "omp")
  set (OpenMP_libgomp_LIBRARY "gomp")
  set (OpenMP_libiomp5_LIBRARY "iomp5")
  # and now add the OpenMP parameters to the compile flags
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
  set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS} -lomp")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  find_package(OpenMP REQUIRED)
  # add the flags it detects to the compile flags
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS} -fopenmp")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -fopenmp")
  set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()

# Set the output folder where your program will be created
set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})
set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/lib)

# The following folder will be included
include_directories("${PROJECT_SOURCE_DIR}")

# Add external projects
include(${CMAKE_ROOT}/Modules/ExternalProject.cmake)

set(CMAKE_BUILD_TYPE Release)

# set up our target executable and specify its dependencies and includes
add_executable(seqwish
  ${CMAKE_SOURCE_DIR}/src/utils.cpp
  ${CMAKE_SOURCE_DIR}/src/tempfile.cpp
  ${CMAKE_SOURCE_DIR}/src/main.cpp
  ${CMAKE_SOURCE_DIR}/src/seqindex.cpp
  ${CMAKE_SOURCE_DIR}/src/paf.cpp
  ${CMAKE_SOURCE_DIR}/src/sxs.cpp
  ${CMAKE_SOURCE_DIR}/src/cigar.cpp
  ${CMAKE_SOURCE_DIR}/src/alignments.cpp
  ${CMAKE_SOURCE_DIR}/src/pos.cpp
  ${CMAKE_SOURCE_DIR}/src/match.cpp
  ${CMAKE_SOURCE_DIR}/src/transclosure.cpp
  ${CMAKE_SOURCE_DIR}/src/links.cpp
  ${CMAKE_SOURCE_DIR}/src/compact.cpp
  ${CMAKE_SOURCE_DIR}/src/dna.cpp
  ${CMAKE_SOURCE_DIR}/src/gfa.cpp
  ${CMAKE_SOURCE_DIR}/src/vgp.cpp
  ${CMAKE_SOURCE_DIR}/src/exists.cpp
  ${CMAKE_SOURCE_DIR}/src/time.cpp
  ${CMAKE_SOURCE_DIR}/src/mmap.cpp
  ${CMAKE_SOURCE_DIR}/src/version.cpp
  )

target_include_directories(seqwish PUBLIC
  # $ENV{GUIX_ENVIRONMENT}/include
  $ENV{GUIX_ENVIRONMENT}/include/atomic_queue # because the last dir is not included by the module
  "contrib/mmmulti/src"
  "contrib/mio/include"
  "contrib/atomicbitvector/include"
  "contrib/ips4o"
  "contrib/flat_hash_map"
  "contrib/paryfor"
  "${tayweeargs_INCLUDE}"
  "${gzipreader_INCLUDE}"
  "${ips4o_INCLUDE}"
  "${mmmulti_INCLUDE}"
  "${iitii_INCLUDE}"
  "${bbhash_INCLUDE}"
  "${atomicbitvector_INCLUDE}"
  "${atomicqueue_INCLUDE}"
  "${ska_INCLUDE}"
  "${paryfor_INCLUDE}"
  "${mio_INCLUDE}")
target_link_libraries(seqwish
  ${SDSLLITE_LINK_LIBRARIES}
  ${LIBDIVSUFSORT_LINK_LIBRARIES}
  "-latomic"
  Threads::Threads
  jemalloc
  z)
if (BUILD_STATIC)
  #set(CMAKE_EXE_LINKER_FLAGS "-static")
  set(CMAKE_EXE_LINKER_FLAGS "-static -Wl,--whole-archive -lpthread -Wl,--no-whole-archive")
endif()

add_test(
  NAME seqwish-test
  COMMAND bash -c "make"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/test)

# version stuff
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/include)
execute_process(COMMAND bash ${CMAKE_SOURCE_DIR}/scripts/generate_git_version.sh ${CMAKE_SOURCE_DIR}/include)

install(TARGETS seqwish DESTINATION bin)
