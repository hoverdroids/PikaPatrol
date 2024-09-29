class MediaUtils {
  // https://en.wikipedia.org/wiki/Video_file_format
  static const FILE_FORMATS_VIDEO = {
    "webm", "mkv", "flv", "f4v", "vob", "ogv", "ogg", "drc", "gif", "gifv", "mng", "avi", "mts", "m2ts", "mov", "qt", "wmv",
    "yuv", "rm", "rmvb", "viv", "asf", "amv", "mp4", "m4p", "m4v", "mpg", "mpg2", "mpeg", "mpe", "mpv", "m2v", "svi", "3gp",
    "3g2", "mxf", "roq", "nsv", "f4p", "f4a", "f4b"
  };

  //https://en.wikipedia.org/wiki/Audio_file_format
  static const FILE_FORMATS_AUDIO = {
    "3gp","aa", "aac", "aax", "act", "aiff", "alac", "amr", "ape", "au", "awb", "dss", "dvf", "flac", "gsm", "iklax",
    "ivs", "m4a", "m4b", "m4p", "mmf", "movpkg", "mp3", "mpc", "msv", "nmf", "ogg", "oga", "mogg", "opus", "ra", "rm",
    "raw", "rf64", "sln", "tta", "voc", "vox", "wav", "wma", "wv", "webm", "8svx", "cda"
  };

  //https://en.wikipedia.org/wiki/Image_file_format
  // https://fileinfo.com/filetypes/raster_image
  static const FILE_FORMATS_IMAGE_RASTER = {
    "bif", "jxl", "pxd", "sprite2", "xpm", "icon", "afphoto", "ase", "psdc", "lrpreview", "8ci", "sumo", "qoi", "gif", "mnr",
    "sprite3", "psd", "tbn", "ptex", "plp", "snagx", "avatar", "bpg", "png", "ysp", "sprite", "tga", "flif", "tpf", "dds", "piskel",
    "dib", "sai", "spr", "pdn", "jpeg", "hdr", "pzp", "vicar", "six", "ppp", "psp", "nwm", "ct", "sld", "ipv", "linea", "jls",
    "pam", "sktz", "wic", "skitch", "oc4", "ipick", "aps", "oplc", "pcx", "clip", "kra", "pm", "jpg", "heif", "webp", "jps", "ota",
    "lip", "tfc", "pwp", "pov", "mng", "exr", "itc2", "xcf", "fits", "wbz", "lzp", "psdx", "73i", "wbc", "djvu", "lsa", "usertile-ms",
    "ppf", "cdc", "cpc", "tiff", "bmp", "pmg", "ozj", "accountpicture-ms", "can", "rgf", "pbm", "2bp", "jpc", "snag", "ecw", "tm2",
    "cdg", "mdp", "stex", "mpf", "pi2", "px", "vna", "pdd", "awd", "pfi", "pspimage", "nol", "pni", "xbm", "msp", "nlm", "drz", "pnc",
    "kfx", "cmr", "ff", "pixela", "urt", "icn", "heic", "rpf", "vrimg", "tn", "dgt", "tg4", "apng", "jng", "fbm", "fil", "vpe", "fpx",
    "jpf", "spp", "fac", "rsr", "aseprite", "dtw", "pat", "pgm", "jpe", "ppm", "iwi", "bmq", "ktx", "i3d", "gim", "ptg",
    "tif", "thm", "psb", "otb", "art", "ozt", "ctex", "jbig2", "sph", "wbm", "wb2", "bmz", "ljp", "spa", "cals", "gmbck", "pp5",
    "j2k", "lb", "hif", "1sc", "g3n", "cpd", "vrphoto", "ktx2", "mpo", "viff", "pxo", "wb0", "pns", "jxr", "gih", "avifs", "wbmp",
    "zif", "pic", "lmnr", "sig", "arr", "info", "pgf", "abm", "hdp", "pjpg", "lbm", "cimg", "bti", "pictclipping", "ce",
    "face", "sai2", "jp2", "rtl", "tex", "jpx", "pxm", "djv", "jpg2", "qtif", "cpt", "vda", "riff", "pe4", "pnt", "pvr", "agp", "ilbm",
    "oti", "oci", "rcl", "pzs", "lif", "oc3", "kdi", "gbr", "ufo", "1", "vss", "sid", "gro", "sup", "int", "rli", "apd", "s2mv",
    "ggr", "cit", "prw", "ais", "wb1", "sfc", "jia", "dm4", "gp4", "insp", "jpg_large", "dcm", "avif", "thumb", "mcs",
    "v", "pcd", "wi", "wdp", "mbm", "procreate", "neo", "hpi", "jif", "ras", "ncd", "wmp", "bmc", "snagproj", "bmx", "rif", "qmg", "ica",
    "pse", "jfi", "kodak", "spe", "ithmb", "ora", "cin", "sun", "msk", "pxz", "rgb", "sdr", "targa", "max", "gmspr", "pop", "ivue",
    "wpb", "gpd", "pc2", "pc1", "srf", "pp4", "t2b", "pjp", "skm", "sky", "pyxel", "wbp", "avb", "ozb", "pza", "hdrp", "oc5", "pixadex",
    "myl", "fpos", "spj", "gcdp", "36", "kra~", "bm2", "jbig", "monopic", "svslide", "psxprj", "afx", "ipx", "fsthumb", "monosnippet",
    "j2c", "cd5", "picnc", "mix", "ab3", "qti", "tjp", "cid", "dmi", "pbs", "xwd", "dpx", "jbf", "agif", "pxr", "dcx",
    "bss", "pano", "psf", "zvi", "8ca", "texture", "9png", "rgba", "dt2", "bw", "cut", "pspbrush", "dicom", "apx", "sgd", "sva", "mac",
    "jiff", "drp", "ncr", "ddt", "cpg", "fppx", "sep", "rle", "pac", "u", "kic", "dic", "8xi", "gfie", "shg", "ndpi", "pap", "odi", "rcu",
    "scn", "jtf", "jb2", "cal", "skypeemoticonset", "qif", "cam", "jfif", "ink", "sfw", "mxi", "svs", "jbr", "oe6", "miff", "pnm",
    "yuv", "aic", "jpd", "tps", "epp", "sob", "tub", "sbp", "acorn", "uga", "jwl", "rvg", "ivr", "ugoira", "mrb", "sct", "mat", "mic",
    "mipmaps", "wvl", "ptk", "ptx", "pjpeg", "rsb", "pi1", "ddb", "smp", "hr", "omf", "bs", "rri", "sgi", "jbg", "adc", "c4", "y", "csf",
    "mrxs", "psptube", "dc2", "brn", "icpr", "trif", "vdoc", "cpx", "mip", "fsymbols-art", "psdb", "dino", "pal", "jas", "pxicon",
    "acr", "pc3", "ric", "aai", "pfr", "dm3", "colz", "fax", "wbd", "bmf", "ldoc", "oir", "palm", "g3f", "nct", "inv", "upf", "pspframe",
    "vmu", "npsd", "gvrs", "t2k", "xface", "dc6", "qptiff", "gfb", "vic", "frm", "dvl", "cpbitmap", "tsr", "kpg",
    "cps", "pts", "brt", "wpe", "tla", "pix", "vst", "blkrt", "ic3", "ic2", "ic1", "iphotoproject"
  };

  //https://en.wikipedia.org/wiki/Image_file_format
  //https://fileinfo.com/filetypes/vector_image
  static const FILE_FORMATS_IMAGE_VECTOR = {
    "svg", "svgz", "vstm", "shapes", "ai", "vsdx", "gvdesign", "cdr", "ep", "cmx", "apm", "fh8", "fcm", "slddrt", "afdesign",
    "vstx", "std", "dpr", "eps", "drw", "fh10", "csy", "epsf", "wmf", "odg", "pfd", "fh9", "cdmz", "cdd", "ps", "lmk", "cdrapp",
    "psid", "glox", "fh4", "pobj", "ft9", "fxg", "fh7", "igx", "dpp", "ink", "emz", "xar", "vsd", "drawio", "nodes",
    "texemz", "cvd", "fhd", "ssk", "aic", "plt", "sk", "ecs5", "xmmat", "drawit", "mvg", "vsdm", "cvx", "otg", "ac6", "pmg",
    "svm", "pen", "ait", "pixil", "wpg", "puppet", "sxd", "ft8", "pd", "hpgl", "scv", "rdl", "cdx", "esc", "hpg", "pict",
    "vectornator", "hvif", "cdtx", "fig", "dia", "gsd", "mp", "clarify", "mgc", "fh11", "sketch", "asy", "vml", "imd", "ydr",
    "tpl", "jsl", "idea", "cvs", "cddz", "graffle", "pat", "emf", "wmz", "sk1", "maker", "epgz", "mgtx", "fh3", "fh5", "mmat",
    "isf", "dhs", "wpi", "ezdraw", "drawing", "tne", "ylc", "cvxcad", "scut5", "cdtz", "gstencil", "mgcb", "sk2", "cvg",
    "tlc", "vst", "cvi", "snagstyles", "ovr", "mgmx", "smf", "dxb", "ded", "sda", "cdsx", "stn", "ovp", "dpx", "vec", "cv5",
    "egc", "svf", "pfv", "cgm", "ftn", "fh6", "ac5", "cil", "af3", "fmv", "fif", "abc", "cnv", "sketchpad", "pl", "af2",
    "hpl", "design", "pic", "zgm", "dcs", "ddrw", "ufr", "awg", "ft10", "fs", "xmmap", "hgl", "cdmm", "artb", "gks", "ft7", "art",
    "pct", "dsf", "cor", "vbr", "curve", "cdmt", "qcc", "cvdtpl", "mgmf", "cdt", "ccx", "gtemplate", "mgmt", "xpr", "ft11", "cdmtz",
    "ds4", "dsg", "amdn", "gem", "ndb", "ndx", "ndtx", "yal", "cag", "p", "pws", "pcs", "gls", "mgs", "cwt", "igt", "nap"
  };

  //https://fileinfo.com/filetypes/3d_image
  static const FILE_FORMATS_3D = {
    "bbmodel", "hipnc", "gh", "crz", "mesh", "iavatar", "ddp", "md5anim", "part", "irr", "vrm", "c4d", "duf", "fsh", "mcsg", "dff",
    "blend", "makerbot", "m3d", "iv", "dsv", "thing", "atm", "phy", "zt", "mc5", "cmdb", "pmx", "cfg", "smd", "mdl", "fx", "mix",
    "xaf", "lxf", "x", "nm", "mu", "p3d", "an8", "mtz", "mdx", "usd", "3ds", "psa", "amf", "vox", "flt", "cso", "x3d", "3d2", "gltf",
    "3mf", "obp", "wft", "md5mesh", "n3d", "p3l", "prm", "p4d", "trace", "br7", "md5camera", "ive", "3dxml", "hdz", "kfm", "reality",
    "atl", "ppz", "ccp", "gmf", "dae", "ma", "irrmesh", "vpd", "tme", "animset", "facefx", "e57", "3d4", "t3d", "ply", "mhm", "bip",
    "v3d", "shapr", "stel", "llm", "pp2", "ghx", "grs", "tilt", "sh3d", "xmf", "z3d", "anim", "ds", "ifc", "psk", "skp", "obj", "pz2",
    "pkg", "3da", "rcs", "lnd", "sdb", "igi", "glsl", "pl0", "x3g", "lxo", "dwf", "usdz", "anm", "p5d", "fcp", "cg", "mnm", "blk",
    "prc", "mgf", "mxm", "meb", "dn", "des", "tri", "mb", "off", "a8s", "sh3f", "chr", "spv", "cg3", "mrml", "mqo", "mxs", "xsi", "sis",
    "p3m", "3dm", "hip", "sc4model", "m3g", "a2c", "pmd", "nif", "mdd", "vsh", "b3d", "a3d", "album", "3dp", "ms3d", "bif", "hrz", "v3v",
    "fcz", "obz", "fpf", "tcn", "dsa", "glb", "msh", "arfx", "mcz", "fbx", "wrp", "bld", "shp", "ol", "3dl", "fxt", "bro", "3dmf", "cgfx",
    "arexport", "fg", "w3d", "u3d", "geo", "cmod", "gmt", "ums", "visual_processed", "ktz", "vs", "nxs", "xr", "arm", "par", "vroid",
    "grn", "mc", "mcx-8", "fxl", "hlsl", "fxs", "mud", "crf", "bvh", "mtl", "cmf", "cm2", "lws", "br4", "fnc", "c3d", "vvd", "mtx", "s",
    "act", "d3d", "lwo", "srf", "max", "fp", "iges", "glf", "ydl", "cpy", "vmd", "sbsar", "vp", "sgn", "br6", "qc", "vrl", "dsb", "csd",
    "ccb", "aof", "veg", "session", "vue", "bio", "f3d", "csm", "cal", "egg", "igs", "wrl", "3df", "maxc", "brg", "pgal", "pl2", "cr2",
    "vob", "gmmod", "c3z", "p3r", "3dc", "fxm", "pzz", "tvm", "dsf", "prv", "nff", "ogf", "pz3", "ik", "daz", "tmd", "visual", "fun",
    "jcd", "xof", "clara", "fxa", "skl", "previz", "sm", "dse", "p2z", "dbm", "mc6", "hr2", "mdg", "cmz", "kmcobj", "smc", "dfs", "s3g",
    "kmc", "fpj", "pskx", "spline", "zmbx", "fry", "arpatch", "drf", "arprojpkg", "v3o", "real", "hxn", "primitives_processed", "pro",
    "3dmk", "j3o", "xmm", "atf", "thl", "dmc", "3dw", "prefab", "vtx", "xpr", "cas", "aoi", "m3", "br5", "pl1", "ddd", "fig", "sbfres",
    "br3", "dbs", "xrf", "fp3", "mat", "cms", "dbc", "n2", "lp", "jas", "wow", "ts1", "rft", "fc2", "oct", "bsk", "tps", "pigs", "glm",
    "3dx", "mp", "dsi", "ldm", "rad", "si", "mpj", "exp", "3d", "glslesf", "lps", "egm", "fsq", "r3d", "sto", "yaodl", "vso", "asat", "xv0",
    "dso", "dbl", "ltz", "pat", "primitives", "mmpp", "dif", "nsbta", "chrparams", "igm", "mbx", "cga", "vac", "scw", "xsf", "csf",
    "bbscene", "s3o", "pigm", "zvf", "svf", "3dv", "tmo", "tgo", "p21", "fpe", "hd2", "igmesh", "emcam", "3don", "caf", "mot", "lt2",
    "animset_ingame", "brk", "dsd", "tddd", "fbm", "vmo", "bto", "facefx_ingame", "arproj", "fuse", "rds", "stc", "wrz", "rig", "ray"
  };
}