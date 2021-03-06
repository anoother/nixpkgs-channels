{ stdenv, fetchurl, python2Packages, intltool, file
, wrapGAppsHook, virtinst, gtkvnc, vte, avahi, dconf
, gobjectIntrospection, libvirt-glib, system-libvirt
, gsettings_desktop_schemas, glib, libosinfo, gnome3
, spiceSupport ? true, spice_gtk ? null
}:

with stdenv.lib;

python2Packages.buildPythonApplication rec {
  name = "virt-manager-${version}";
  version = "1.4.3";
  namePrefix = "";

  src = fetchurl {
    url = "http://virt-manager.org/download/sources/virt-manager/${name}.tar.gz";
    sha256 = "093azs8p4p7y4nf5j25xpsvdxww7gky1g0hs8mkcvmpxl2wjd0jj";
  };

  nativeBuildInputs = [
    wrapGAppsHook intltool file
    gobjectIntrospection # for setup hook populating GI_TYPELIB_PATH
  ];

  buildInputs =
    [ libvirt-glib vte virtinst dconf gtkvnc gnome3.defaultIconTheme avahi
      gsettings_desktop_schemas libosinfo
    ] ++ optional spiceSupport spice_gtk;

  propagatedBuildInputs = with python2Packages;
    [ eventlet greenlet gflags netaddr carrot routes PasteDeploy
      m2crypto ipy twisted distutils_extra simplejson
      cheetah lockfile httplib2 urlgrabber pyGtkGlade dbus-python
      pygobject3 ipaddr mox libvirt libxml2 requests
    ];

  patchPhase = ''
    sed -i 's|/usr/share/libvirt/cpu_map.xml|${system-libvirt}/share/libvirt/cpu_map.xml|g' virtinst/capabilities.py
    sed -i "/'install_egg_info'/d" setup.py
  '';

  postConfigure = ''
    ${python2Packages.python.interpreter} setup.py configure --prefix=$out
  '';

  postInstall = ''
    ${glib.dev}/bin/glib-compile-schemas "$out"/share/glib-2.0/schemas
  '';

  preFixup = ''
    gappsWrapperArgs+=(--set PYTHONPATH "$PYTHONPATH")
  '';

  # Failed tests
  doCheck = false;

  meta = with stdenv.lib; {
    homepage = http://virt-manager.org;
    description = "Desktop user interface for managing virtual machines";
    longDescription = ''
      The virt-manager application is a desktop user interface for managing
      virtual machines through libvirt. It primarily targets KVM VMs, but also
      manages Xen and LXC (linux containers).
    '';
    license = licenses.gpl2;
    maintainers = with maintainers; [ qknight offline fpletz ];
  };
}
