# Copyright 2015 Fin Christensen
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI="https://github.com/holylobster/nuntius-linux.git"
VALA_MIN_API_VERSION="0.18"

inherit eutils git-r3 vala

DESCRIPTION="Nuntius delivers notifications from your phone or tablet to your computer"
HOMEPAGE="https://github.com/holylobster/nuntius-linux"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RDEPEND="
	>=x11-libs/gtk+-3.14
	>=dev-libs/glib-2.38
	>=dev-libs/json-glib-0.16.2
	>=media-gfx/qrencode-3.1.0"
DEPEND="${RDEPEND}
	>=dev-vcs/git-2.4.6
	>=dev-util/intltool-0.50
	$(vala_depend)"

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	./autogen.sh || die "Autogen failed!"
	vala_src_prepare
}
