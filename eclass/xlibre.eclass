# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: xlibre.eclass
# @MAINTAINER:
# maintainer-needed@example.com
# @AUTHOR:
# Author: Tomáš Chvátal <scarabeus@gentoo.org>
# Author: Donnie Berkholz <dberkholz@gentoo.org>
# Author: Matt Turner <mattst88@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @PROVIDES: multilib-minimal
# @BLURB: Reduces code duplication in the modularized X11 ebuilds.
# @DESCRIPTION:
# This eclass makes trivial X ebuilds possible for apps, drivers,
# and more. Many things that would normally be done in various functions
# can be accessed by setting variables instead, such as patching,
# running eautoreconf, passing options to configure and installing docs.
# This eclass is based on xorg-3.eclass from gentoo upstream.
#
# All you need to do in a basic ebuild is inherit this eclass and set
# DESCRIPTION, KEYWORDS and RDEPEND/DEPEND. If your package is hosted
# with the other X packages, you don't need to set SRC_URI. Pretty much
# everything else should be automatic.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_XLIBRE_ECLASS} ]]; then
_XLIBRE_ECLASS=1

GIT_ECLASS=""
if [[ ${PV} == *9999* ]]; then
	GIT_ECLASS="git-r3"
	: "${XLIBRE_EAUTORECONF:="yes"}"
fi

# If we're a font package, but not the font.alias one
FONT_ECLASS=""
if [[ ${CATEGORY} = media-fonts ]]; then
	case ${PN} in
	font-alias|font-util)
		;;
	font*)
		# Activate font code in the rest of the eclass
		FONT="yes"
		FONT_ECLASS="font"
		;;
	esac
fi

# @ECLASS_VARIABLE: XLIBRE_MULTILIB
# @PRE_INHERIT
# @DESCRIPTION:
# If set to 'yes', the multilib support for package will be enabled. Set
# before inheriting this eclass.
: "${XLIBRE_MULTILIB:="no"}"

# we need to inherit autotools first to get the deps
AUTOTOOLS_AUTO_DEPEND=no
inherit autotools libtool multilib toolchain-funcs flag-o-matic \
	${FONT_ECLASS} ${GIT_ECLASS}
unset FONT_ECLASS GIT_ECLASS

[[ ${XLIBRE_MULTILIB} == yes ]] && inherit multilib-minimal

# @ECLASS_VARIABLE: XLIBRE_EAUTORECONF
# @PRE_INHERIT
# @DESCRIPTION:
# If set to 'yes' and configure.ac exists, eautoreconf will run. Set
# before inheriting this eclass.
: "${XLIBRE_EAUTORECONF:="no"}"

# @ECLASS_VARIABLE: XLIBRE_BASE_INDIVIDUAL_URI
# @PRE_INHERIT
# @DESCRIPTION:
# Set up SRC_URI for individual modular releases. If set to an empty
# string, no SRC_URI will be provided by the eclass.
: "${XLIBRE_BASE_INDIVIDUAL_URI="https://github.com/X11Libre"}"

# @ECLASS_VARIABLE: XLIBRE_MODULE
# @PRE_INHERIT
# @DESCRIPTION:
# The subdirectory to download source from. Possible settings are app,
# doc, data, util, driver, font, lib, proto, xserver. Set above the
# inherit to override the default autoconfigured module.
: "${XLIBRE_MODULE:="auto"}"
if [[ ${XLIBRE_MODULE} == auto ]]; then
	case "${CATEGORY}/${P}" in
		app-doc/*)               XLIBRE_MODULE=doc/     ;;
		media-fonts/*)           XLIBRE_MODULE=font/    ;;
		x11-apps/*|x11-wm/*)     XLIBRE_MODULE=app/     ;;
		x11-misc/*|x11-themes/*) XLIBRE_MODULE=util/    ;;
		x11-base/*)              XLIBRE_MODULE=         ;;
		x11-drivers/*)           XLIBRE_MODULE=         ;;
		x11-libs/*)              XLIBRE_MODULE=lib/     ;;
		*)                       XLIBRE_MODULE=         ;;
	esac
fi

# @ECLASS_VARIABLE: XLIBRE_PACKAGE_NAME
# @PRE_INHERIT
# @DESCRIPTION:
# For git checkout the git repository might differ from package name.
# This variable can be used for proper directory specification
: "${XLIBRE_PACKAGE_NAME:=${PN}}"
case "${CATEGORY}/${P}" in
	x11-base/xlibre-server-*) 	XLIBRE_PACKAGE_NAME=xserver ;;
esac

HOMEPAGE="https://github.com/X11Libre/${XLIBRE_MODULE}${XLIBRE_PACKAGE_NAME}"

# @ECLASS_VARIABLE: XLIBRE_TARBALL_SUFFIX
# @PRE_INHERIT
# @DESCRIPTION:
# Most Xlibre projects provide tarballs as tar.gz. This eclass defaults to gz.
: "${XLIBRE_TARBALL_SUFFIX:="gz"}"

if [[ ${PV} == *9999* ]]; then
	: "${EGIT_REPO_URI:="https://github.com/X11Libre/${XLIBRE_MODULE}${XLIBRE_PACKAGE_NAME}.git"}"
elif [[ -n ${XLIBRE_BASE_INDIVIDUAL_URI} ]]; then
	SRC_URI="${XLIBRE_BASE_INDIVIDUAL_URI}/${XLIBRE_PACKAGE_NAME}/archive/refs/tags/xlibre-${XLIBRE_PACKAGE_NAME}-${PV}.tar.${XLIBRE_TARBALL_SUFFIX}"
	S="${WORKDIR}/${XLIBRE_PACKAGE_NAME}-xlibre-${XLIBRE_PACKAGE_NAME}-${PV}"
fi

: "${SLOT:=0}"

# Set the license for the package. This can be overridden by setting
# LICENSE after the inherit. Nearly all FreeDesktop-hosted X packages
# are under the MIT license. (This is what Red Hat does in their rpms)
: "${LICENSE:=MIT}"

# Set up autotools shared dependencies
# Remember that all versions here MUST be stable
EAUTORECONF_DEPEND+=" ${AUTOTOOLS_DEPEND}"
if [[ ${PN} != util-macros ]] ; then
	EAUTORECONF_DEPEND+=" >=x11-misc/util-macros-1.18"
	# Required even by xlibre-server
	[[ ${PN} == "font-util" ]] || EAUTORECONF_DEPEND+=" >=media-fonts/font-util-1.2.0"
fi
if [[ ${XLIBRE_EAUTORECONF} == no ]] ; then
	BDEPEND+=" ${LIBTOOL_DEPEND}"
else
	BDEPEND+=" ${EAUTORECONF_DEPEND}"
fi
unset EAUTORECONF_DEPEND

# @ECLASS_VARIABLE: FONT_DIR
# @PRE_INHERIT
# @DESCRIPTION:
# If you're creating a font package and the suffix of PN is not equal to
# the subdirectory of /usr/share/fonts/ it should install into, set
# FONT_DIR to that directory or directories.  Set before inheriting this
# eclass.

if [[ ${FONT} == yes ]]; then
	RDEPEND+=" media-fonts/encodings
		>=x11-apps/mkfontscale-1.2.0"
	PDEPEND+=" media-fonts/font-alias"
	DEPEND+=" >=media-fonts/font-util-1.2.0
		>=x11-apps/mkfontscale-1.2.0"
	BDEPEND+=" x11-apps/bdftopcf"

	[[ -z ${FONT_DIR} ]] && FONT_DIR=${PN##*-}

	# Fix case of font directories
	FONT_DIR=${FONT_DIR/ttf/TTF}
	FONT_DIR=${FONT_DIR/otf/OTF}
	FONT_DIR=${FONT_DIR/type1/Type1}
	FONT_DIR=${FONT_DIR/speedo/Speedo}
fi
BDEPEND+=" virtual/pkgconfig"

# @ECLASS_VARIABLE: XLIBRE_DRI
# @PRE_INHERIT
# @DESCRIPTION:
# Possible values are "always" or the value of the useflag DRI capabilities
# are required for. Default value is "no"
#
# Eg. XLIBRE_DRI="opengl" will pull all dri dependent deps for opengl useflag
: "${XLIBRE_DRI:="no"}"

DRI_COMMON_DEPEND="
	x11-base/xlibre-server[-minimal]
	x11-libs/libdrm
"
case ${XLIBRE_DRI} in
	no)
		;;
	always)
		COMMON_DEPEND+=" ${DRI_COMMON_DEPEND}"
		;;
	*)
		COMMON_DEPEND+=" ${XLIBRE_DRI}? ( ${DRI_COMMON_DEPEND} )"
		IUSE+=" ${XLIBRE_DRI}"
		;;
esac
unset DRI_COMMON_DEPEND

if [[ ${PN} == xf86-video-* || ${PN} == xf86-input-* ]]; then
	DEPEND+="  x11-base/xorg-proto"
	RDEPEND+=" x11-base/xlibre-server:="
	COMMON_DEPEND+=" >=x11-base/xlibre-server-1.20[xorg]"
	[[ ${PN} == xf86-video-* ]] && COMMON_DEPEND+=" >=x11-libs/libpciaccess-0.14"
fi


# @ECLASS_VARIABLE: XLIBRE_DOC
# @PRE_INHERIT
# @DESCRIPTION:
# Possible values are "always" or the value of the useflag doc packages
# are required for. Default value is "no"
#
# Eg. XLIBRE_DOC="manual" will pull all doc dependent deps for manual useflag
: "${XLIBRE_DOC:="no"}"

DOC_DEPEND="
	doc? (
		|| ( app-text/asciidoc dev-ruby/asciidoctor )
		app-text/xmlto
		app-text/docbook-xml-dtd:4.1.2
		app-text/docbook-xml-dtd:4.2
		app-text/docbook-xml-dtd:4.3
	)
"
case ${XLIBRE_DOC} in
	no)
		;;
	always)
		BDEPEND+=" ${DOC_DEPEND}"
		;;
	*)
		BDEPEND+=" ${XLIBRE_DOC}? ( ${DOC_DEPEND} )"
		IUSE+=" ${XLIBRE_DOC}"
		;;
esac
unset DOC_DEPEND

DEPEND+=" ${COMMON_DEPEND}"
RDEPEND+=" ${COMMON_DEPEND}"
unset COMMON_DEPEND

debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: DEPEND=${DEPEND}"
debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: RDEPEND=${RDEPEND}"
debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: PDEPEND=${PDEPEND}"
debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: BDEPEND=${BDEPEND}"

# @FUNCTION: xlibre_pkg_setup
# @DESCRIPTION:
# Setup prefix compat
xlibre_pkg_setup() {
	debug-print-function ${FUNCNAME} "$@"

	[[ ${FONT} == yes ]] && font_pkg_setup "$@"
}

# @FUNCTION: xlibre_src_unpack
# @DESCRIPTION:
# Simply unpack source code.
xlibre_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
	else
		unpack ${A}
	fi

	[[ -n ${FONT} ]] && einfo "Detected font directory: ${FONT_DIR}"
}

# @FUNCTION: xlibre_reconf_source
# @DESCRIPTION:
# Run eautoreconf if necessary, and run elibtoolize.
xlibre_reconf_source() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${XLIBRE_EAUTORECONF} != no ]] ; then
		eautoreconf
	else
		elibtoolize --patch-only
	fi
}

# @FUNCTION: xlibre_src_prepare
# @DESCRIPTION:
# Prepare a package after unpacking, performing all X-related tasks.
xlibre_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	default
	xlibre_reconf_source
}

# @FUNCTION: xlibre_font_configure
# @DESCRIPTION:
# If a font package, perform any necessary configuration steps
xlibre_font_configure() {
	debug-print-function ${FUNCNAME} "$@"

	# Pass --with-fontrootdir to override pkgconf SYSROOT behavior.
	# https://bugs.gentoo.org/815520
	if grep -q -s "with-fontrootdir" "${ECONF_SOURCE:-.}"/configure; then
		FONT_OPTIONS+=( --with-fontrootdir="${EPREFIX}"/usr/share/fonts )
	fi

	if has nls ${IUSE//+} && ! use nls; then
		if ! grep -q -s "disable-all-encodings" ${ECONF_SOURCE:-.}/configure; then
			die "--disable-all-encodings option not available in configure"
		fi
		FONT_OPTIONS+=( --disable-all-encodings --enable-iso8859-1 )
	fi
}

# @FUNCTION: xlibre_flags_setup
# @DESCRIPTION:
# Set up CFLAGS for a debug build
xlibre_flags_setup() {
	debug-print-function ${FUNCNAME} "$@"

	# Hardened flags break module autoloading et al (also fixes #778494)
	if [[ ${PN} == xlibre-server || ${PN} == xf86-video-* || ${PN} == xf86-input-* ]]; then
		filter-flags -fno-plt
		append-ldflags -Wl,-z,lazy
	fi

	# Quite few libraries fail on runtime without these:
	if has static-libs ${IUSE//+}; then
		filter-flags -Wl,-Bdirect
		filter-ldflags -Bdirect
		filter-ldflags -Wl,-Bdirect
	fi
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf "${econfargs[@]}"
}

# @VARIABLE: XLIBRE_CONFIGURE_OPTIONS
# @DESCRIPTION:
# Array of an additional options to pass to configure.
# @DEFAULT_UNSET

# @FUNCTION: xlibre_src_configure
# @DESCRIPTION:
# Perform any necessary pre-configuration steps, then run configure
xlibre_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	xlibre_flags_setup

	local xorgconfadd=("${XLIBRE_CONFIGURE_OPTIONS[@]}")

	local FONT_OPTIONS=()
	[[ -n "${FONT}" ]] && xlibre_font_configure

	# Check if package supports disabling of dep tracking
	# Fixes warnings like:
	#    WARNING: unrecognized options: --disable-dependency-tracking
	if grep -q -s "disable-dependency-tracking" ${ECONF_SOURCE:-.}/configure; then
		local dep_track="--disable-dependency-tracking"
	fi

	# Check if package supports disabling of selective -Werror=...
	if grep -q -s "disable-selective-werror" ${ECONF_SOURCE:-.}/configure; then
		local selective_werror="--disable-selective-werror"
	fi

	# Check if package supports disabling of static libraries
	if grep -q -s "able-static" ${ECONF_SOURCE:-.}/configure; then
		local no_static="--disable-static"
	fi

	local econfargs=(
		${dep_track}
		${selective_werror}
		${no_static}
		"${FONT_OPTIONS[@]}"
		"${xorgconfadd[@]}"
	)

	# Handle static-libs found in IUSE, disable them by default
	if in_iuse static-libs; then
		econfargs+=(
			--enable-shared
			$(use_enable static-libs static)
		)
	fi

	if [[ ${XLIBRE_MULTILIB} == yes ]]; then
		multilib-minimal_src_configure "$@"
	else
		econf "${econfargs[@]}" "$@"
	fi
}

multilib_src_compile() {
	emake "$@"
}

# @FUNCTION: xlibre_src_compile
# @DESCRIPTION:
# Compile a package, performing all X-related tasks.
xlibre_src_compile() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${XLIBRE_MULTILIB} == yes ]]; then
		multilib-minimal_src_compile "$@"
	else
		emake "$@"
	fi
}

multilib_src_install() {
	emake DESTDIR="${D}" "${install_args[@]}" "$@" install
}

# @FUNCTION: xlibre_src_install
# @DESCRIPTION:
# Install a built package to ${D}, performing any necessary steps.
xlibre_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	local install_args=( docdir="${EPREFIX}/usr/share/doc/${PF}" )

	if [[ ${XLIBRE_MULTILIB} == yes ]]; then
		multilib-minimal_src_install "$@"
	else
		emake DESTDIR="${D}" "${install_args[@]}" "$@" install
		einstalldocs
	fi

	# Many X11 libraries unconditionally install developer documentation
	if [[ -d "${D}"/usr/share/man/man3 ]]; then
		! in_iuse doc && eqawarn "QA Notice: ebuild should set XLIBRE_DOC=doc since package installs library documentation"
	fi

	if in_iuse doc && ! use doc; then
		rm -rf "${D}"/usr/share/man/man3
		rmdir "${D}"/usr{/share{/man,},} 2>/dev/null
	fi

	# Don't install libtool archives (even for modules)
	find "${D}" -type f -name '*.la' -delete || die

	if [[ -n ${FONT} ]] ; then
		if [[ -n ${FONT_OPENTYPE_COMPAT} ]] && in_iuse opentype-compat && use opentype-compat ; then
			font_wrap_opentype_compat
		fi

		remove_font_metadata
	fi
}

# @FUNCTION: xlibre_pkg_postinst
# @DESCRIPTION:
# Run X-specific post-installation tasks on the live filesystem. The
# only task right now is some setup for font packages.
xlibre_pkg_postinst() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ -n ${FONT} ]]; then
		create_fonts_scale
		create_fonts_dir
		font_pkg_postinst "$@"

		ewarn "Installed fonts changed. Run 'xset fp rehash' if you are using non-fontconfig applications."
	fi
}

# @FUNCTION: xlibre_pkg_postrm
# @DESCRIPTION:
# Run X-specific post-removal tasks on the live filesystem. The only
# task right now is some cleanup for font packages.
xlibre_pkg_postrm() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ -n ${FONT} ]]; then
		# if we're doing an upgrade, postinst will do
		if [[ -z ${REPLACED_BY_VERSION} ]]; then
			create_fonts_scale
			create_fonts_dir
			font_pkg_postrm "$@"
		fi
	fi
}

# @FUNCTION: remove_font_metadata
# @DESCRIPTION:
# Don't let the package install generated font files that may overlap
# with other packages. Instead, they're generated in pkg_postinst().
remove_font_metadata() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${FONT_DIR} != Speedo && ${FONT_DIR} != CID ]]; then
		einfo "Removing font metadata"
		rm -rf "${ED}"/usr/share/fonts/${FONT_DIR}/fonts.{scale,dir,cache-1}
	fi
}

# @FUNCTION: create_fonts_scale
# @DESCRIPTION:
# Create fonts.scale file, used by the old server-side fonts subsystem.
create_fonts_scale() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${FONT_DIR} != Speedo && ${FONT_DIR} != CID ]]; then
		ebegin "Generating fonts.scale"
			mkfontscale \
				-a "${EROOT}/usr/share/fonts/encodings/encodings.dir" \
				-- "${EROOT}/usr/share/fonts/${FONT_DIR}"
		eend $?
	fi
}

# @FUNCTION: create_fonts_dir
# @DESCRIPTION:
# Create fonts.dir file, used by the old server-side fonts subsystem.
create_fonts_dir() {
	debug-print-function ${FUNCNAME} "$@"

	ebegin "Generating fonts.dir"
			mkfontdir \
				-e "${EROOT}"/usr/share/fonts/encodings \
				-e "${EROOT}"/usr/share/fonts/encodings/large \
				-- "${EROOT}/usr/share/fonts/${FONT_DIR}"
	eend $?
}

fi

EXPORT_FUNCTIONS src_prepare src_configure src_unpack src_compile src_install pkg_postinst pkg_postrm
