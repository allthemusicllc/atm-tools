// gen.rs
//
// Copyright (c) 2022 All The Music LLC
//
// This work is licensed under the Creative Commons Attribution 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/ or send
// a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

use flate2::Compression;

use crate::{
    cli::CliDirective,
    directives::{GenBatchDirective, GenSingleDirective, GenTarDirective, GenTarGzDirective},
    storage::StorageBackend,
};

/*************************
***** Utility Errors *****
*************************/

/// Error type for converting `&str` to
/// [flate2::Compression](../../../flate2/struct.Compression.html)
#[derive(Debug, thiserror::Error)]
pub enum CompressionArgError {
    #[error(transparent)]
    NotInteger(#[from] std::num::ParseIntError),
    #[error("Compression level must be between 0 and 9 (found {input})")]
    ValueOutOfRange { input: u32 },
}

/**************************
***** Utility Methods *****
**************************/

/// Parse [flate2::Compression](../../../flate2/struct.Compression.html) from `&str`
pub(crate) fn try_compression_from_str(arg: &str) -> Result<Compression, CompressionArgError> {
    let compression_level = arg.parse::<u32>()?;
    if compression_level > 9 {
        return Err(CompressionArgError::ValueOutOfRange { input: compression_level });
    }
    Ok(Compression::new(compression_level))
}

/// Generate melodies and write them to provided backend
pub(crate) fn write_melodies_to_backend<B: StorageBackend>(
    note_set: libatm::MIDINoteSet,
    melody_length: u32,
    mut backend: B,
) {
    // Convert set of notes to vec
    let notes = libatm::MIDINoteVec::from(note_set);
    // Generate total number of melodies
    let num_melodies = crate::utils::gen_num_melodies(notes.len() as u32, melody_length);
    // Initialize progress bar
    let mut pb = pbr::ProgressBar::new(num_melodies);
    pb.set_max_refresh_rate(Some(std::time::Duration::from_millis(500)));

    // For each melody
    for melody_ref in crate::utils::gen_sequences(&notes, melody_length) {
        // Copy notes into owned melody
        let melody = melody_ref.iter().map(|n| *n.clone()).collect::<libatm::MIDINoteVec>();
        // Show error if adding melody to backend failed
        if let Err(err) = backend.append_melody(melody, None) {
            println!("::: WARNING: Failed to add melody to storage backend ({:?})", err);
        }
        // Increment progress bar even if write failed
        pb.inc();
    }

    // Stop progress bar
    pb.finish_println("");
    // Finish writing to backend
    if let Err(err) = backend.finish() {
        println!("::: ERROR: Failed to finish writing to storage backend ({:?})", err);
        std::process::exit(1);
    }
}

/***********************
***** GenDirective *****
***********************/

/// Generate melodies (MIDI files) and store them in a file/files.
#[derive(structopt::StructOpt)]
pub enum GenDirective {
    /// Generate melodies and store them in Tar file, where each entry
    /// is Gzip-compressed Tar file containing a batch of melodies.
    /// Can be useful for situations where disk space is very limited,
    /// though in general using the `tar-gz` backend will provide better compression.
    #[structopt(name = "batch")]
    GenBatch(GenBatchDirective),
    /// Generate single melody (MIDI file).
    #[structopt(name = "single")]
    GenSingle(GenSingleDirective),
    /// Generate melodies and store them in Tar file.
    /// Use for datasets where output file size is less of a concern.
    #[structopt(name = "tar")]
    GenTar(GenTarDirective),
    /// Generate melodies and store them in Gzip-compressed Tar file.
    /// Generally provides the best compression, and should be used for larger datasets.
    /// See `estimate` directives to simulate output file sizes.
    #[structopt(name = "tar-gz")]
    GenTarGz(GenTarGzDirective),
}

impl CliDirective for GenDirective {
    fn run(self) {
        match self {
            Self::GenBatch(d) => d.run(),
            Self::GenSingle(d) => d.run(),
            Self::GenTar(d) => d.run(),
            Self::GenTarGz(d) => d.run(),
        }
    }
}
