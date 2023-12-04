(use-modules (guix packages)
	     (gnu packages bash)
	     (gnu packages base)
	     (gnu packages guile)
	     (gnu packages guile-xyz)
	     (gnu packages fontutils)
	     (gnu packages gnome)
	     (gnu packages gl)
	     (gnu packages xorg)
	     (gnu packages xdisorg)
	     (gnu packages vulkan)
	     (gnu packages freedesktop)
	     (gnu packages cups)
	     (gnu packages video)
	     (gnu packages fribidi)
	     (gnu packages gstreamer)
	     (gnu packages iso-codes)
	     (gnu packages image)
	     (gnu packages docbook)
	     (gnu packages gettext)
	     (gnu packages xml)
	     (gnu packages python-xyz)
	     (gnu packages python-build)
	     (gnu packages web)
	     (guix download)	     	     
	     (guix utils)
	     (guix build-system)
	     (guix build-system meson)
	     (gnu packages pcre)
	     (gnu packages base)
	     (gnu packages gtk)
	     (gnu packages glib)
	     (gnu packages package-management)                 
	     (gnu packages pkg-config)                         
	     (gnu packages python)                             
	     (gnu packages version-control)
	     (guix build-system gnu)                           	     
	     (guix build-system cmake)                         
	     (guix build-system meson)                         
	     (guix build-system perl)                          
	     (guix build-system python)                        
	     (guix download)                                   
	     (guix git-download)                               
	     ((guix licenses) #:prefix license:)               
	     (guix packages)                                   
	     (guix utils)                                      
	     (guix gexp)                                       
	     (srfi srfi-26)                                    
	     ((srfi srfi-1) #:hide (zip)))


(define-public glib-edge
  (package
   (inherit glib)
   (name "glib-edge")
   (version "2.78.1")
   (source (origin
	    (method url-fetch)
	    (uri "https://download.gnome.org/sources/glib/2.78/glib-2.78.1.tar.xz")
	    (sha256 (base64 "kVvD0PhQfWUOrTgy4vj7Zw/OWarE13VKfatvHm/teLI="))))
   (propagated-inputs
    (modify-inputs (package-propagated-inputs glib)
		   (replace "pcre" pcre2)))
   (build-system meson-build-system)
   (arguments
    (list
     #:tests? #f
     #:disallowed-references
     (cons tzdata-for-tests
           ;; Verify glib-mkenums, gtester, ... use the cross-compiled
           ;; python.
           (if (%current-target-system)
               (map (cut gexp-input <> #:native? #t)
                    `(,(this-package-native-input "python")
                      ,(this-package-native-input "python-wrapper")))
               '()))
     #:configure-flags #~(list "--default-library=both"
                               "-Dman=false"
                               "-Dselinux=disabled"
                               (string-append "--bindir="
                                              #$output:bin "/bin"))
     #:phases
     #~(modify-phases %standard-phases
		      ;; Needed to pass the test phase on slower ARM and i686 machines.
		      (add-after 'unpack 'increase-test-timeout
				 (lambda _
				   (substitute* "meson.build"
						(("(test_timeout.*) = ([[:digit:]]+)" all first second)
						 (string-append first " = " second "0")))))
		      (add-after 'unpack 'disable-failing-tests
				 (lambda _
				   (substitute* "gio/tests/meson.build"
						((".*'testfilemonitor'.*") ;marked as flaky
						 ""))
				   (with-directory-excursion "glib/tests"
							     (substitute* '("unix.c" "utils.c")
									  (("[ \t]*g_test_add_func.*;") "")))
				   (with-directory-excursion "gio/tests"
							     (substitute* '("contenttype.c" "gdbus-address-get-session.c"
									    "gdbus-peer.c" "appinfo.c" "desktop-app-info.c")
									  (("[ \t]*g_test_add_func.*;") "")))

				   #$@(if (target-x86-32?)
					  ;; Comment out parts of timer.c that fail on i686 due to
					  ;; excess precision when building with GCC 10:
					  ;; <https://gitlab.gnome.org/GNOME/glib/-/issues/820>.
					  '((substitute* "glib/tests/timer.c"
							 (("^  g_assert_cmpuint \\(micros.*" all)
							  (string-append "//" all "\n"))
							 (("^  g_assert_cmpfloat \\(elapsed, ==.*" all)
							  (string-append "//" all "\n"))))
					  '())))
		      ;; Python references are not being patched in patch-phase of build,
		      ;; despite using python-wrapper as input. So we patch them manually.
		      ;;
		      ;; These python scripts are both used during build and installed,
		      ;; so at first, use a python from 'native-inputs', not 'inputs'. When
		      ;; cross-compiling, the 'patch-shebangs' phase will replace
		      ;; the native python with a python from 'inputs'.
		      (add-after 'unpack 'patch-python-references
				 (lambda* (#:key native-inputs inputs #:allow-other-keys)
				   (substitute* '("gio/gdbus-2.0/codegen/gdbus-codegen.in"
						  "glib/gtester-report.in"
						  "gobject/glib-genmarshal.in"
						  "gobject/glib-mkenums.in")
						(("@PYTHON@")
						 (search-input-file (or native-inputs inputs)
								    (string-append
								     "/bin/python"
								     #$(version-major+minor
									(package-version python))))))))
		      (add-before 'check 'pre-check
				  (lambda* (#:key native-inputs inputs outputs #:allow-other-keys)
				    ;; For tests/gdatetime.c.
				    (setenv "TZDIR"
					    (search-input-directory (or native-inputs inputs)
								    "share/zoneinfo"))
				    ;; Some tests want write access there.
				    (setenv "HOME" (getcwd))
				    (setenv "XDG_CACHE_HOME" (getcwd))))
		      (add-after 'install 'move-static-libraries
				 (lambda _
				   (mkdir-p (string-append #$output:static "/lib"))
				   (for-each (lambda (a)
					       (rename-file a (string-append #$output:static "/lib/"
									     (basename a))))
					     (find-files #$output "\\.a$"))))
		      (add-after 'install 'patch-pkg-config-files
				 (lambda* (#:key outputs #:allow-other-keys)
				   ;; Do not refer to "bindir", which points to "${prefix}/bin".
				   ;; We don't patch "bindir" to point to "$bin/bin", because that
				   ;; would create a reference cycle between the "out" and "bin"
				   ;; outputs.
				   (substitute*
				    (list (search-input-file outputs "lib/pkgconfig/gio-2.0.pc")
					  (search-input-file outputs "lib/pkgconfig/glib-2.0.pc"))
				    (("^bindir=.*")
				     "")
				    (("=\\$\\{bindir\\}/")
				     "=")))))))))
(define-public gobject-introspection-edge
  (package
   (inherit gobject-introspection)
   (name    "gobject-introspection-edge")
   (version "1.78.1")
   (source (origin
	    (method url-fetch)
	    (uri "https://download.gnome.org/sources/gobject-introspection/1.78/gobject-introspection-1.78.1.tar.xz")
	    (sha256 (base64 "vXur2Zr3JY52gZ5Fukprw5lgj+di2D/ePKwDPFCEG7Q="))))
   (native-inputs
    (modify-inputs (package-native-inputs gobject-introspection)
		   (replace "glib" `(,glib-edge "bin"))))
   (propagated-inputs
    (modify-inputs (package-propagated-inputs gobject-introspection)
		   (replace "glib" glib-edge)))
   ))
(define-public mygtk
  (package
   (name "my-gtk")
   (version "4.12.4")
   (source (origin
	    (method url-fetch)
	    (uri "https://download.gnome.org/sources/gtk/4.12/gtk-4.12.4.tar.xz")
	    (sha256 (base64 "umfGSY5Vmfko7a+54IoyCt+qUKsvDab8arIlL8LVdSA="))))
   (build-system meson-build-system)
   (outputs '("out" "bin"))
   (arguments
    (list
     #:modules '((guix build utils)
                 (guix build meson-build-system)
                 ((guix build glib-or-gtk-build-system) #:prefix glib-or-gtk:))
     #:configure-flags
     #~(list
	"-Dintrospection=enabled"
        "-Dbroadway-backend=true"
        "-Dcloudproviders=enabled"
        "-Dtracker=enabled"
        "-Dcolord=enabled"
	"-Dgtk_doc=false"
        "-Dman-pages=false")
     #:tests? #f
     #:phases
     #~(modify-phases %standard-phases
          (add-after 'unpack 'generate-gdk-pixbuf-loaders-cache-file
            (assoc-ref glib-or-gtk:%standard-phases
                       'generate-gdk-pixbuf-loaders-cache-file))
          (add-after 'unpack 'patch-rst2man
            (lambda _
              (substitute* "docs/reference/gtk/meson.build"
                (("find_program\\('rst2man'")
                 "find_program('rst2man.py'"))))
          (add-after 'unpack 'patch
            (lambda* (#:key inputs native-inputs outputs #:allow-other-keys)
              ;; Correct DTD resources of docbook.
              (substitute* (find-files "docs" "\\.xml$")
                (("http://www.oasis-open.org/docbook/xml/4.3/")
                 (string-append #$(this-package-native-input "docbook-xml")
                                "/xml/dtd/docbook/")))
              ;; Disable building of icon cache.
              (substitute* "meson.build"
                (("gtk_update_icon_cache: true")
                 "gtk_update_icon_cache: false"))
              ;; Disable failing tests.
              (substitute* (find-files "testsuite" "meson.build")
                (("[ \t]*'empty-text.node',") "")
                (("[ \t]*'testswitch.node',") "")
                (("[ \t]*'widgetfactory.node',") "")
                ;; The unaligned-offscreen test fails for unknown reasons, also
                ;; on different distributions (see:
                ;; https://gitlab.gnome.org/GNOME/gtk/-/issues/4889).
                (("  'unaligned-offscreen',") ""))
              (substitute* "testsuite/reftests/meson.build"
                (("[ \t]*'label-wrap-justify.ui',") "")
                ;; The inscription-markup.ui fails due to /etc/machine-id
                ;; related warnings (see:
                ;; https://gitlab.gnome.org/GNOME/gtk/-/issues/5169).
                (("[ \t]*'inscription-markup.ui',") ""))))
          (add-before 'build 'set-cache
            (lambda _
              (setenv "XDG_CACHE_HOME" (getcwd))))
          (add-before 'check 'pre-check
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Tests require a running X server.
              (system "Xvfb :1 +extension GLX &")
              (setenv "DISPLAY" ":1")
              ;; Tests write to $HOME.
              (setenv "HOME" (getcwd))
              ;; Tests look for those variables.
              (setenv "XDG_RUNTIME_DIR" (getcwd))
              ;; For missing '/etc/machine-id'.
              (setenv "DBUS_FATAL_WARNINGS" "0")
              ;; Required for the calendar test.
              (setenv "TZDIR" (search-input-directory inputs
                                                      "share/zoneinfo"))))
          (add-after 'install 'move-files
            (lambda _
              (for-each mkdir-p
                        (list
                         (string-append #$output:bin "/share/applications")
                         (string-append #$output:bin "/share/icons")
                         (string-append #$output:bin "/share/metainfo")))
              ;; Move programs and related files to output 'bin'.
              (for-each (lambda (dir)
                          (rename-file
                           (string-append #$output dir)
                           (string-append #$output:bin dir)))
                        (list
                         "/share/applications"
                         "/share/icons"
                         "/share/metainfo"))
              ;; Move HTML documentation to output 'doc'.
	      )))))
   (native-inputs
    (list docbook-xml-4.3
	  git
          docbook-xsl
          gettext-minimal
          `(,glib-edge "bin")
          gobject-introspection-edge        ;for building introspection data
          graphene
          gtk-doc                      ;for building documentation
          intltool
          libxslt                      ;for building man-pages
          pkg-config
          python-pygobject
          ;; These python modules are required for building documentation.
          python-docutils
          python-jinja2
          python-markdown
          python-markupsafe
          python-pygments
          python-toml
          python-typogrify
          sassc                        ;for building themes
          tzdata-for-tests
          vala
          xorg-server-for-tests))
   (inputs
    (list colord
          cups 
          ffmpeg
          fribidi
          gstreamer
          gst-plugins-bad
          gst-plugins-base
          harfbuzz
          iso-codes
          json-glib
          libcloudproviders
          libgudev
          libjpeg-turbo
          libpng
          libtiff
          python
          rest
          tracker))
   (propagated-inputs
    (list cairo
           fontconfig
           (librsvg-for-system)
           glib-edge
           graphene
           libepoxy
           libx11                       ;for x11 display-backend
           libxcomposite
           libxcursor
           libxdamage
           libxext
           libxfixes
           libxi
           libxinerama                  ;for xinerama support
           libxkbcommon
           libxrandr
           libxrender
           pango
           vulkan-headers
           vulkan-loader                ;for vulkan graphics API support
           wayland                      ;for wayland display-backend
           wayland-protocols))
   (native-search-paths
     (list
      (search-path-specification
       (variable "GUIX_GTK4_PATH")
       (files '("lib/gtk-4.0")))))
   (search-paths native-search-paths)
    (home-page "https://www.gtk.org/")
    (synopsis "Cross-platform widget toolkit")
    (description "GTK is a multi-platform toolkit for creating graphical user
interfaces.  Offering a complete set of widgets, GTK is suitable for projects
ranging from small one-off tools to complete application suites.")
    (license license:lgpl2.1+))
  )

(packages->manifest `(,glib-edge ,gobject-introspection-edge ,mygtk ,coreutils ,bash ,guile-3.0 ,guile-gi ,grep ,binutils))
