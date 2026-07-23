///|
fn main {
  let exit_code = @cli_core.run_cli_from_files(
    @cli_core.command_args(@sys.get_cli_args()),
  )
  if exit_code != 0 {
    @sys.exit(exit_code)
  }
}
