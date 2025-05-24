const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("proj", .{});
    const sqlite = b.dependency("sqlite", .{ .target = target, .optimize = optimize });

    // We use our patched version due to issues with the original
    // ("VERSION" was used both as a macro AND as an identifier; clang doesn't like that)
    const proj_config_h = b.addConfigHeader(.{
        .style = .{ .cmake = b.path("patch/proj_config.cmake.in") },
        .include_path = "proj_config.h",
    }, .{
        .HAVE_LIBDL = null,
        .HAVE_STRERROR = 1,
        .PACKAGE = "proj",
        .PACKAGE_BUGREPORT = "https://github.com/OSGeo/PROJ/issues",
        .PACKAGE_NAME = "PROJ",
        .PACKAGE_STRING = "PROJ 9.6.0",
        .PACKAGE_TARNAME = "proj",
        .PACKAGE_URL = "https://proj.org",
        .PACKAGE_VERSION = "9.6.0",
        // .VERSION = "9.6.0",
    });

    const lib = b.addLibrary(.{
        .name = "proj",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = .static,
    });

    const common_flags: []const []const u8 = &.{
        "-Wall",
        "-Wdate-time",
        "-Werror=format-security",
        "-Werror=vla",
        "-Wextra",
        "-Wformat",
        "-Wmissing-declarations",
        "-Wshadow",
        "-Wswitch",
        "-Wunused-parameter",
        "-Wcomma",
        "-Wdeprecated",
        "-Wdocumentation",
        "-Wno-documentation-deprecated-sync",
        "-Wfloat-conversion",
        "-Wlogical-op-parentheses",
    };
    const cpp_flags: []const []const u8 = &.{
        "--std=c++17",
        "-Weffc++",
        "-Wextra-semi",
        "-Woverloaded-virtual",
        "-Wshorten-64-to-32",
        "-Wunused-private-field",
        "-Wzero-as-null-pointer-constant",
    };
    const c_flags: []const []const u8 = &.{
        "--std=c99",
        "-Wmissing-prototypes",
        "-Wc11-extensions",
    };

    const all_proj_cpp_sources = proj_core_files ++ proj_projection_files ++ proj_transform_files ++ proj_conversion_files ++ proj_iso19111_files;

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = all_proj_cpp_sources,
        .flags = common_flags ++ cpp_flags,
    });
    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = proj_core_files_c,
        .flags = common_flags ++ c_flags,
    });
    lib.addIncludePath(upstream.path("include"));
    lib.addIncludePath(upstream.path("src"));
    lib.linkLibrary(sqlite.artifact("sqlite"));
    lib.addIncludePath(sqlite.builder.dependency("sqlite", .{}).path("."));

    lib.addConfigHeader(proj_config_h);
    lib.installConfigHeader(proj_config_h);

    lib.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    for (proj_headers) |h| {
        lib.installHeader(upstream.path(b.fmt("src/{s}", .{h})), h);
    }

    b.installArtifact(lib);
}

const proj_headers: []const []const u8 = &.{
    "proj.h",
    "proj_experimental.h",
    "proj_constants.h",
    "proj_symbol_rename.h",
    "geodesic.h",
};

const proj_core_files: []const []const u8 = &.{
    "aasincos.cpp",
    "adjlon.cpp",
    "area.cpp",
    "auth.cpp",
    "coord_operation.cpp",
    "coordinates.cpp",
    "create.cpp",
    "crs_to_crs.cpp",
    "ctx.cpp",
    "datum_set.cpp",
    "datums.cpp",
    "deriv.cpp",
    "dist.cpp",
    "dmstor.cpp",
    "ell_set.cpp",
    "ellps.cpp",
    "factors.cpp",
    "filemanager.cpp",
    "fwd.cpp",
    "gauss.cpp",
    "generic_inverse.cpp",
    "grids.cpp",
    "info.cpp",
    "init.cpp",
    "initcache.cpp",
    "internal.cpp",
    "inv.cpp",
    "latitudes.cpp",
    "list.cpp",
    "log.cpp",
    "malloc.cpp",
    "mlfn.cpp",
    "msfn.cpp",
    "mutex.cpp",
    "networkfilemanager.cpp",
    "param.cpp",
    "phi2.cpp",
    "pipeline.cpp",
    "pr_list.cpp",
    "proj_json_streaming_writer.cpp",
    "proj_mdist.cpp",
    "qsfn.cpp",
    "release.cpp",
    "rtodms.cpp",
    "strerrno.cpp",
    "strtod.cpp",
    "sqlite3_utils.cpp",
    "tracing.cpp",
    "trans.cpp",
    "trans_bounds.cpp",
    "tsfn.cpp",
    "units.cpp",
    "wkt1_parser.cpp",
    "wkt2_parser.cpp",
    "wkt_parser.cpp",
    "zpoly1.cpp",
};

const proj_core_files_c: []const []const u8 = &.{
    "geodesic.c",
    "wkt1_generated_parser.c",
    "wkt2_generated_parser.c",
};

const proj_conversion_files: []const []const u8 = &.{
    "conversions/axisswap.cpp",
    "conversions/cart.cpp",
    "conversions/geoc.cpp",
    "conversions/geocent.cpp",
    "conversions/noop.cpp",
    "conversions/topocentric.cpp",
    "conversions/set.cpp",
    "conversions/unitconvert.cpp",
};

const proj_projection_files: []const []const u8 = &.{
    "projections/airocean.cpp",
    "projections/aeqd.cpp",
    "projections/adams.cpp",
    "projections/gnom.cpp",
    "projections/laea.cpp",
    "projections/mod_ster.cpp",
    "projections/nsper.cpp",
    "projections/nzmg.cpp",
    "projections/ortho.cpp",
    "projections/stere.cpp",
    "projections/sterea.cpp",
    "projections/aea.cpp",
    "projections/bipc.cpp",
    "projections/bonne.cpp",
    "projections/eqdc.cpp",
    "projections/isea.cpp",
    "projections/ccon.cpp",
    "projections/imw_p.cpp",
    "projections/krovak.cpp",
    "projections/lcc.cpp",
    "projections/poly.cpp",
    "projections/rpoly.cpp",
    "projections/sconics.cpp",
    "projections/rouss.cpp",
    "projections/cass.cpp",
    "projections/cc.cpp",
    "projections/cea.cpp",
    "projections/eqc.cpp",
    "projections/gall.cpp",
    "projections/labrd.cpp",
    "projections/som.cpp",
    "projections/merc.cpp",
    "projections/mill.cpp",
    "projections/ocea.cpp",
    "projections/omerc.cpp",
    "projections/somerc.cpp",
    "projections/tcc.cpp",
    "projections/tcea.cpp",
    "projections/times.cpp",
    "projections/tmerc.cpp",
    "projections/tobmerc.cpp",
    "projections/airy.cpp",
    "projections/aitoff.cpp",
    "projections/august.cpp",
    "projections/bacon.cpp",
    "projections/bertin1953.cpp",
    "projections/chamb.cpp",
    "projections/hammer.cpp",
    "projections/lagrng.cpp",
    "projections/larr.cpp",
    "projections/lask.cpp",
    "projections/latlong.cpp",
    "projections/nicol.cpp",
    "projections/ob_tran.cpp",
    "projections/oea.cpp",
    "projections/tpeqd.cpp",
    "projections/vandg.cpp",
    "projections/vandg2.cpp",
    "projections/vandg4.cpp",
    "projections/wag7.cpp",
    "projections/lcca.cpp",
    "projections/geos.cpp",
    "projections/boggs.cpp",
    "projections/collg.cpp",
    "projections/comill.cpp",
    "projections/crast.cpp",
    "projections/denoy.cpp",
    "projections/eck1.cpp",
    "projections/eck2.cpp",
    "projections/eck3.cpp",
    "projections/eck4.cpp",
    "projections/eck5.cpp",
    "projections/fahey.cpp",
    "projections/fouc_s.cpp",
    "projections/gins8.cpp",
    "projections/gstmerc.cpp",
    "projections/gn_sinu.cpp",
    "projections/goode.cpp",
    "projections/igh.cpp",
    "projections/igh_o.cpp",
    "projections/imoll.cpp",
    "projections/imoll_o.cpp",
    "projections/hatano.cpp",
    "projections/loxim.cpp",
    "projections/mbt_fps.cpp",
    "projections/mbtfpp.cpp",
    "projections/mbtfpq.cpp",
    "projections/moll.cpp",
    "projections/nell.cpp",
    "projections/nell_h.cpp",
    "projections/patterson.cpp",
    "projections/putp2.cpp",
    "projections/putp3.cpp",
    "projections/putp4p.cpp",
    "projections/putp5.cpp",
    "projections/putp6.cpp",
    "projections/qsc.cpp",
    "projections/robin.cpp",
    "projections/s2.cpp",
    "projections/sch.cpp",
    "projections/sts.cpp",
    "projections/urm5.cpp",
    "projections/urmfps.cpp",
    "projections/wag2.cpp",
    "projections/wag3.cpp",
    "projections/wink1.cpp",
    "projections/wink2.cpp",
    "projections/healpix.cpp",
    "projections/natearth.cpp",
    "projections/natearth2.cpp",
    "projections/calcofi.cpp",
    "projections/eqearth.cpp",
    "projections/col_urban.cpp",
    "projections/spilhaus.cpp",
};

const proj_transform_files: []const []const u8 = &.{
    "transformations/affine.cpp",
    "transformations/deformation.cpp",
    "transformations/gridshift.cpp",
    "transformations/helmert.cpp",
    "transformations/hgridshift.cpp",
    "transformations/horner.cpp",
    "transformations/molodensky.cpp",
    "transformations/vgridshift.cpp",
    "transformations/xyzgridshift.cpp",
    "transformations/defmodel.cpp",
    "transformations/tinshift.cpp",
    "transformations/vertoffset.cpp",
};

const proj_iso19111_files: []const []const u8 = &.{
    "iso19111/static.cpp",
    "iso19111/util.cpp",
    "iso19111/metadata.cpp",
    "iso19111/common.cpp",
    "iso19111/coordinates.cpp",
    "iso19111/crs.cpp",
    "iso19111/datum.cpp",
    "iso19111/coordinatesystem.cpp",
    "iso19111/io.cpp",
    "iso19111/internal.cpp",
    "iso19111/factory.cpp",
    "iso19111/c_api.cpp",
    "iso19111/operation/concatenatedoperation.cpp",
    "iso19111/operation/coordinateoperationfactory.cpp",
    "iso19111/operation/conversion.cpp",
    "iso19111/operation/esriparammappings.cpp",
    "iso19111/operation/oputils.cpp",
    "iso19111/operation/parametervalue.cpp",
    "iso19111/operation/parammappings.cpp",
    "iso19111/operation/projbasedoperation.cpp",
    "iso19111/operation/singleoperation.cpp",
    "iso19111/operation/transformation.cpp",
    "iso19111/operation/vectorofvaluesparams.cpp",
};

// TODO
const embedded_resource_files: []const []const u8 = &.{
    "embedded_resources.c",
};
