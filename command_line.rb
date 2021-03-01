# frozen_string_literal: false

# Functions related to the command line

def err(message)
  warn " > #{message}"
end

def exit_fail!(code = false)
  yield if block_given?
  exit code || false # Looks a little strange, but I don't want to do `exit nil`
end
