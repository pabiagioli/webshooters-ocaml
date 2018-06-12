
module Http2Frame : sig
    type t
    val length : Buffer.t (** The 24-bit length field allows a single frame to carry up to 2^24 bytes of data. *)
    val frame_type: t option (** The 8-bit type field determines the format and semantics of the frame. *)
    val flags: Buffer.t (** The 8-bit flags field communicates frame-type specific boolean flags. *)
    val reserved: char (** The 1-bit reserved field is always set to 0. *)
    val stream_id: Buffer.t (** The 31-bit stream identifier uniquely identifies the HTTP/2 stream. *)
end = struct
    type t = 
        |DATA (** Used to transport HTTP message bodies *)
        |HEADERS (** Used to communicate header fields for a stream *)
        |PRIORITY (** Used to communicate sender-advised priority of a stream *)
        |RST_STREAM (** Used to signal termination of a stream *)
        |SETTINGS (** Used to communicate configuration parameters for the connection *)
        |PUSH_PROMISE (** Used to signal a promise to serve the referenced resource *)
        |PING (** Used to measure the roundtrip time and perform "liveness" checks *)
        |GOAWAY (** Used to inform the peer to stop creating streams for current connection *)
        |WINDOW_UPDATE (** Used to implement flow stream and connection flow control *)
        |CONTINUATION (** Used to continue a sequence of header block fragments *)

    (** The 24-bit length field allows a single frame to carry up to 2^24 bytes of data. *)
    let length : Buffer.t = Buffer.create 3
    (** The 8-bit type field determines the format and semantics of the frame. *)
    let frame_type: t option = None
    (** The 8-bit flags field communicates frame-type specific boolean flags. *)
    let flags: Buffer.t = Buffer.create 1
    (** The 1-bit reserved field is always set to 0. *)
    let reserved: char = '\000'
    (** The 31-bit stream identifier uniquely identifies the HTTP/2 stream. *)
    let stream_id: Buffer.t = Buffer.create 4
end

