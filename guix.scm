;; To use this file to build a version of seqwish using git HEAD:
;;
;;   guix build -f guix.scm                  # default build
;;   guix build -L . seqwish-gcc-git          # standard gcc build
;;   guix build -L . seqwish-gcc-debug-git    # gcc build with debug and ASAN
;;   guix build -L . seqwish-gcc-profile-git  # run the profiler!
;;   guix build -L . seqwish-gcc-static-git --without-tests=seqwish-gcc-static-git # gcc static build (default)
;;   guix build -L . seqwish-clang-git        # clang build
;;
;; Note that for above build commands testing should be disabled with --without-tests=target.
;;
;; To get a development container using a recent guix (see `guix pull`)
;;
;;   guix shell --share=$HOME/.cargo -C -D -F -v 3 -f guix.scm            # default build
;;   guix shell --share=$HOME/.cargo -L . -C -D -F seqwish-gcc-git         # preferred development container
;;   guix shell --share=$HOME/.cargo -L . -C -D -F seqwish-gcc-static-git
;;   guix shell --share=$HOME/.cargo -L . -C -D -F seqwish-clang-git
;;
;; and inside the container
;;
;;   mkdir build
;;   cd build
;;   rm -rf ../build/*
;;   cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_OPTIMIZED=1 ..
;;   make -j 12 VERBOSE=1
;;   ctest . --verbose
;;
;; alternative builds
;;
;;   cmake -DCMAKE_BUILD_TYPE=Debug ..           # for development (use seqwish-gcc-git)
;;   cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..  # for distros including Debian (use seqwish-gcc-git)
;;   cmake -DBUILD_STATIC=1 ..                   # static binary (use seqwish-gcc-static-git)
;;
;; For tests to work build wgatools in the next directory and add --expose=../wgatools=/wgatools to the shell options above.
;; Inside the container you should be able to run:
;;
;; env LD_LIBRARY_PATH=$GUIX_PROFILE/lib /wgatools/target/release/wgatools
;;
;; list packages
;;
;;   guix package -L . -A|grep wfm
;;
;; Installing guix (note that Debian comes with guix). Once installed update as a normal user with:
;;
;;   mkdir ~/opt
;;   guix pull -p ~/opt/guix # update guix takes a while - don't do this often!
;;
;; Use the update guix to build seqwish:
;;
;;   ~/opt/guix/bin/guix build -f guix.scm
;;
;; Or get a shell
;;
;;   ~/opt/guix/gin/guix build -f guix.scm
;;
;; If things do not work you may also have to update the guix-daemon in systemd. Guix mostly downloads binary
;; substitutes. If it wants to build a lot of software you probably have substitutes misconfigured.

;; by Pjotr Prins & Andrea Guarracino (c) 2023-2025

(define-module (guix)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bioinformatics)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages crates-check) ; for cargo
  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages crates-web)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages datastructures)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages jemalloc)
  #:use-module (gnu packages linux) ; for util-linux column
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages rust-apps) ; for cargo
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  )


(define %source-dir (dirname (current-filename)))

(define %version
  (read-string (open-pipe "git describe --always --tags --long|tr -d $'\n'" OPEN_READ)))

(define-public seqwish-base-git
  (package
    (name "seqwish-base-git")
    (version %version)
    (source (local-file %source-dir #:recursive? #t))
    (build-system cmake-build-system)
    (properties '((tunable? . #t)))
    (inputs (list
             ;; bash bedtools util-linux samtools ; for testing
             atomic-queue
             sdsl-lite
             libdivsufsort
             jemalloc
             gnu-make
             pkg-config
             zlib))
    (arguments
     `(#:tests? #f ;; running tests as profiler
       #:configure-flags
         ,#~(list
             "-DCMAKE_BUILD_TYPE=Generic")
       #:phases
         ,#~(modify-phases %standard-phases
            (replace 'check
                     (lambda* (#:key tests? #:allow-other-keys)
                              ;; Add seqwish to the PATH for the tests.
                              (setenv "PATH" (string-append (getcwd) ":" (getenv "PATH")))
                              (when tests?
                                (with-directory-excursion "../source/test"
                                                          (invoke "make"))))))))
    (synopsis "unbiased graph inducer")
    (description
"seqwish implements a lossless conversion from pairwise alignments between
sequences to a variation graph encoding the sequences and their alignments.  As
input we typically take all-versus-all alignments, but the exact structure of
the alignment set may be defined in an application specific way.  This algorithm
uses a series of disk-backed sorts and passes over the alignment and sequence
inputs to allow the graph to be constructed from very large inputs that are
commonly encountered when working with large numbers of noisy input sequences.")
    (home-page "https://github.com/ekg/seqwish")
    (license license:expat)
))

(define-public seqwish-gcc-git
  "Default build with gcc - as is used in distros"
  (package
    (inherit seqwish-base-git)
    (name "seqwish-gcc-git")
    (inputs
     (modify-inputs (package-inputs seqwish-base-git)
         (append gcc)))))

(define-public seqwish-gcc-debug-git
  "Build with debug options"
  (package
    (inherit seqwish-gcc-git)
    (name "seqwish-gcc-debug-git")
    (arguments
     `(;; #:tests? #f ;; skip tests, this is mostly to run a shell
       #:configure-flags
       ,#~(list
           "-DASAN=ON"
           "-DDISABLE_LTO=ON"
           "-DCMAKE_BUILD_TYPE=Debug"))) ; force cmake static build and do not rewrite RPATH
    (inputs
     (modify-inputs (package-inputs seqwish-gcc-git)
                    (append gperftools git)
                    ))
    (propagated-inputs (list
                        coreutils
                        util-linux
                        grep
                        ))
    (arguments
     `(#:phases (modify-phases %standard-phases
                               (delete 'configure)
                               (delete 'build)
                               (delete 'package)
                               (delete 'check)
                               (delete 'install))))))

(define-public seqwish-clang-git
  "Clang+LLVM build"
  (package
    (inherit seqwish-base-git)
    (name "seqwish-clang-git")
    (inputs
     (modify-inputs (package-inputs seqwish-base-git)
         (append clang-toolchain-18
                 lld
                 libomp)))))

(define-public seqwish-gcc-profile-git
  "Build seqwish optimally and automatically run profiler on all tests"
  (package
    (inherit seqwish-gcc-git)
    (name "seqwish-gcc-profile-git")
    (arguments
     `(#:tests? #f ;; running tests as profiler
       #:configure-flags
         ,#~(list
             "-DCMAKE_BUILD_TYPE=Generic"
             ;; "-DBUILD_OPTIMIZED=ON" -- use --tune switch
             "-DPROFILER=ON")
       #:phases
         ,#~(modify-phases %standard-phases
            (add-after 'install 'run-profiler-on-all2all
                       (lambda* (#:key outputs #:allow-other-keys)
                         (invoke "ctest" "--verbose" "-R" "all2all") ; only run all2all test
                         (invoke "ls" "-l" "bin/seqwish")
                         (invoke "ls" "-l")
                         (invoke "pprof" "--text" "bin/seqwish" "seqwish.prof")
                         (mkdir-p (string-append #$output:doc "/share")))))))
    (inputs
     (modify-inputs (package-inputs seqwish-gcc-git)
                    (append gperftools
                            coreutils ;; for ls
                 )))))

;; ==== The following is for static binary builds using gcc - used mostly for deployment ===

;; Guix does not come with a static version of libdeflate
(define-public libdeflate-static
  (package
    (inherit libdeflate)
    (name "libdeflate-static")
    (version "1.19")
    (arguments
     (list #:configure-flags
           #~(list "-DLIBDEFLATE_BUILD_STATIC_LIB=YES"
                   "-DLIBDEFLATE_BUILD_TESTS=YES")))))

;; A minimal static version of htslib that does not depend on curl and openssl. This
;; reduces the number of higher order dependencies in static linking.
(define-public htslib-static
  (package
    (inherit htslib)
    (name "htslib-static")
    (version "1.19")
    (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/samtools/htslib/releases/download/"
                  version "/htslib-" version ".tar.bz2"))
            (sha256
             (base32
              "0dh79lwpspwwfbkmllrrhbk8nkvlfc5b5ib4d0xg5ld79w6c8lc7"))))
    (arguments
     (substitute-keyword-arguments (package-arguments htslib)
       ((#:configure-flags flags ''())
        ''())))
    (inputs
     (list bzip2 xz))))

(define %source-dir (dirname (current-filename)))

(define %git-commit
    (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ)))

(define-public seqwish-gcc-static-git
  "Optimized for latest AMD architecture build and static deployment.
These binaries can be copied to HPC."
  (package
    (inherit seqwish-base-git)
    (name "seqwish-gcc-static-git")
    (arguments
     `(#:tests? #f  ;; no Rust tools
       #:configure-flags
       ,#~(list
           "-DBUILD_STATIC=ON"
           ;; "-DBUILD_OPTIMIZED=ON"    ;; we don't use the standard cmake optimizations
           "-DCMAKE_BUILD_TYPE=Generic" ;; to optimize use --tune=march-type (e.g. --tune=native)
           "-DCMAKE_INSTALL_RPATH=")))   ; force cmake static build and do not rewrite RPATH
    (inputs
     (modify-inputs (package-inputs seqwish-gcc-git)
                    (delete pafcheck-github)
                    (prepend
                     `(,bzip2 "static")
                     `(,zlib "static")
                     `(,gsl "static")
                     `(,xz "static")
                     libdeflate-static
                     htslib-static)))))

seqwish-gcc-static-git ;; default optimized static deployment build
