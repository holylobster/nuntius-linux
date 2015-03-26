
/*
 * Minimal VAPI file for LIBQRENCODE Barcode library.
 */
namespace Qrencode {

    [CCode (cheader_filename = "qrencode.h", cname = "QRcode", unref_function = "QRcode_free")]
    public class QRcode {
        [CCode (cname = "QRcode_encodeString")]
        public QRcode.encodeString(string digits, int version, EcLevel level, Mode hint, int casesensitive);

        public int version;
        public int width;
        [CCode (array_length = false)]
        public uint8[] data;
    }

    [CCode (cheader_filename = "qrencode.h", cname="QRencLevel")]
    public enum EcLevel {
        [CCode (cname="QR_ECLEVEL_L")]
        L,
        [CCode (cname="QR_ECLEVEL_M")]
        M,
        [CCode (cname="QR_ECLEVEL_Q")]
        Q,
        [CCode (cname="QR_ECLEVEL_H")]
        H
    }

    [CCode (cheader_filename = "qrencode.h", cname="QRencodeMode")]
    public enum Mode {
        [CCode (cname="QR_MODE_NUL")]
        NUL,
        [CCode (cname="QR_MODE_NUM")]
        NUM,
        [CCode (cname="QR_MODE_AN")]
        AN,
        [CCode (cname="QR_MODE_8")]
        B8,
        [CCode (cname="QR_MODE_KANJI")]
        KANJI,
        [CCode (cname="QR_MODE_STRUCTURE")]
        STRUCTURE
    }
}
