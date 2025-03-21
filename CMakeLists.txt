cmake_minimum_required(VERSION 3.1)

project(seqwish)
set(CMAKE_CXX_STANDARD 17)

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
pkg_check_modules(TBB tbb)
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

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_REENTRANT") # defined for ips4o::parallel

if (${CMAKE_BUILD_TYPE} MATCHES Debug)
  # Debug use the defaults
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O -g -fsanitize=address")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O -g -fsanitize=address")
else()
  # Use all standard-compliant optimizations - always add these:
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS} ${PIC_FLAG} ${EXTRA_FLAGS}")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} ${PIC_FLAG} ${EXTRA_FLAGS}")
endif ()

# --- Removed Darwin stuff - as it can probably be done a lot simpler.

# Set the output folder where the program will be created
set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})
set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/lib)

# The following folder will be included
include_directories("${PROJECT_SOURCE_DIR}")

# set up our target executable and specify its dependencies and includes
add_executable(seqwish
  src/utils.cpp
  src/tempfile.cpp
  src/main.cpp
  src/seqindex.cpp
  src/paf.cpp
  src/sxs.cpp
  src/cigar.cpp
  src/alignments.cpp
  src/pos.cpp
  src/match.cpp
  src/transclosure.cpp
  src/links.cpp
  src/compact.cpp
  src/dna.cpp
  src/gfa.cpp
  src/vgp.cpp
  src/exists.cpp
  src/time.cpp
  src/mmap.cpp
  src/version.cpp
  )

target_include_directories(seqwish PUBLIC
  # $ENV{GUIX_ENVIRONMENT}/include
  $ENV{GUIX_ENVIRONMENT}/include/atomic_queue # because the last dir is not included by the module
  "contrib/mmmulti/src"
  "contrib/mio/include"
  "contrib/atomicbitvector/include"
  "contrib/ips4o/include"
  "contrib/flat_hash_map"
  "contrib/paryfor"
  "${tayweeargs_INCLUDE}"
  "${gzipreader_INCLUDE}"
  # "${ips4o_INCLUDE}"
  # "${mmmulti_INCLUDE}"
  # "${iitii_INCLUDE}"
  # "${bbhash_INCLUDE}"
  # "${atomicbitvector_INCLUDE}"
  "${atomicqueue_INCLUDE}"
  # "${ska_INCLUDE}"
  # "${paryfor_INCLUDE}"
  # "${mio_INCLUDE}"
)

target_link_libraries(seqwish
  ${SDSLLITE_LINK_LIBRARIES}
  ${TBB_LINK_LIBRARIES}
  ${LIBDIVSUFSORT_LINK_LIBRARIES}
  "-latomic"
  Threads::Threads
  jemalloc
  z
)

if (BUILD_STATIC)
  #set(CMAKE_EXE_LINKER_FLAGS "-static")
  set(CMAKE_EXE_LINKER_FLAGS "-static -Wl,--whole-archive -lpthread -Wl,--no-whole-archive")
endif()

add_test(
  NAME seqwish-test
  COMMAND bash -c "make"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/test
)

# version stuff
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/include)
execute_process(COMMAND bash ${CMAKE_SOURCE_DIR}/scripts/generate_git_version.sh ${CMAKE_SOURCE_DIR}/include)

install(TARGETS seqwish DESTINATION bin)
