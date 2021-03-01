# frozen_string_literal: false

# The thing that runs the processing of the CSV and writing the output.
# Actual field matching is performed using the given Matcher

require "csv"

class Engine
  OUTFILE_SUFFIX = "grouped".freeze
  ID_HEADER = "UUID".freeze

  def initialize(file_name, matcher, outfile_suffix: nil)
    @file_name = file_name
    @matcher = matcher
    @outfile_suffix = outfile_suffix
  end

  def run!
    CSV.open outfile_name, "w" do |new_csv|
      CSV.foreach(@file_name,
                  headers: true,
                  header_converters: [:downcase],
                  return_headers: true) do |row|
        if row.header_row?
          new_csv << [ID_HEADER, row.fields].flatten
        else
          count_row!
          # 1. Get fields to be matched
          values = row.to_h.slice *@matcher.field_names
          # 2. Track the values
          id = track_values values
          # 3. Write the row to the new CSV
          new_csv << [id, row.fields].flatten
        end
      end
    end
  end

  def outfile_name
    "#{@file_name}.#{outfile_suffix}"
  end

  def rows_processed
    @rows_processed ||= 0
  end

  private

  def count_row!
    @rows_processed = rows_processed + 1
  end

  def outfile_suffix
    @outfile_suffix || OUTFILE_SUFFIX
  end

  def new_id
    # Arbitrarily long UUID
    SecureRandom.hex 10
  end

  def value_store
    @value_store ||= {}
  end

  def store_value(value, id)
    value_store[value] = id
  end

  def value_in_store?(value)
    value_store.has_key? value
  end

  def track_values(values_hash)
    normalized = @matcher.normalize values_hash
    # If we already have a match, use it
    matched = normalized.find {|norm| value_in_store?(norm)}
    active_id = matched ? value_id(matched) : new_id
    normalized.each do |norm|
      store_value(norm, active_id) unless norm.blank? || value_in_store?(norm)
    end
    active_id
  end

  def value_id(value)
    value_store[value]
  end
end

