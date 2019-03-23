class Mapserver < Formula
  desc "Publish spatial data and interactive mapping apps to the web"
  homepage "https://mapserver.org/"
  url "https://download.osgeo.org/mapserver/mapserver-7.2.2.tar.gz"
  sha256 "287f8dfe10961bc685bb87e118b7aa81382df907b2b3961d6559169b527ba95c"

  bottle do
    cellar :any
    sha256 "3dfb756ff659789cf4253595aa22d2ab0b2b4b6b7bf6cbf4cba6853237b626dc" => :mojave
    sha256 "ce339daff8744842eb6c82bcb034fce73ec2f53dfa4c522a02ac01382766affb" => :high_sierra
    sha256 "792a125e13694bdcba3023bf0a068d345050cbf479cb445dd01b96a9772caaf8" => :sierra
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "cairo"
  depends_on "fcgi"
  depends_on "freetype"
  depends_on "gd"
  depends_on "gdal"
  depends_on "geos"
  depends_on "giflib"
  depends_on "libpng"
  depends_on "postgresql"
  depends_on "proj"
  depends_on "protobuf-c"

  def install
    # Harfbuzz support requires fribidi and fribidi support requires
    # harfbuzz but fribidi currently fails to build with:
    # fribidi-common.h:61:12: fatal error: 'glib.h' file not found
    args = std_cmake_args + %w[
      -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python
      -DWITH_CLIENT_WFS=ON
      -DWITH_CLIENT_WMS=ON
      -DWITH_CURL=ON
      -DWITH_FCGI=ON
      -DWITH_FRIBIDI=OFF
      -DWITH_GDAL=ON
      -DWITH_GEOS=ON
      -DWITH_HARFBUZZ=OFF
      -DWITH_KML=ON
      -DWITH_OGR=ON
      -DWITH_POSTGIS=ON
      -DWITH_PROJ=ON
      -DWITH_PYTHON=ON
      -DWITH_SOS=ON
      -DWITH_WFS=ON
      -WITH_CAIRO=ON
    ]

    # Install within our sandbox
    inreplace "mapscript/python/CMakeLists.txt" do |s|
      s.gsub! "${PYTHON_SITE_PACKAGES}", lib/"python2.7/site-packages"
      s.gsub! "${PYTHON_LIBRARIES}", "-Wl,-undefined,dynamic_lookup"
    end
    inreplace "mapscript/php/CMakeLists.txt", "${PHP5_EXTENSION_DIR}", lib/"php/extensions"

    # Using rpath on python module seems to cause problems if you attempt to
    # import it with an interpreter it wasn't built against.
    # 2): Library not loaded: @rpath/libmapserver.1.dylib
    args << "-DCMAKE_SKIP_RPATH=ON"

    # Use Proj 6.0.0 compatibility headers
    # https://github.com/mapserver/mapserver/issues/5766
    ENV.append_to_cflags "-DACCEPT_USE_OF_DEPRECATED_PROJ_API_H"

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mapserv -v")
    system "python2.7", "-c", "import mapscript"
  end
end
