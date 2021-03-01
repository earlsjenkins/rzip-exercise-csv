# frozen_string_literal: false

# Encapsulate the actual "matching" logic for values, based on the type.
# Technically, it doesn't do any actual matching. Instead, it take in a set of values,
# and produces a normalized "matcher" value based on rules for the specific type, which
# is then used in the Engine for actual lookups against other rows that have the same
# normalized matcher value. Thus, the "matcher" value will always be the same for any
# given set of fields that are supposed to match per the specific matching type.

class Matcher
  MATCHER_TYPE_EMAIL = "email".freeze
  MATCHER_TYPE_PHONE = "phone".freeze
  MATCHER_TYPE_EMAIL_OR_PHONE = "email_or_phone".freeze
  VALID_MATCHER_TYPES = [
    MATCHER_TYPE_EMAIL,
    MATCHER_TYPE_PHONE,
    MATCHER_TYPE_EMAIL_OR_PHONE
  ].freeze

  def self.valid_matcher_type?(matcher_type)
    VALID_MATCHER_TYPES.include? matcher_type
  end

  def self.normalize_matcher_type(matcher_type)
    matcher_type.to_s.strip.downcase
  end

  def initialize(match_as, field_matcher_hash)
    @match_as = self.class.normalize_matcher_type match_as
    raise "Unknown matcher type!" unless self.class.valid_matcher_type? @match_as

    @field_matcher_hash = field_matcher_hash
    @field_matcher_hash.transform_keys! &:downcase
    @field_matcher_hash.transform_values! do |raw_matcher_type|
      matcher_type = self.class.normalize_matcher_type raw_matcher_type
      raise "Unknown matcher type!" unless self.class.valid_matcher_type? matcher_type

      matcher_type
    end
  end

  def field_names
    @field_names ||= @field_matcher_hash.keys
  end

  def normalize(values_hash)
    values_hash.collect do |k, v|
      if MATCHER_TYPE_EMAIL_OR_PHONE == @match_as
        # Since this is a composite type, we need to find out
        # how any given field is supposed to be matched
        field_match_type = matcher_type_for_field k
        normalize_for_type field_match_type, v
      else
        normalize_for_type @match_as, v
      end
    end
  end

  private

  def normalize_for_type(matcher_type, value)
    case matcher_type
    when MATCHER_TYPE_EMAIL
      normalize_email value
    when MATCHER_TYPE_PHONE
      normalize_phone value
    else
      # This should never happen, but I prefer to wear suspenders with my belt.
      raise "Unknown matcher type!"
    end
  end

  def matcher_type_for_field(field_name)
    @field_matcher_hash[field_name]
  end

  def normalize_email(email)
    email.to_s.strip.downcase
  end

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, "")
  end
end

