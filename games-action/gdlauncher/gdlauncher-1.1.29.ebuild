# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="GDLauncher is a simple, yet powerful Minecraft custom launcher with a strong focus on the user experience."
HOMEPAGE="https://gdlauncher.com"
SRC_URI="https://github.com/gorilla-devs/GDLauncher/archive/refs/tags/v${PV}.tar.gz"

S="${WORKDIR}/GDLauncher-${PV}"

LICENSE="GPL3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=app-arch/p7zip-16.02-r8"
DEPEND=""
BDEPEND="
	>=net-libs/nodejs-16.13.1
	>=dev-lang/python-3.11.1
	>=virtual/rust-1.65.0-r1
	"

# Run-time dependencies. Must be defined to whatever this depends on to run.
# Example:
#    ssl? ( >=dev-libs/openssl-1.0.2q:0= )
#    >=dev-lang/perl-5.24.3-r1
# It is advisable to use the >= syntax show above, to reflect what you
# had installed on your system when you tested the package.  Then
# other users hopefully won't be caught without the right version of
# a dependency.
#RDEPEND=""

# Build-time dependencies that need to be binary compatible with the system
# being built (CHOST). These include libraries that we link against.
# The below is valid if the same run-time depends are required to compile.
#DEPEND="${RDEPEND}"

# Build-time dependencies that are executed during the emerge process, and
# only need to be present in the native build system (CBUILD). Example:
#BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/use-system-7z-and-disable-autoupdate.patch"
	"${FILESDIR}/only-build-dir.patch"
	)
	
src_prepare() {
	default
	
	sed -e '/electron-updater/d;/7zip-bin/d' -i package.json
	
	mkdir -p .git
}

src_configure() {}

src_compile() {
	npm install --legacy-peer-deps --cache="${WORKDIR}/npm-cache"

	npm run build
	npm run build-electron:setup
	npm run deploy setup
}

src_install() {
	install -dm755 "${D}/opt/gdlauncher"
	cp -r release/linux-unpacked/* "${D}/opt/gdlauncher"
	install -dm755 "${D}/usr/bin"
	ln -s "${D}/usr/bin/../../opt/gdlauncher/gdlauncher" "${D}/usr/bin/gdlauncher"
	install -dm755 "${D}/usr/share/applications"
	install -Dm644 "${FILESDIR}/GDLauncher.desktop" "${D}/usr/share/applications/GDLauncher.desktop"
	cd public/linux-icons
	for icon in *.png; do
		install -dm755 "${D}/usr/share/icons/hicolor/${icon::-4}/apps/"
		cp "$icon" "${D}/usr/share/icons/hicolor/${icon::-4}/apps/${PN}.png"
	done

	# You must *personally verify* that this trick doesn't install
	# anything outside of DESTDIR; do this by reading and
	# understanding the install part of the Makefiles.
	# This is the preferred way to install.
	#emake DESTDIR="${D}" install

	# When you hit a failure with emake, do not just use make. It is
	# better to fix the Makefiles to allow proper parallelization.
	# If you fail with that, use "emake -j1", it's still better than make.

	# For Makefiles that don't make proper use of DESTDIR, setting
	# prefix is often an alternative.  However if you do this, then
	# you also need to specify mandir and infodir, since they were
	# passed to ./configure as absolute paths (overriding the prefix
	# setting).
	#emake \
	#	prefix="${D}"/usr \
	#	mandir="${D}"/usr/share/man \
	#	infodir="${D}"/usr/share/info \
	#	libdir="${D}"/usr/$(get_libdir) \
	#	install
	# Again, verify the Makefiles!  We don't want anything falling
	# outside of ${D}.
}
