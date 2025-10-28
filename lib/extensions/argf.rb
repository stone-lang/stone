# Iterate through ARGF input files. Can still use ARGF.filename and ARGF.lineno.
def ARGF.each_file
  until ARGF.closed?
    yield ARGF.file
    ARGF.skip
    return if ARGV.empty? # Ensure we stop if we were reading from STDIN.
  end
end
