import hashlib
import zlib


def make_doc(dst, source):
    g = open(dst, "w", encoding="utf-8")
    buf = ""
    docbegin = ""
    docend = ""
    for src_path in source:
        if not src_path.endswith(".xml"):
            continue
        with open(src_path, "r", encoding="utf-8") as f:
            content = f.read()
        buf += content

    buf = (docbegin + buf + docend).encode("utf-8")
    decomp_size = len(buf)

    # Use maximum zlib compression level to further reduce file size
    # (at the cost of initial build times).
    buf = zlib.compress(buf, zlib.Z_BEST_COMPRESSION)

    g.write("/* THIS FILE IS GENERATED DO NOT EDIT */\n")
    g.write("\n")
    g.write("#include <godot_cpp/godot.hpp>\n")
    g.write("\n")

    g.write('static const char *_doc_data_hash = "' + hashlib.md5(buf).hexdigest() + '";\n')
    g.write("static const int _doc_data_uncompressed_size = " + str(decomp_size) + ";\n")
    g.write("static const int _doc_data_compressed_size = " + str(len(buf)) + ";\n")
    g.write("static const unsigned char _doc_data_compressed[] = {\n")
    for i in range(len(buf)):
        g.write("\t" + str(buf[i]) + ",\n")
    g.write("};\n")
    g.write("\n")

    g.write(
        "static godot::internal::DocDataRegistration _doc_data_registration(_doc_data_hash, _doc_data_uncompressed_size, _doc_data_compressed_size, _doc_data_compressed);\n"
    )
    g.write("\n")

    g.close()


# if ran as a script, use sys.argv[1] as destination and the rest as sources
if __name__ == "__main__":
    import sys

    make_doc(sys.argv[1], sys.argv[2:])
