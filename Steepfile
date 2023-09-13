D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"

  configure_code_diagnostics(D::Ruby.strict)
  configure_code_diagnostics do |config|
    config[D::Ruby::MethodDefinitionMissing] = :hint
    config[D::Ruby::UnreachableBranch] = :hint
    config[D::Ruby::FallbackAny] = :hint
    config[D::Ruby::UnexpectedBlockGiven] = :hint
  end
end

# target :test do
#   signature "sig", "sig-private"

#   check "spec"

#   library "rspec"
# end
