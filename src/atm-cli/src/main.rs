// main.rs
//
// Copyright (c) 2022 All The Music LLC
//
// This work is licensed under the Creative Commons Attribution 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/ or send
// a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

use atm::cli::CliDirective;

use structopt::StructOpt;

fn main() {
    // Parse command line arguments and run program
    atm::cli::Cli::from_args().run();
}
